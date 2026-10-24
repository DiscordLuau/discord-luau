//! The caller's buffers and strings as safe values, and counts as the ABI's `i32`. A raw buffer or string becomes a
//! safe value only through an `unsafe fn` here.

use std::ffi::{CStr, c_char};
use std::ptr;
use std::slice;

const MAX_COUNT: u32 = i32::MAX.unsigned_abs();

/// A caller's buffer for NUL-terminated UTF-8, or none when its pointer is null.
#[derive(Clone, Copy)]
pub(crate) struct TextBuffer {
    pointer: *mut u8,
    capacity: u32,
}

impl TextBuffer {
    /// # Safety
    ///
    /// `pointer` must be null or valid for writes of `capacity` bytes for as long as the buffer is used.
    pub(crate) unsafe fn new(pointer: *mut u8, capacity: u32) -> Self {
        Self { pointer, capacity }
    }

    /// Writes `text`, cut at a character boundary to fit with its NUL, and returns the bytes written without the NUL.
    ///
    /// A null or zero-capacity buffer gets nothing.
    pub(crate) fn write(self, text: &str) -> usize {
        if self.pointer.is_null() || self.capacity == 0 {
            return 0;
        }

        let length = text.floor_char_boundary(self.capacity as usize - 1);

        // SAFETY: `new`'s caller guarantees `capacity` writable bytes, and `length` is below `capacity`. `text` is the
        // crate's own memory, so the two cannot overlap.
        unsafe { ptr::copy_nonoverlapping(text.as_ptr(), self.pointer, length) };
        // SAFETY: `length` is below `capacity`, so the NUL lands inside the buffer.
        unsafe { self.pointer.wrapping_add(length).write(0) };

        length
    }
}

/// # Safety
///
/// `data` must be null or hold `length` bytes, unless 0, that nothing writes during `'data`.
pub(crate) unsafe fn input_slice<'data>(data: *const u8, length: u32) -> Option<&'data [u8]> {
    if length == 0 {
        return Some(&[]);
    }

    if data.is_null() {
        return None;
    }

    // SAFETY: `data` is not null, and the caller guarantees `length` readable bytes there that nothing writes.
    Some(unsafe { slice::from_raw_parts(data, length as usize) })
}

/// # Safety
///
/// `pointer` must be null or hold `length` initialized bytes, unless 0, that nothing else uses during `'output`.
pub(crate) unsafe fn output_slice<'output>(pointer: *mut u8, length: usize) -> Option<&'output mut [u8]> {
    if pointer.is_null() {
        return None;
    }

    if length == 0 {
        return Some(&mut []);
    }

    // SAFETY: `pointer` is not null, and the caller guarantees `length` initialized bytes there that nothing else uses.
    Some(unsafe { slice::from_raw_parts_mut(pointer, length) })
}

/// # Safety
///
/// `text` must be null or point to a NUL-terminated string that outlives `'text`.
pub(crate) unsafe fn c_str<'text>(text: *const c_char) -> Option<&'text CStr> {
    if text.is_null() {
        return None;
    }

    // SAFETY: `text` is not null, and the caller guarantees a NUL-terminated string that outlives `'text`.
    Some(unsafe { CStr::from_ptr(text) })
}

/// A caller's capacity, capped so that a count of what fills it fits an export's `i32` result.
pub(crate) fn capped_capacity(capacity: u32) -> usize {
    capacity.min(MAX_COUNT) as usize
}

pub(crate) fn saturate_to_i32(value: impl TryInto<i32>) -> i32 {
    value.try_into().unwrap_or(i32::MAX)
}
