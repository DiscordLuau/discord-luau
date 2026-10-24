use std::any::Any;
use std::io::Read;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc::{Receiver, TryRecvError};
use std::sync::{Arc, Mutex};

use symphonia::core::codecs::audio::AudioDecoder;
use symphonia::core::formats::FormatReader;

use crate::chunk_reader::ChunkReader;
use crate::decoder::Decoder;
use crate::demuxer::Demuxer;
use crate::error::Error;
use crate::ffi::{self, TextBuffer};
use crate::guard::lock;
use crate::handle::Handle;
use crate::opus::OpusHead;
use crate::resample::StereoResampler;
use crate::session::Session;
use crate::status::Status;
use crate::stream::StreamSession;
use crate::{FAILED, guard, resample, stream};

pub const PANIC: &[u8] = b"\0a test panic: ";
pub const INPUT_CHUNKS: usize = stream::INPUT_CHUNKS;
pub const OUTPUT_BLOCKS: usize = stream::OUTPUT_BLOCKS;
pub const BLOCK_FRAMES: usize = stream::BLOCK_FRAMES;
pub const RESAMPLER_CHUNK_FRAMES: usize = resample::CHUNK_FRAMES;

static BLOCKS_SENT: AtomicUsize = AtomicUsize::new(0);

#[expect(clippy::panic, reason = "the hook fails a stream's worker on request")]
pub(crate) fn panic_on_request(chunk: &[u8]) {
    if let Some(message) = chunk.strip_prefix(PANIC) {
        panic!("{}", String::from_utf8_lossy(message));
    }
}

pub(crate) fn count_block() {
    BLOCKS_SENT.fetch_add(1, Ordering::SeqCst);
}

pub fn blocks_sent() -> usize {
    BLOCKS_SENT.load(Ordering::SeqCst)
}

pub fn panic_error(payload: &(dyn Any + Send)) -> Error {
    guard::panic_error(payload)
}

/// # Safety
///
/// `error_out` must be null or valid for writes of `error_capacity` bytes.
pub unsafe fn guarded(error_out: *mut u8, error_capacity: u32, body: impl FnOnce() -> Result<i32, Error>) -> i32 {
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guard::guarded(error_out, FAILED, body)
}

/// # Safety
///
/// `handle` must be null or an open session, and `error_out` null or valid for writes of `error_capacity` bytes.
pub unsafe fn guarded_session(
    handle: *mut Handle,
    error_out: *mut u8,
    error_capacity: u32,
    body: impl FnOnce(&mut Handle) -> Result<i32, Error>,
) -> i32 {
    // SAFETY: the caller guarantees that `handle` is null or an open session.
    let handle = unsafe { handle.as_mut() };
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guard::guarded_session(handle, error_out, FAILED, body)
}

/// # Safety
///
/// `pointer` must be null or valid for writes of `capacity` bytes.
pub unsafe fn write_text(pointer: *mut u8, capacity: u32, text: &str) -> usize {
    // SAFETY: the caller guarantees that `pointer` is null or has `capacity` writable bytes.
    unsafe { TextBuffer::new(pointer, capacity) }.write(text)
}

/// # Safety
///
/// `data` must be null or hold `length` bytes, unless 0, that nothing writes during `'data`.
pub unsafe fn input<'data>(data: *const u8, length: u32) -> Option<&'data [u8]> {
    // SAFETY: the caller upholds `input_slice`'s contract.
    unsafe { ffi::input_slice(data, length) }
}

/// # Safety
///
/// `pointer` must be null or hold `length` initialized bytes, unless 0, that nothing else uses during `'output`.
pub unsafe fn output<'output>(pointer: *mut u8, length: usize) -> Option<&'output mut [u8]> {
    // SAFETY: the caller upholds `output_slice`'s contract.
    unsafe { ffi::output_slice(pointer, length) }
}

pub fn capped_capacity(capacity: u32) -> usize {
    ffi::capped_capacity(capacity)
}

pub fn saturate_to_i32(value: u64) -> i32 {
    ffi::saturate_to_i32(value)
}

pub fn parse_opus_head(bytes: &[u8]) -> Result<Option<(u8, u8)>, Error> {
    Ok(OpusHead::parse(bytes)?.map(|head| (head.mapping_family, head.stream_count)))
}

pub fn decode_with(
    codec: Box<dyn AudioDecoder>,
    reader: Box<dyn FormatReader>,
    track_id: u32,
    sample_rate: u32,
    output: &mut [u8],
) -> Result<usize, Error> {
    Decoder::new(codec, sample_rate, None)?.read(&mut Demuxer::new(reader, track_id), sample_rate, output)
}

pub fn set_sample_rate(session: &mut Session, sample_rate: u32) {
    session.sample_rate = sample_rate;
}

pub fn resampled_frames(resampler: &StereoResampler) -> u64 {
    resampler.trim.output_frames
}

pub fn expected_frames(resampler: &StereoResampler) -> u64 {
    resampler.expected_frames()
}

pub fn output_closed(stream: &StreamSession) -> (bool, bool) {
    let status = lock(&stream.status);
    let closed = matches!(stream.output.try_recv(), Err(TryRecvError::Disconnected));

    (closed, status.failure().is_some())
}

pub fn chunk_reader(chunks: Receiver<Vec<u8>>) -> (impl Read + Send + Sync, impl Fn() + Send) {
    let status = Arc::new(Mutex::new(Status::new()));
    let stopped = Arc::clone(&status);

    (ChunkReader::new(Arc::new(Mutex::new(chunks)), status), move || lock(&stopped).stop())
}
