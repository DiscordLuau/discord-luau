//! Writing text and bytes into a caller's buffers, copying a caller's bytes in, and the ABI's number conversions.

#![expect(clippy::undocumented_unsafe_blocks, reason = "every buffer is one the test owns, with the size it passes")]

use super::*;

/// Writes `text` into a 16-byte buffer of `0xAA` that claims `capacity` bytes.
fn written(capacity: u32, text: &str) -> (usize, Vec<u8>) {
    let mut buffer = vec![0xAA_u8; 16];
    let length = unsafe { TextBuffer::new(buffer.as_mut_ptr(), capacity) }.write(text);

    (length, buffer)
}

#[test]
fn writes_the_whole_text_with_a_nul() {
    let (length, buffer) = written(16, "hello");

    assert_eq!(length, 5);
    assert_eq!(&buffer[..6], b"hello\0");
    assert_eq!(buffer[6], 0xAA, "nothing is written past the NUL");
}

#[test]
fn truncates_to_the_capacity_and_never_writes_past_it() {
    let (length, buffer) = written(4, "hello");

    assert_eq!(length, 3);
    assert_eq!(&buffer[..4], b"hel\0");
    assert!(buffer[4..].iter().all(|&byte| byte == 0xAA));
}

#[test]
fn a_capacity_of_one_writes_only_the_nul() {
    let (length, buffer) = written(1, "hello");

    assert_eq!(length, 0);
    assert_eq!(buffer[0], 0);
    assert_eq!(buffer[1], 0xAA);
}

#[test]
fn truncation_keeps_utf8_whole() {
    // "é" is two bytes, so a capacity of 3 leaves room for "a" and the NUL only.
    let (length, buffer) = written(3, "aé");

    assert_eq!(length, 1);
    assert_eq!(&buffer[..2], b"a\0");
}

#[test]
fn a_zero_capacity_writes_nothing() {
    let (length, buffer) = written(0, "hello");

    assert_eq!(length, 0);
    assert!(buffer.iter().all(|&byte| byte == 0xAA));
}

#[test]
fn a_null_buffer_writes_nothing() {
    let length = unsafe { TextBuffer::new(std::ptr::null_mut(), 64) }.write("hello");

    assert_eq!(length, 0);
}

#[test]
fn an_output_buffer_copies_what_fits_and_nothing_more() {
    let mut buffer = [0xAA_u8; 8];
    let output = unsafe { OutputBuffer::new(buffer.as_mut_ptr(), 4) }.unwrap();

    assert_eq!(output.write(b"abcdef"), 4);
    assert_eq!(&buffer, b"abcd\xAA\xAA\xAA\xAA");
    assert!(unsafe { OutputBuffer::new(std::ptr::null_mut(), 4) }.is_none(), "a null buffer is none");
}

#[test]
fn copy_in_takes_a_zero_length_as_empty_and_a_null_pointer_as_none() {
    let bytes = [1_u8, 2, 3];

    assert_eq!(unsafe { copy_in(bytes.as_ptr(), 3) }, Some(vec![1, 2, 3]));
    assert_eq!(unsafe { copy_in(std::ptr::null(), 0) }, Some(Vec::new()));
    assert_eq!(unsafe { copy_in(std::ptr::null(), 3) }, None);
}

#[test]
fn counts_saturate_to_the_abi_range() {
    assert_eq!(saturate_to_i32(7_u64), 7);
    assert_eq!(saturate_to_i32(u64::MAX), i32::MAX);
    assert_eq!(capped_capacity(10), 10);
    assert_eq!(capped_capacity(u32::MAX), i32::MAX as usize);
}
