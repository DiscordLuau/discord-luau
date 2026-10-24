mod chunk_reader;
mod decoder;
mod demuxer;
mod error;
mod ffi;
mod fields;
mod guard;
mod handle;
pub mod limits;
mod mix;
pub mod opus;
mod resample;
mod session;
mod status;
mod stream;
#[cfg(feature = "testing")]
pub mod testing;
pub mod wav;

use std::ffi::c_char;
use std::ptr;
use std::task::Poll;

use crate::ffi::TextBuffer;
use crate::guard::{catch, guarded, guarded_session};
pub use crate::{
    decoder::BYTES_PER_FRAME,
    error::Error,
    fields::{DescribeField, InfoField, State, UNKNOWN},
    handle::Handle,
    mix::{OUTPUT_CHANNELS, StereoMix},
    resample::StereoResampler,
    session::{Info, Session},
    stream::{PushOutcome, StreamSession},
};

pub const ABI_VERSION: i32 = 3;
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

/// Opens a copy of the `length` bytes at `data`, returning the session or null with the error in `error_out`.
///
/// # Safety
///
/// `data` must hold `length` bytes, `extension` be null or NUL-terminated, `error_out` null or `error_capacity` long.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_open_memory(
    data: *const u8,
    length: u32,
    extension: *const c_char,
    error_out: *mut u8,
    error_capacity: u32,
) -> *mut Handle {
    // SAFETY: the caller guarantees `length` readable bytes at `data`.
    let bytes = unsafe { ffi::input_slice(data, length) };
    // SAFETY: the caller guarantees that `extension` is null or a NUL-terminated string.
    let extension = unsafe { ffi::c_str(extension) };
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, ptr::null_mut(), || Handle::open_memory(bytes, extension).map(Handle::into_raw))
}

/// Opens the file at `path`, read as it plays, returning the session or null with the error in `error_out`.
///
/// # Safety
///
/// `path` and `extension` must be null or NUL-terminated, and `error_out` null or `error_capacity` bytes long.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_open_file(
    path: *const c_char,
    extension: *const c_char,
    error_out: *mut u8,
    error_capacity: u32,
) -> *mut Handle {
    // SAFETY: the caller guarantees that `path` is null or a NUL-terminated string.
    let path = unsafe { ffi::c_str(path) };
    // SAFETY: the caller guarantees that `extension` is null or a NUL-terminated string.
    let extension = unsafe { ffi::c_str(extension) };
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, ptr::null_mut(), || Handle::open_file(path, extension).map(Handle::into_raw))
}

/// Starts a stream session, returning it or null with the error in `error_out`.
///
/// # Safety
///
/// `error_out` must be null or valid for writes of `error_capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_open_stream(error_out: *mut u8, error_capacity: u32) -> *mut Handle {
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded(error_out, ptr::null_mut(), || StreamSession::open().map(|stream| Handle::Stream(stream).into_raw()))
}

/// Queues a copy of the `length` bytes at `data` for the stream's worker: `SUCCEEDED`, `FULL` or `FAILED`.
///
/// # Safety
///
/// `handle` must be null or an open session, and `data` hold `length` bytes when `length` is not 0.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_push(handle: *mut Handle, data: *const u8, length: u32) -> i32 {
    // SAFETY: the caller guarantees that `handle` is null or an open session.
    let stream = unsafe { handle.as_ref() }.and_then(Handle::as_stream);
    // SAFETY: the caller guarantees `length` readable bytes at `data` when `length` is not 0.
    let chunk = unsafe { ffi::input_slice(data, length) };

    match catch(|| Some(stream?.push(chunk?.to_vec()))) {
        Ok(Some(PushOutcome::Queued)) => SUCCEEDED,
        Ok(Some(PushOutcome::Full)) => FULL,
        Ok(Some(PushOutcome::Refused) | None) | Err(_) => FAILED,
    }
}

/// Ends the stream's input: `SUCCEEDED`, also for a second call, or `FAILED` for anything but a stream.
///
/// # Safety
///
/// `handle` must be null or an open session.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_finish(handle: *mut Handle) -> i32 {
    // SAFETY: the caller guarantees that `handle` is null or an open session.
    let stream = unsafe { handle.as_mut() }.and_then(Handle::as_stream_mut);

    match catch(|| stream.map(StreamSession::finish)) {
        Ok(Some(())) => SUCCEEDED,
        Ok(None) | Err(_) => FAILED,
    }
}

/// Returns `InfoField` number `field` of the session, or `FAILED` for a null `handle` or an unknown field.
///
/// # Safety
///
/// `handle` must be null or an open session.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_info(handle: *mut Handle, field: i32) -> i32 {
    // SAFETY: the caller guarantees that `handle` is null or an open session.
    let handle = unsafe { handle.as_ref() };

    match (handle, InfoField::from_number(field)) {
        (Some(handle), Some(field)) => catch(|| field.value(handle.state(), handle.info().as_ref())).unwrap_or(FAILED),
        _ => FAILED,
    }
}

/// Writes `DescribeField` number `field` of the session into `output` as NUL-terminated text, truncated.
///
/// # Safety
///
/// `handle` must be null or an open session, and `output` null or valid for writes of `capacity` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_describe(handle: *mut Handle, field: i32, output: *mut u8, capacity: u32) -> i32 {
    // SAFETY: the caller guarantees that `handle` is null or an open session.
    let handle = unsafe { handle.as_ref() };
    // SAFETY: the caller guarantees that `output` is null or has `capacity` writable bytes.
    let output = unsafe { TextBuffer::new(output, capacity) };

    match (handle, DescribeField::from_number(field)) {
        (Some(handle), Some(field)) => {
            catch(|| ffi::saturate_to_i32(output.write(&handle.describe(field)))).unwrap_or(FAILED)
        }
        _ => FAILED,
    }
}

/// Reads up to `capacity_frames` frames of 48 kHz stereo f32 into `output`: the count, 0 at the end, or a code.
///
/// # Safety
///
/// `handle` must be null or an open session, `output` null or `capacity_frames * BYTES_PER_FRAME` initialized bytes
/// nothing else uses, and `error_out` null or `error_capacity` writable bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_read(
    handle: *mut Handle,
    output: *mut u8,
    capacity_frames: u32,
    error_out: *mut u8,
    error_capacity: u32,
) -> i32 {
    let capacity = ffi::capped_capacity(capacity_frames).saturating_mul(BYTES_PER_FRAME);
    // SAFETY: the caller guarantees that `handle` is null or an open session.
    let handle = unsafe { handle.as_mut() };
    // SAFETY: the caller guarantees that `output` is null or has at least `capacity` unshared initialized bytes.
    let output = unsafe { ffi::output_slice(output, capacity) };
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded_session(handle, error_out, FAILED, |handle| match handle.read(output.ok_or(Error::NullOutput)?)? {
        Poll::Ready(frames) => Ok(ffi::saturate_to_i32(frames)),
        Poll::Pending => Ok(NOT_READY),
    })
}

/// Reads the next Opus packet into `output`: its length, `END` at the end, or a code.
///
/// # Safety
///
/// `handle` must be null or an open session, `output` null or `capacity` initialized bytes nothing else uses, and
/// `error_out` null or `error_capacity` writable bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_read_packet(
    handle: *mut Handle,
    output: *mut u8,
    capacity: u32,
    error_out: *mut u8,
    error_capacity: u32,
) -> i32 {
    // SAFETY: the caller guarantees that `handle` is null or an open session.
    let handle = unsafe { handle.as_mut() };
    // SAFETY: the caller guarantees `output` is null or has at least the capped `capacity` unshared initialized bytes.
    let output = unsafe { ffi::output_slice(output, ffi::capped_capacity(capacity)) };
    // SAFETY: the caller guarantees that `error_out` is null or has `error_capacity` writable bytes.
    let error_out = unsafe { TextBuffer::new(error_out, error_capacity) };

    guarded_session(handle, error_out, FAILED, |handle| match handle.read_packet(output.ok_or(Error::NullOutput)?)? {
        Poll::Ready(Some(length)) => Ok(ffi::saturate_to_i32(length)),
        Poll::Ready(None) => Ok(END),
        Poll::Pending => Ok(NOT_READY),
    })
}

/// Frees the session; a null `handle` does nothing, and a stream's worker is stopped, never waited for.
///
/// # Safety
///
/// `handle` must be null or an open session, and is never used again.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn symphonia_close(handle: *mut Handle) {
    // SAFETY: the caller guarantees that `handle` is null or an open session, never used again.
    let handle = unsafe { Handle::from_raw(handle) };

    let _ = catch(|| drop(handle));
}

/// Returns the number of sessions opened and not closed yet.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_open_count() -> i32 {
    handle::open_count()
}

/// Returns the number of stream worker threads that have not exited, which the specs use to show none leak.
#[unsafe(no_mangle)]
pub extern "C" fn symphonia_worker_count() -> i32 {
    stream::worker_count()
}
