//! Test hooks and white-box accessors for the integration tests in `tests/`. Built only with the `testing` feature,
//! which only the crate's own dev-dependency turns on.

use std::any::Any;
use std::io::Read;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc::{Receiver, TryRecvError};
use std::sync::{Arc, Mutex};

use crate::chunk_reader::ChunkReader;
use crate::error::Error;
use crate::fields::State;
use crate::guard::lock;
use crate::opus::OpusHead;
use crate::resample::StereoResampler;
use crate::session::Session;
use crate::status::Status;
use crate::stream::StreamSession;
use crate::{guard, resample, stream};

/// A chunk that starts with this makes the worker's reader panic, with the rest of the chunk as the message.
pub const PANIC: &[u8] = b"\0a test panic: ";
/// The chunks a stream's input holds before `StreamSession::push` returns `Full`.
pub const INPUT_CHUNKS: usize = stream::INPUT_CHUNKS;
/// The blocks a stream's output holds before its worker waits.
pub const OUTPUT_BLOCKS: usize = stream::OUTPUT_BLOCKS;
/// The most frames one stream block holds.
pub const BLOCK_FRAMES: usize = stream::BLOCK_FRAMES;
/// The frames the resampler takes in each round.
pub const RESAMPLER_CHUNK_FRAMES: usize = resample::CHUNK_FRAMES;

/// Every worker's queued blocks, counted by `count_block`.
static BLOCKS_SENT: AtomicUsize = AtomicUsize::new(0);

/// The hook in the worker's reader: panics on a chunk that starts with `PANIC`.
#[expect(clippy::panic, reason = "the hook fails a stream's worker on request")]
pub(crate) fn panic_on_request(chunk: &[u8]) {
    if let Some(message) = chunk.strip_prefix(PANIC) {
        panic!("{}", String::from_utf8_lossy(message));
    }
}

/// The hook in the worker's decode loop: counts each block sent to the output.
pub(crate) fn count_block() {
    BLOCKS_SENT.fetch_add(1, Ordering::SeqCst);
}

/// The blocks every stream worker has sent to its output.
pub fn blocks_sent() -> usize {
    BLOCKS_SENT.load(Ordering::SeqCst)
}

/// The error the panic guard makes from a caught panic's `payload`.
pub fn panic_error(payload: &(dyn Any + Send)) -> Error {
    guard::panic_error(payload)
}

/// The mapping family and stream count of the `OpusHead` at the start of `bytes`, as `opus::check_passthrough` reads
/// them.
pub fn parse_opus_head(bytes: &[u8]) -> Result<Option<(u8, u8)>, Error> {
    Ok(OpusHead::parse(bytes)?.map(|head| (head.mapping_family, head.stream_count)))
}

/// Changes the sample rate `session` expects its decoded audio at.
pub fn set_sample_rate(session: &mut Session, sample_rate: u32) {
    session.sample_rate = sample_rate;
}

/// The frames `resampler` has appended to its output.
pub fn resampled_frames(resampler: &StereoResampler) -> u64 {
    resampler.trim.output_frames
}

/// The frames `resampler`'s input so far makes at 48 kHz.
pub fn expected_frames(resampler: &StereoResampler) -> u64 {
    resampler.expected_frames()
}

/// The state `stream`'s worker last stored.
pub fn stream_state(stream: &StreamSession) -> State {
    stream.state()
}

/// The failure `stream`'s worker stored, if any.
pub fn stream_failure(stream: &StreamSession) -> Option<Error> {
    stream.failure()
}

/// Whether `stream`'s output has closed, and whether a failure is stored, both read under one hold of the status lock.
pub fn output_closed(stream: &StreamSession) -> (bool, bool) {
    let status = lock(&stream.status);
    let closed = matches!(stream.output.try_recv(), Err(TryRecvError::Disconnected));

    (closed, status.failure().is_some())
}

/// A stream worker's reader over `chunks`, and a function that stops it as closing its session does.
pub fn chunk_reader(chunks: Receiver<Vec<u8>>) -> (impl Read + Send + Sync, impl Fn() + Send) {
    let status = Arc::new(Mutex::new(Status::new()));
    let stopped = Arc::clone(&status);

    (ChunkReader::new(Arc::new(Mutex::new(chunks)), status), move || lock(&stopped).stop())
}
