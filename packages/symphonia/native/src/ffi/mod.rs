//! The caller's pointers as safe values, and counts as the ABI's `i32`. A raw pointer becomes a safe value only
//! through an `unsafe fn` here.

use std::ffi::{CStr, c_char};
use std::ptr::{self, NonNull};
use std::slice;

const MAX_COUNT: u32 = i32::MAX.unsigned_abs();

/// A caller's buffer for NUL-terminated UTF-8, or none when its pointer is null.
#[derive(Clone, Copy)]
pub struct TextBuffer {
    pointer: *mut u8,
    capacity: u32,
}

impl TextBuffer {
    /// # Safety
    ///
    /// `pointer` must be null or valid for writes of `capacity` bytes for as long as the buffer is used.
    pub unsafe fn new(pointer: *mut u8, capacity: u32) -> Self {
        Self { pointer, capacity }
    }

    /// Writes `text`, cut at a character boundary to fit with its NUL, and returns the bytes written without the NUL.
    ///
    /// A null or zero-capacity buffer gets nothing.
    pub fn write(self, text: &str) -> usize {
        if self.pointer.is_null() || self.capacity == 0 {
            return 0;
        }

        let room = self.capacity as usize - 1;
        let mut length = text.len().min(room);

        while !text.is_char_boundary(length) {
            length -= 1;
        }

        // SAFETY: `new`'s caller guarantees `capacity` writable bytes, and `length` is below `capacity`. `text` is the
        // crate's own memory, so the two cannot overlap.
        unsafe { ptr::copy_nonoverlapping(text.as_ptr(), self.pointer, length) };
        // SAFETY: `length` is below `capacity`, so the NUL lands inside the buffer.
        unsafe { self.pointer.wrapping_add(length).write(0) };

        length
    }
}

/// A caller's buffer for decoded bytes.
#[derive(Clone, Copy)]
pub struct OutputBuffer {
    pointer: NonNull<u8>,
    capacity: usize,
}

impl OutputBuffer {
    /// Returns `None` when `pointer` is null.
    ///
    /// # Safety
    ///
    /// `pointer` must be null or valid for writes of `capacity` bytes for as long as the buffer is used.
    pub unsafe fn new(pointer: *mut u8, capacity: usize) -> Option<Self> {
        NonNull::new(pointer).map(|pointer| Self { pointer, capacity })
    }

    /// Copies as much of `bytes` as fits, and returns the bytes copied.
    pub fn write(self, bytes: &[u8]) -> usize {
        let length = bytes.len().min(self.capacity);

        // SAFETY: `new`'s caller guarantees `capacity` writable bytes, and `length` is at most `capacity`. `bytes` is
        // the crate's own memory, so the two cannot overlap.
        unsafe { ptr::copy_nonoverlapping(bytes.as_ptr(), self.pointer.as_ptr(), length) };

        length
    }
}

/// Copies the `length` bytes at `data`: empty for a `length` of 0 whatever `data` is, and `None` for a null `data`.
///
/// # Safety
///
/// When `length` is not 0 and `data` is not null, `data` must be valid for reads of `length` bytes.
pub unsafe fn copy_in(data: *const u8, length: u32) -> Option<Vec<u8>> {
    if length == 0 {
        return Some(Vec::new());
    }

    if data.is_null() {
        return None;
    }

    // SAFETY: `data` is not null, and the caller guarantees `length` readable bytes there.
    Some(unsafe { slice::from_raw_parts(data, length as usize) }.to_vec())
}

/// # Safety
///
/// `text` must be null or point to a NUL-terminated string that outlives `'text`.
pub unsafe fn c_str<'text>(text: *const c_char) -> Option<&'text CStr> {
    if text.is_null() {
        return None;
    }

    // SAFETY: `text` is not null, and the caller guarantees a NUL-terminated string that outlives `'text`.
    Some(unsafe { CStr::from_ptr(text) })
}

/// A caller's capacity, capped so that a count of what fills it fits an export's `i32` result.
pub fn capped_capacity(capacity: u32) -> usize {
    capacity.min(MAX_COUNT) as usize
}

pub fn saturate_to_i32(value: impl TryInto<i32>) -> i32 {
    value.try_into().unwrap_or(i32::MAX)
}

#[cfg(test)]
mod tests;
