//! The exports, called as Luau calls them: session pointers, error buffers, field numbers, codes and the panic guard.
//! Also the pieces under them: the caller's buffers, the field enums and the panic payloads.

#![expect(clippy::undocumented_unsafe_blocks, reason = "every ABI call passes buffers the test owns")]

use std::ptr;

use discord_luau_symphonia::testing::{
    capped_capacity, guarded, guarded_session, input, output, panic_error, saturate_to_i32, write_text,
};
use discord_luau_symphonia::{
    DescribeField, InfoField, State, symphonia_abi_version, symphonia_describe, symphonia_open_count,
    symphonia_open_file, symphonia_open_memory, symphonia_push, symphonia_read, symphonia_read_packet,
};

use crate::files::{tone_sample, wav};
use crate::util::{ERROR_CAPACITY, close, finish, info, open, read, read_to_end, serial, text};

#[test]
fn the_abi_version_is_three() {
    assert_eq!(symphonia_abi_version(), 3);
}

#[test]
fn an_open_returns_a_session_pointer() {
    let _serial = serial();
    let (first, message) = open(&wav(48_000, 1, 10), None);
    let (second, _) = open(&wav(48_000, 1, 10), None);

    assert!(!first.is_null(), "{message}");
    assert!(!second.is_null() && second != first, "each open is its own session");

    close(first);
    close(second);
}

#[test]
fn closing_null_does_nothing() {
    let _serial = serial();
    let start = symphonia_open_count();

    close(ptr::null_mut());

    assert_eq!(symphonia_open_count(), start);
}

#[test]
fn a_session_opens_reads_and_closes() {
    let _serial = serial();
    let start = symphonia_open_count();
    let (handle, message) = open(&wav(44_100, 2, 22_050), Some(c"wav"));

    assert!(!handle.is_null(), "{message}");
    assert_eq!(symphonia_open_count(), start + 1);
    assert_eq!(info(handle, 0), 44_100);
    assert_eq!(info(handle, 1), 2);
    assert_eq!(info(handle, 2), 0);
    assert_eq!(info(handle, 3), 500);
    assert_eq!(info(handle, 4), 0);
    assert_eq!(info(handle, 5), 0);
    assert_eq!(info(handle, 7), 1, "open");

    let mut name = [0xAA_u8; 64];
    let written = unsafe { symphonia_describe(handle, 1, name.as_mut_ptr(), 64) };

    assert_eq!(written, 4);
    assert_eq!(text(&name), "wave");
    assert_eq!(read_to_end(handle, 48_000), 24_000);
    assert_eq!(info(handle, 7), 2, "ended");
    assert_eq!(read(handle, 4800).0, 0, "the end stays the end");
    assert_eq!(info(handle, 7), 2);

    close(handle);

    assert_eq!(symphonia_open_count(), start);
}

#[test]
fn open_memory_rejects_an_empty_buffer() {
    let mut error = [0xAA_u8; 64];
    let handle = unsafe { symphonia_open_memory(ptr::null(), 0, ptr::null(), error.as_mut_ptr(), 64) };

    assert!(handle.is_null());
    assert_eq!(text(&error), "the audio is empty");

    let bytes = [1_u8; 4];
    let handle = unsafe { symphonia_open_memory(bytes.as_ptr(), 0, ptr::null(), error.as_mut_ptr(), 64) };

    assert!(handle.is_null());
    assert_eq!(text(&error), "the audio is empty");
}

#[test]
fn open_memory_rejects_a_null_pointer_with_a_length() {
    let mut error = [0xAA_u8; 64];
    let handle = unsafe { symphonia_open_memory(ptr::null(), 10, ptr::null(), error.as_mut_ptr(), 64) };

    assert!(handle.is_null());
    assert_eq!(text(&error), "the audio pointer is null");
}

#[test]
fn open_errors_are_truncated_with_a_nul() {
    let mut error = [0xAA_u8; 8];
    let handle = unsafe { symphonia_open_memory(ptr::null(), 0, ptr::null(), error.as_mut_ptr(), 5) };

    assert!(handle.is_null());
    assert_eq!(&error[..5], b"the \0");
    assert!(error[5..].iter().all(|&byte| byte == 0xAA), "nothing past the capacity");
}

#[test]
fn a_null_or_zero_capacity_error_buffer_gets_nothing() {
    let handle = unsafe { symphonia_open_memory(ptr::null(), 0, ptr::null(), ptr::null_mut(), 64) };

    assert!(handle.is_null());

    let mut error = [0xAA_u8; 8];
    let handle = unsafe { symphonia_open_memory(ptr::null(), 0, ptr::null(), error.as_mut_ptr(), 0) };

    assert!(handle.is_null());
    assert!(error.iter().all(|&byte| byte == 0xAA));

    let result = unsafe { symphonia_read(ptr::null_mut(), [0_u8; 8].as_mut_ptr(), 1, ptr::null_mut(), 0) };

    assert_eq!(result, -1);
}

#[test]
fn a_null_session_is_an_error_everywhere() {
    let _serial = serial();
    let start = symphonia_open_count();
    let null = ptr::null_mut();

    assert_eq!(info(null, 0), -1);
    assert_eq!(unsafe { symphonia_describe(null, 0, [0_u8; 8].as_mut_ptr(), 8) }, -1);

    let (result, message) = read(null, 10);

    assert_eq!(result, -1);
    assert_eq!(message, "the session pointer is null");

    let mut error = [0xAA_u8; 64];
    let result = unsafe { symphonia_read_packet(null, [0_u8; 8].as_mut_ptr(), 8, error.as_mut_ptr(), 64) };

    assert_eq!(result, -1);
    assert_eq!(text(&error), "the session pointer is null");
    assert_eq!(unsafe { symphonia_push(null, [1_u8].as_ptr(), 1) }, -1);
    assert_eq!(finish(null), -1);

    close(null);

    assert_eq!(symphonia_open_count(), start);
}

#[test]
fn an_unknown_field_is_minus_one() {
    let _serial = serial();
    let (handle, _) = open(&wav(48_000, 1, 10), None);

    assert_eq!(info(handle, 6), 0, "field 6 exists: not ended early");
    assert_eq!(info(handle, 7), 1, "field 7 exists: open");
    assert_eq!(info(handle, 8), -1);
    assert_eq!(info(handle, -1), -1);
    assert_eq!(unsafe { symphonia_describe(handle, 2, [0xAA_u8; 8].as_mut_ptr(), 8) }, 0, "field 2 exists: no failure");
    assert_eq!(unsafe { symphonia_describe(handle, 3, [0_u8; 8].as_mut_ptr(), 8) }, -1);

    close(handle);
}

#[test]
fn a_guarded_panic_becomes_an_error_and_fails_the_session() {
    let _serial = serial();
    let (handle, _) = open(&wav(48_000, 2, 4_800), None);
    let (other, _) = open(&wav(48_000, 2, 4_800), None);
    let mut error = [0xAA_u8; ERROR_CAPACITY as usize];
    let result =
        unsafe { guarded_session(handle, error.as_mut_ptr(), ERROR_CAPACITY, |_| panic!("a deliberate panic")) };

    assert_eq!(result, -1);
    assert_eq!(text(&error), "symphonia wrapper panicked: a deliberate panic");
    assert_eq!(info(handle, 5), 1, "the session is marked failed");
    assert_eq!(info(handle, 7), 3);

    let mut failure = [0xAA_u8; ERROR_CAPACITY as usize];

    unsafe { symphonia_describe(handle, 2, failure.as_mut_ptr(), ERROR_CAPACITY) };

    assert_eq!(text(&failure), "symphonia wrapper panicked: a deliberate panic");

    let (frames, message) = read(handle, 10);

    assert_eq!(frames, -1);
    assert_eq!(message, "symphonia wrapper panicked: a deliberate panic", "later calls repeat it");

    let (frames, message) = read(other, 10);

    assert_eq!(frames, 10, "other sessions still work after the panic: {message}");
    assert_eq!(info(other, 5), 0);

    close(handle);
    close(other);
}

#[test]
fn a_panic_in_an_open_becomes_an_error() {
    let mut error = [0xAA_u8; 64];
    let result = unsafe { guarded(error.as_mut_ptr(), 64, || panic!("{}", String::from("formatted"))) };

    assert_eq!(result, -1);
    assert_eq!(text(&error), "symphonia wrapper panicked: formatted");
}

#[test]
fn read_on_opus_and_read_packet_on_pcm_are_errors() {
    let _serial = serial();
    let (handle, _) = open(&wav(48_000, 2, 100), None);
    let mut error = [0xAA_u8; 64];
    let result = unsafe { symphonia_read_packet(handle, [0_u8; 8].as_mut_ptr(), 8, error.as_mut_ptr(), 64) };

    assert_eq!(result, -1);
    assert_eq!(text(&error), "this audio is not Opus; read it with read");

    close(handle);
}

#[test]
fn read_rejects_a_null_or_empty_output() {
    let _serial = serial();
    let (handle, _) = open(&wav(48_000, 2, 100), None);
    let mut error = [0xAA_u8; 64];
    let result = unsafe { symphonia_read(handle, ptr::null_mut(), 10, error.as_mut_ptr(), 64) };

    assert_eq!(result, -1);
    assert_eq!(text(&error), "the output buffer is null");

    let (result, message) = read(handle, 0);

    assert_eq!(result, -1);
    assert_eq!(message, "the output buffer has room for no frames");

    close(handle);
}

#[test]
fn hostile_rates_fail_at_open() {
    let (handle, message) = open(&wav(2_147_483_647, 1, 2_000), None);

    assert!(handle.is_null());
    assert_eq!(message, "the sample rate of 2147483647 Hz is outside 1000 to 384000 Hz");

    let (handle, message) = open(&wav(1, 1, 2_000), None);

    assert!(handle.is_null());
    assert_eq!(message, "the sample rate of 1 Hz is outside 1000 to 384000 Hz");
}

#[test]
fn open_file_streams_a_file_from_disk() {
    let _serial = serial();
    let path = std::env::temp_dir().join(format!("discord-luau-symphonia-{}.wav", std::process::id()));

    std::fs::write(&path, wav(22_050, 1, 11_025)).unwrap();

    let path_text = std::ffi::CString::new(path.to_str().unwrap()).unwrap();
    let mut error = [0xAA_u8; ERROR_CAPACITY as usize];
    let handle = unsafe { symphonia_open_file(path_text.as_ptr(), ptr::null(), error.as_mut_ptr(), ERROR_CAPACITY) };

    std::fs::remove_file(&path).unwrap();

    assert!(!handle.is_null(), "{}", text(&error));
    assert_eq!(info(handle, 7), 1, "open");
    assert_eq!(read_to_end(handle, 48_000), 24_000);
    assert_eq!(info(handle, 7), 2, "ended");

    close(handle);

    let missing = c"/nonexistent/tone.mp3";
    let handle = unsafe { symphonia_open_file(missing.as_ptr(), ptr::null(), error.as_mut_ptr(), ERROR_CAPACITY) };

    assert!(handle.is_null());
    assert!(text(&error).starts_with("/nonexistent/tone.mp3: "));

    let handle = unsafe { symphonia_open_file(ptr::null(), ptr::null(), error.as_mut_ptr(), ERROR_CAPACITY) };

    assert!(handle.is_null());
    assert_eq!(text(&error), "the path is null");
}

#[test]
fn output_is_little_endian_f32_at_any_alignment() {
    let _serial = serial();
    let (handle, _) = open(&wav(48_000, 1, 1_000), None);
    let mut storage = vec![0_u8; 1 + 100 * 8];
    let output = unsafe { storage.as_mut_ptr().add(1) };
    let mut error = [0_u8; 64];
    let frames = unsafe { symphonia_read(handle, output, 100, error.as_mut_ptr(), 64) };

    assert_eq!(frames, 100);

    let sample = f32::from(tone_sample(10, 48_000));
    let expected = sample / 32_768.0;
    let sample_at = |offset: usize| f32::from_le_bytes(storage[1 + offset..1 + offset + 4].try_into().unwrap());

    assert_eq!(sample_at(80), expected, "frame 10, left");
    assert_eq!(sample_at(84), expected, "frame 10, right");

    close(handle);
}

/// Writes `text` into a 16-byte buffer of `0xAA` that claims `capacity` bytes.
fn written(capacity: u32, text: &str) -> (usize, Vec<u8>) {
    let mut buffer = vec![0xAA_u8; 16];
    let length = unsafe { write_text(buffer.as_mut_ptr(), capacity, text) };

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
    let length = unsafe { write_text(ptr::null_mut(), 64, "hello") };

    assert_eq!(length, 0);
}

#[test]
fn an_output_is_none_when_null_and_empty_for_a_length_of_0() {
    let mut buffer = [0xAA_u8; 8];

    assert_eq!(unsafe { output(buffer.as_mut_ptr(), 4) }.map(|slice| slice.len()), Some(4));
    assert_eq!(unsafe { output(buffer.as_mut_ptr(), 0) }.map(|slice| slice.len()), Some(0));
    assert!(unsafe { output(ptr::null_mut(), 4) }.is_none(), "a null buffer is none");
}

#[test]
fn an_input_takes_a_zero_length_as_empty_and_a_null_pointer_as_none() {
    let bytes = [1_u8, 2, 3];

    assert_eq!(unsafe { input(bytes.as_ptr(), 3) }, Some(&[1, 2, 3][..]));
    assert_eq!(unsafe { input(ptr::null(), 0) }, Some(&[][..]));
    assert_eq!(unsafe { input(ptr::null(), 3) }, None);
}

#[test]
fn counts_saturate_to_the_abi_range() {
    assert_eq!(saturate_to_i32(7), 7);
    assert_eq!(saturate_to_i32(u64::MAX), i32::MAX);
    assert_eq!(capped_capacity(10), 10);
    assert_eq!(capped_capacity(u32::MAX), i32::MAX as usize);
}

#[test]
fn every_field_is_found_by_its_own_number() {
    for (index, field) in InfoField::ALL.into_iter().enumerate() {
        assert_eq!(field as usize, index, "{field:?} is at its number in ALL");
        assert_eq!(InfoField::from_number(field as i32), Some(field));
    }

    for (index, field) in DescribeField::ALL.into_iter().enumerate() {
        assert_eq!(field as usize, index, "{field:?} is at its number in ALL");
        assert_eq!(DescribeField::from_number(field as i32), Some(field));
    }

    assert_eq!(InfoField::from_number(-1), None);
    assert_eq!(InfoField::from_number(8), None);
    assert_eq!(DescribeField::from_number(-1), None);
    assert_eq!(DescribeField::from_number(3), None);
}

#[test]
fn the_numbers_are_the_ones_sys_luau_uses() {
    assert_eq!(InfoField::ALL.map(|field| field as i32), [0, 1, 2, 3, 4, 5, 6, 7]);
    assert_eq!(InfoField::State as i32, 7);
    assert_eq!(InfoField::EndedEarly as i32, 6);
    assert_eq!(DescribeField::Failure as i32, 2);
    assert_eq!([State::Probing, State::Open, State::Ended, State::Failed].map(|state| state as i32), [0, 1, 2, 3]);
}

#[test]
fn panic_payloads_become_the_message() {
    let from_str = panic_error(&"broken").to_string();
    let from_string = panic_error(&String::from("also broken")).to_string();
    let from_other = panic_error(&42_u8).to_string();

    assert_eq!(from_str, "symphonia wrapper panicked: broken");
    assert_eq!(from_string, "symphonia wrapper panicked: also broken");
    assert_eq!(from_other, "symphonia wrapper panicked: a panic without a message");
}
