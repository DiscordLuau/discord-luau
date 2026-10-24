//! The C ABI over Symphonia for the `discord_luau/symphonia` Luau package. Every export is named `symphonia_<name>`,
//! which keeps each `#[unsafe(no_mangle)]` symbol unique.

#![expect(
    clippy::missing_errors_doc,
    clippy::must_use_candidate,
    reason = "the Rust API is for the crate's own tests in tests/; callers use the C ABI"
)]

mod chunk_reader;
mod decoder;
mod demuxer;
mod error;
mod ffi;
mod fields;
mod guard;
pub mod limits;
mod mix;
pub mod opus;
mod resample;
mod session;
mod session_table;
mod status;
mod stream;
#[cfg(feature = "testing")]
pub mod testing;
pub mod wav;

pub use crate::{
    decoder::BYTES_PER_FRAME,
    error::Error,
    ffi::{OutputBuffer, TextBuffer, capped_capacity, copy_in, saturate_to_i32},
    fields::{DescribeField, InfoField, State, UNKNOWN},
    guard::guarded,
    mix::{OUTPUT_CHANNELS, StereoMix},
    resample::StereoResampler,
    session::Session,
    session_table::{Entry, with_session, with_stream},
    stream::{PushOutcome, StreamSession},
};

use std::ffi::{CStr, c_char};
use std::task::Poll;

use crate::guard::catch_quietly;

pub const ABI_VERSION: i32 = 2;
pub const FAILED: i32 = -1;
pub const NOT_READY: i32 = -2;
pub const FULL: i32 = -3;
pub const SUCCEEDED: i32 = 0;
pub const END: i32 = 0;

/// Returns `ABI_VERSION`; the Luau package refuses any other.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_abi_version() -> i32 {
    ABI_VERSION
}

/// Opens a copy of the `length` bytes at `data`, and returns its id or `FAILED` with the error in `error_out`.
///
/// An empty buffer is an error. `extension` is an optional hint, which Symphonia 0.6.1's probe ignores.
///
/// # Safety
///
/// `data` must be valid for reads of `length` bytes. `extension` must be null or a NUL-terminated string. `error_out`
/// must be null or valid for writes of `error_capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_open_memory(
    data: *const u8,
    length: u32,
    extension: *const c_char,
    error_out: *mut u8,
    error_capacity: u32,
) -> i32 {
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, FAILED, || {
        // SAFETY: the caller guarantees `length` readable bytes at `data`.
        let bytes = unsafe { ffi::copy_in(data, length) }.ok_or(Error::NullAudio)?;
        // SAFETY: the caller guarantees that `extension` is null or a NUL-terminated string.
        let extension = unsafe { ffi::c_str(extension) }.map(CStr::to_string_lossy);

        session_table::insert(Entry::Direct(Session::open_memory(bytes, extension.as_deref())?))
    })
}

/// Opens the file at `path`, read as it plays, and returns the session's id or `FAILED` with the error in `error_out`.
///
/// With a null `extension`, the path's extension is the hint.
///
/// # Safety
///
/// `path` and `extension` must each be null or a NUL-terminated string. `error_out` must be null or valid for writes
/// of `error_capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_open_file(
    path: *const c_char,
    extension: *const c_char,
    error_out: *mut u8,
    error_capacity: u32,
) -> i32 {
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, FAILED, || {
        // SAFETY: the caller guarantees that `path` is null or a NUL-terminated string.
        let path = unsafe { ffi::c_str(path) }.ok_or(Error::NullPath)?;
        let path = path.to_str().map_err(|_| Error::PathNotUtf8)?;
        // SAFETY: the caller guarantees that `extension` is null or a NUL-terminated string.
        let extension = unsafe { ffi::c_str(extension) }.map(CStr::to_string_lossy);

        session_table::insert(Entry::Direct(Session::open_file(path, extension.as_deref())?))
    })
}

/// Starts a stream session, whose worker thread decodes the bytes `symphonia_push` gives it.
///
/// Returns the session's id, or `FAILED` with the error in `error_out`.
///
/// # Safety
///
/// `error_out` must be null or valid for writes of `error_capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_open_stream(error_out: *mut u8, error_capacity: u32) -> i32 {
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, FAILED, || session_table::insert(Entry::Stream(StreamSession::open()?)))
}

/// Queues a copy of the `length` bytes at `data` for stream `id`'s worker, without blocking.
///
/// Returns `SUCCEEDED` (an empty push queues nothing), `FULL` while the input holds `INPUT_CHUNKS` chunks, or `FAILED`
/// for an id that is not a live stream, after `symphonia_finish`, and once the stream has ended or failed.
///
/// # Safety
///
/// `data` must be valid for reads of `length` bytes when `length` is not 0.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_push(id: i32, data: *const u8, length: u32) -> i32 {
    let outcome = catch_quietly(|| {
        // SAFETY: the caller guarantees `length` readable bytes at `data` when `length` is not 0.
        let chunk = unsafe { ffi::copy_in(data, length) }?;

        session_table::with_stream(id, |stream| stream.push(chunk))
    });

    match outcome {
        Ok(Some(PushOutcome::Queued)) => SUCCEEDED,
        Ok(Some(PushOutcome::Full)) => FULL,
        Ok(Some(PushOutcome::Refused) | None) | Err(_) => FAILED,
    }
}

/// Ends stream `id`'s input, so its worker decodes what was pushed and then ends.
///
/// Returns `SUCCEEDED`, also for a second call, or `FAILED` for an id that is not a live stream.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_finish(id: i32) -> i32 {
    match catch_quietly(|| session_table::with_stream(id, StreamSession::finish)) {
        Ok(Some(())) => SUCCEEDED,
        Ok(None) | Err(_) => FAILED,
    }
}

/// Returns `InfoField` number `field` of session `id`, or `FAILED` for an unknown id or field.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_info(id: i32, field: i32) -> i32 {
    catch_quietly(|| {
        let field = InfoField::from_number(field)?;

        session_table::with_entry(id, |entry| entry.info(field))
    })
    .ok()
    .flatten()
    .unwrap_or(FAILED)
}

/// Writes `DescribeField` number `field` of session `id` into `output` as NUL-terminated text, truncated to `capacity`.
///
/// Returns the bytes written without the NUL, or `FAILED` for an unknown id or field.
///
/// # Safety
///
/// `output` must be null or valid for writes of `capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_describe(id: i32, field: i32, output: *mut u8, capacity: u32) -> i32 {
    // SAFETY: the caller guarantees that `output` is null or has `capacity` writable bytes.
    let output = unsafe { TextBuffer::new(output, capacity) };

    catch_quietly(|| {
        let field = DescribeField::from_number(field)?;
        let text = session_table::with_entry(id, |entry| entry.describe(field))?;

        Some(ffi::saturate_to_i32(output.write(&text)))
    })
    .ok()
    .flatten()
    .unwrap_or(FAILED)
}

/// Reads up to `capacity_frames` frames of 48 kHz interleaved stereo f32 into `output`, `BYTES_PER_FRAME` bytes each.
///
/// Returns the frames written, 0 at the end, `NOT_READY` while a stream has nothing decoded, or `FAILED` with the
/// error in `error_out`. A `capacity_frames` of 0 is an error, since 0 frames would read as the end. A stream read
/// never blocks, returns at most one `BLOCK_FRAMES` block, and gives its failure only after every block before it.
///
/// # Safety
///
/// `output` must be null or valid for writes of `capacity_frames * BYTES_PER_FRAME` bytes. `error_out` must be null
/// or valid for writes of `error_capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_read(
    id: i32,
    output: *mut u8,
    capacity_frames: u32,
    error_out: *mut u8,
    error_capacity: u32,
) -> i32 {
    let capacity = (capacity_frames as usize).saturating_mul(BYTES_PER_FRAME);
    // SAFETY: the caller guarantees that `output` is null or has `capacity_frames * BYTES_PER_FRAME` writable bytes,
    // which is at least `capacity`.
    let output = unsafe { OutputBuffer::new(output, capacity) };
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, FAILED, || {
        with_session(id, |entry| {
            let output = output.ok_or(Error::NullOutput)?;

            if capacity_frames == 0 {
                return Err(Error::ZeroCapacity);
            }

            match entry.read(ffi::capped_capacity(capacity_frames))? {
                Poll::Ready(bytes) => Ok(ffi::saturate_to_i32(output.write(bytes) / BYTES_PER_FRAME)),
                Poll::Pending => Ok(NOT_READY),
            }
        })
    })
}

/// Reads the next Opus packet into `output`, and returns its length in bytes.
///
/// Returns `END` at the end, `NOT_READY` while a stream has no packet, or `FAILED` with the error in `error_out`. Empty
/// packets are skipped and counted. A packet over `capacity` bytes is an error, and stays next for a bigger buffer.
///
/// # Safety
///
/// `output` must be null or valid for writes of `capacity` bytes. `error_out` must be null or valid for writes of
/// `error_capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_read_packet(
    id: i32,
    output: *mut u8,
    capacity: u32,
    error_out: *mut u8,
    error_capacity: u32,
) -> i32 {
    // SAFETY: the caller guarantees that `output` is null or has `capacity` writable bytes.
    let output = unsafe { OutputBuffer::new(output, capacity as usize) };
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, FAILED, || {
        with_session(id, |entry| {
            let output = output.ok_or(Error::NullOutput)?;

            match entry.read_packet(ffi::capped_capacity(capacity))? {
                Poll::Ready(Some(packet)) => Ok(ffi::saturate_to_i32(output.write(&packet))),
                Poll::Ready(None) => Ok(END),
                Poll::Pending => Ok(NOT_READY),
            }
        })
    })
}

/// Frees session `id`; an unknown id does nothing. A stream's worker is stopped, never waited for.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_close(id: i32) {
    let _ = catch_quietly(|| drop(session_table::remove(id)));
}

/// Returns the number of live sessions.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_open_count() -> i32 {
    catch_quietly(|| ffi::saturate_to_i32(session_table::count())).unwrap_or(FAILED)
}

/// Returns the number of stream worker threads that have not exited, which the specs use to show none leak.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_worker_count() -> i32 {
    stream::worker_count()
}
