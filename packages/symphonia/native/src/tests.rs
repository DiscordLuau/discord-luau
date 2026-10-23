//! The exports, called as Luau calls them: ids, error buffers, field numbers, codes and the panic guard. Also the
//! helpers and synthetic-file builders that more than one module's tests use.

#![expect(clippy::undocumented_unsafe_blocks, reason = "every ABI call passes buffers the test owns")]
#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_precision_loss,
    reason = "the builders write header fields and samples of known small values"
)]

use super::*;

use std::sync::{Mutex, MutexGuard};
use std::thread;
use std::time::{Duration, Instant};

use crate::guard::lock;

pub const ERROR_CAPACITY: u32 = 256;
/// How long a stream's worker, or a read it is blocked in, may take to return once the stream is done or closed.
pub const EXIT_WAIT: Duration = Duration::from_secs(1);
/// A chunk that starts with this makes the worker's reader panic, with the rest of the chunk as the message.
pub const PANIC: &[u8] = b"\0a test panic: ";
pub const ADPCM_BLOCK_FRAMES: u32 = 2041;
const ADPCM_DATA_OFFSET: usize = 60;
const WAVE_FORMAT_PCM: u16 = 1;
const TONE_FREQUENCY: f64 = 440.0;
/// Half scale.
const TONE_PEAK: f64 = 16_384.0;

/// Serialises the tests that open sessions or start stream workers, since they share one table and one worker count,
/// and count them.
pub fn serial() -> MutexGuard<'static, ()> {
    static LOCK: Mutex<()> = Mutex::new(());

    lock(&LOCK)
}

/// The NUL-terminated text at the start of `buffer`.
pub fn text(buffer: &[u8]) -> String {
    let end = buffer.iter().position(|&byte| byte == 0).expect("a NUL");

    String::from_utf8(buffer[..end].to_vec()).unwrap()
}

/// Checks `condition` every millisecond, and panics past `bound`.
pub fn wait_until(what: &str, bound: Duration, mut condition: impl FnMut() -> bool) {
    let deadline = Instant::now() + bound;

    while !condition() {
        assert!(Instant::now() < deadline, "{what}: not within {bound:?}");
        thread::sleep(Duration::from_millis(1));
    }
}

/// Returns the id, and the error if the open failed.
pub fn open(bytes: &[u8], extension: Option<&CStr>) -> (i32, String) {
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let extension = extension.map_or(std::ptr::null(), CStr::as_ptr);
    let length = u32::try_from(bytes.len()).unwrap();
    let id = unsafe { symphonia_open_memory(bytes.as_ptr(), length, extension, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if id < 0 { text(&error) } else { String::new() };

    (id, message)
}

/// Returns the result, and the error if the read failed.
pub fn read(id: i32, capacity_frames: u32) -> (i32, String) {
    let mut output = vec![0_u8; capacity_frames as usize * BYTES_PER_FRAME];
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let result =
        unsafe { symphonia_read(id, output.as_mut_ptr(), capacity_frames, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if result == -1 { text(&error) } else { String::new() };

    (result, message)
}

/// Panics after `max_frames`, so a session that never ends fails the test instead of growing forever.
fn read_to_end(id: i32, max_frames: i32) -> i32 {
    let mut total = 0;

    loop {
        let (frames, message) = read(id, 4800);

        assert!(frames >= 0, "{message}");

        if frames == 0 {
            return total;
        }

        total += frames;

        assert!(total <= max_frames, "read more than {max_frames} frames without reaching the end");
    }
}

/// A WAV file with a 16-byte `fmt ` chunk and `data` as its samples.
pub fn wav_file(format: u16, bits_per_sample: u16, sample_rate: u32, channel_count: u16, data: &[u8]) -> Vec<u8> {
    let block_align = channel_count * bits_per_sample / 8;
    let data_length = data.len() as u32;
    let mut bytes = Vec::new();

    bytes.extend_from_slice(b"RIFF");
    bytes.extend_from_slice(&(36 + data_length).to_le_bytes());
    bytes.extend_from_slice(b"WAVEfmt ");
    bytes.extend_from_slice(&16_u32.to_le_bytes());
    bytes.extend_from_slice(&format.to_le_bytes());
    bytes.extend_from_slice(&channel_count.to_le_bytes());
    bytes.extend_from_slice(&sample_rate.to_le_bytes());
    bytes.extend_from_slice(&sample_rate.wrapping_mul(u32::from(block_align)).to_le_bytes());
    bytes.extend_from_slice(&block_align.to_le_bytes());
    bytes.extend_from_slice(&bits_per_sample.to_le_bytes());
    bytes.extend_from_slice(b"data");
    bytes.extend_from_slice(&data_length.to_le_bytes());
    bytes.extend_from_slice(data);

    bytes
}

pub fn s16_wav(sample_rate: u32, channel_count: u16, samples: &[i16]) -> Vec<u8> {
    let data: Vec<u8> = samples.iter().flat_map(|sample| sample.to_le_bytes()).collect();

    wav_file(WAVE_FORMAT_PCM, 16, sample_rate, channel_count, &data)
}

pub fn tone_phase(frame: usize, sample_rate: u32) -> f64 {
    frame as f64 * TONE_FREQUENCY * std::f64::consts::TAU / f64::from(sample_rate)
}

pub fn tone_sample(frame: usize, sample_rate: u32) -> i16 {
    (tone_phase(frame, sample_rate).sin() * TONE_PEAK) as i16
}

/// A 16-bit PCM WAV with the test tone on the `active` channels and silence on the rest.
pub fn wav_with(sample_rate: u32, channel_count: u16, frames: usize, active: &[u16]) -> Vec<u8> {
    let mut samples = Vec::with_capacity(frames * usize::from(channel_count));

    for frame in 0..frames {
        let sample = tone_sample(frame, sample_rate);

        for channel in 0..channel_count {
            samples.push(if active.contains(&channel) { sample } else { 0 });
        }
    }

    s16_wav(sample_rate, channel_count, &samples)
}

/// A 16-bit PCM WAV with the test tone on every channel.
pub fn wav(sample_rate: u32, channel_count: u16, frames: usize) -> Vec<u8> {
    let active: Vec<u16> = (0..channel_count).collect();

    wav_with(sample_rate, channel_count, frames, &active)
}

/// A silent mono IMA ADPCM WAV of `blocks` 1024-byte blocks (2041 frames each) whose `fact` chunk says
/// `fact_frames`, as ffmpeg writes it.
pub fn adpcm_wav(sample_rate: u32, fact_frames: u32, blocks: usize) -> Vec<u8> {
    let data_length = blocks as u32 * 1024;
    let mut bytes = Vec::new();

    bytes.extend_from_slice(b"RIFF");
    bytes.extend_from_slice(&(4 + 28 + 12 + 8 + data_length).to_le_bytes());
    bytes.extend_from_slice(b"WAVEfmt ");
    bytes.extend_from_slice(&20_u32.to_le_bytes());
    bytes.extend_from_slice(&0x11_u16.to_le_bytes());
    bytes.extend_from_slice(&1_u16.to_le_bytes());
    bytes.extend_from_slice(&sample_rate.to_le_bytes());
    bytes.extend_from_slice(&(sample_rate * 1024 / 2041).to_le_bytes());
    bytes.extend_from_slice(&1024_u16.to_le_bytes());
    bytes.extend_from_slice(&4_u16.to_le_bytes());
    bytes.extend_from_slice(&2_u16.to_le_bytes());
    bytes.extend_from_slice(&2041_u16.to_le_bytes());
    bytes.extend_from_slice(b"fact");
    bytes.extend_from_slice(&4_u32.to_le_bytes());
    bytes.extend_from_slice(&fact_frames.to_le_bytes());
    bytes.extend_from_slice(b"data");
    bytes.extend_from_slice(&data_length.to_le_bytes());
    bytes.resize(bytes.len() + data_length as usize, 0);

    bytes
}

/// Inserts a `fact` chunk saying `frames` after the 16-byte `fmt ` chunk of a PCM WAV.
pub fn with_fact(mut wav: Vec<u8>, frames: u32) -> Vec<u8> {
    let mut fact = Vec::from(&b"fact"[..]);

    fact.extend_from_slice(&4_u32.to_le_bytes());
    fact.extend_from_slice(&frames.to_le_bytes());
    wav.splice(36..36, fact);

    let riff_length = wav.len() as u32 - 8;

    wav[4..8].copy_from_slice(&riff_length.to_le_bytes());
    wav
}

/// A 368-byte CAF of 100 frames of mono 24-bit big-endian LPCM whose description claims `frames_per_packet` frames in
/// every 3-byte packet.
pub fn caf_lpcm(frames_per_packet: u32) -> Vec<u8> {
    let data_length = 300_u32;
    let mut bytes = Vec::from(&b"caff"[..]);

    bytes.extend_from_slice(&1_u16.to_be_bytes());
    bytes.extend_from_slice(&0_u16.to_be_bytes());
    bytes.extend_from_slice(b"desc");
    bytes.extend_from_slice(&32_i64.to_be_bytes());
    bytes.extend_from_slice(&44_100_f64.to_be_bytes());
    bytes.extend_from_slice(b"lpcm");
    bytes.extend_from_slice(&0_u32.to_be_bytes());
    bytes.extend_from_slice(&3_u32.to_be_bytes());
    bytes.extend_from_slice(&frames_per_packet.to_be_bytes());
    bytes.extend_from_slice(&1_u32.to_be_bytes());
    bytes.extend_from_slice(&24_u32.to_be_bytes());
    bytes.extend_from_slice(b"data");
    bytes.extend_from_slice(&(i64::from(data_length) + 4).to_be_bytes());
    bytes.extend_from_slice(&0_u32.to_be_bytes());
    bytes.resize(bytes.len() + data_length as usize, 0);

    bytes
}

/// A 48 kHz `adpcm_wav` of `blocks` blocks with no padding, where the blocks in `corrupt` have an invalid step index,
/// which the decoder rejects with `DecodeError`.
pub fn corrupted_adpcm_wav(blocks: usize, corrupt: impl Iterator<Item = usize>) -> Vec<u8> {
    let mut bytes = adpcm_wav(48_000, blocks as u32 * ADPCM_BLOCK_FRAMES, blocks);

    for block in corrupt {
        bytes[ADPCM_DATA_OFFSET + block * 1024 + 2] = 0xFF;
    }

    bytes
}

/// The Ogg page checksum: CRC-32 with polynomial 0x04c11db7, no reflection, zero start.
fn ogg_crc(bytes: &[u8]) -> u32 {
    let mut crc = 0_u32;

    for &byte in bytes {
        crc ^= u32::from(byte) << 24;

        for _ in 0..8 {
            crc = if crc & 0x8000_0000 == 0 { crc << 1 } else { (crc << 1) ^ 0x04c1_1db7 };
        }
    }

    crc
}

/// One Ogg page holding whole `packets`. `header_type` is 0x02 for the first page of a stream and 0x04 for its last.
fn ogg_page(header_type: u8, granule: u64, serial: u32, sequence: u32, packets: &[&[u8]]) -> Vec<u8> {
    let mut lacing = Vec::new();

    for packet in packets {
        lacing.extend(std::iter::repeat_n(255_u8, packet.len() / 255));
        lacing.push((packet.len() % 255) as u8);
    }

    assert!(lacing.len() <= 255, "too many segments for one page");

    let mut page = Vec::from(&b"OggS\0"[..]);

    page.push(header_type);
    page.extend_from_slice(&granule.to_le_bytes());
    page.extend_from_slice(&serial.to_le_bytes());
    page.extend_from_slice(&sequence.to_le_bytes());
    page.extend_from_slice(&0_u32.to_le_bytes());
    page.push(lacing.len() as u8);
    page.extend_from_slice(&lacing);

    for packet in packets {
        page.extend_from_slice(packet);
    }

    let crc = ogg_crc(&page);

    page[22..26].copy_from_slice(&crc.to_le_bytes());
    page
}

/// A 20 ms stereo CELT packet followed by `filler` bytes of `1`. It is never decoded.
pub fn opus_packet(filler: usize) -> Vec<u8> {
    let mut packet = vec![0xFC];

    packet.resize(1 + filler, 1);
    packet
}

/// A complete Ogg Opus stream with serial `serial`: an `OpusHead` (family 0, pre-skip 312), `OpusTags`, then
/// `packets`, 200 to a page.
pub fn ogg_opus(serial: u32, channel_count: u8, packets: &[Vec<u8>]) -> Vec<u8> {
    let mut head = Vec::from(&b"OpusHead\x01"[..]);

    head.push(channel_count);
    head.extend_from_slice(&312_u16.to_le_bytes());
    head.extend_from_slice(&48_000_u32.to_le_bytes());
    head.extend_from_slice(&[0, 0, 0]);

    let tags = b"OpusTags\x04\0\0\0test\0\0\0\0";
    let mut bytes = ogg_page(0x02, 0, serial, 0, &[&head]);

    bytes.extend(ogg_page(0x00, 0, serial, 1, &[tags]));

    let pages: Vec<&[Vec<u8>]> = packets.chunks(200).collect();
    let mut granule = 0;

    for (index, page_packets) in pages.iter().enumerate() {
        let header_type = if index + 1 == pages.len() { 0x04 } else { 0x00 };
        let slices: Vec<&[u8]> = page_packets.iter().map(Vec::as_slice).collect();

        granule += 960 * page_packets.iter().filter(|packet| !packet.is_empty()).count() as u64;
        bytes.extend(ogg_page(header_type, granule, serial, index as u32 + 2, &slices));
    }

    bytes
}

#[test]
fn the_abi_version_is_two() {
    assert_eq!(symphonia_abi_version(), 2);
}

#[test]
fn a_session_opens_reads_and_closes() {
    let _serial = serial();
    let start = symphonia_open_count();
    let (id, message) = open(&wav(44_100, 2, 22_050), Some(c"wav"));

    assert!(id > 0, "{message}");
    assert_eq!(symphonia_open_count(), start + 1);
    assert_eq!(symphonia_info(id, 0), 44_100);
    assert_eq!(symphonia_info(id, 1), 2);
    assert_eq!(symphonia_info(id, 2), 0);
    assert_eq!(symphonia_info(id, 3), 500);
    assert_eq!(symphonia_info(id, 4), 0);
    assert_eq!(symphonia_info(id, 5), 0);
    assert_eq!(symphonia_info(id, 7), 1, "open");

    let mut name = [0xAA_u8; 64];
    let written = unsafe { symphonia_describe(id, 1, name.as_mut_ptr(), 64) };

    assert_eq!(written, 4);
    assert_eq!(text(&name), "wave");
    assert_eq!(read_to_end(id, 48_000), 24_000);
    assert_eq!(symphonia_info(id, 7), 2, "ended");
    assert_eq!(read(id, 4800).0, 0, "the end stays the end");
    assert_eq!(symphonia_info(id, 7), 2);

    symphonia_close(id);

    assert_eq!(symphonia_open_count(), start);
}

#[test]
fn ids_are_positive_and_never_reused() {
    let _serial = serial();
    let (first, _) = open(&wav(48_000, 1, 10), None);

    symphonia_close(first);

    let (second, _) = open(&wav(48_000, 1, 10), None);

    assert!(first > 0 && second > first);

    symphonia_close(second);
}

#[test]
fn open_memory_rejects_an_empty_buffer() {
    let mut error = [0xAA_u8; 64];
    let id = unsafe { symphonia_open_memory(std::ptr::null(), 0, std::ptr::null(), error.as_mut_ptr(), 64) };

    assert_eq!(id, -1);
    assert_eq!(text(&error), "the audio is empty");

    let bytes = [1_u8; 4];
    let id = unsafe { symphonia_open_memory(bytes.as_ptr(), 0, std::ptr::null(), error.as_mut_ptr(), 64) };

    assert_eq!(id, -1);
    assert_eq!(text(&error), "the audio is empty");
}

#[test]
fn open_memory_rejects_a_null_pointer_with_a_length() {
    let mut error = [0xAA_u8; 64];
    let id = unsafe { symphonia_open_memory(std::ptr::null(), 10, std::ptr::null(), error.as_mut_ptr(), 64) };

    assert_eq!(id, -1);
    assert_eq!(text(&error), "the audio pointer is null");
}

#[test]
fn open_errors_are_truncated_with_a_nul() {
    let mut error = [0xAA_u8; 8];
    let id = unsafe { symphonia_open_memory(std::ptr::null(), 0, std::ptr::null(), error.as_mut_ptr(), 5) };

    assert_eq!(id, -1);
    assert_eq!(&error[..5], b"the \0");
    assert!(error[5..].iter().all(|&byte| byte == 0xAA), "nothing past the capacity");
}

#[test]
fn a_null_or_zero_capacity_error_buffer_gets_nothing() {
    let id = unsafe { symphonia_open_memory(std::ptr::null(), 0, std::ptr::null(), std::ptr::null_mut(), 64) };

    assert_eq!(id, -1);

    let mut error = [0xAA_u8; 8];
    let id = unsafe { symphonia_open_memory(std::ptr::null(), 0, std::ptr::null(), error.as_mut_ptr(), 0) };

    assert_eq!(id, -1);
    assert!(error.iter().all(|&byte| byte == 0xAA));

    let result = unsafe { symphonia_read(-5, [0_u8; 8].as_mut_ptr(), 1, std::ptr::null_mut(), 0) };

    assert_eq!(result, -1);
}

#[test]
fn an_unknown_id_is_an_error_everywhere() {
    let _serial = serial();
    let start = symphonia_open_count();

    for id in [0, -1, 999_999_999] {
        assert_eq!(symphonia_info(id, 0), -1);
        assert_eq!(unsafe { symphonia_describe(id, 0, [0_u8; 8].as_mut_ptr(), 8) }, -1);

        let (result, message) = read(id, 10);

        assert_eq!(result, -1);
        assert_eq!(message, format!("no decoder has the id {id}"));

        let mut error = [0xAA_u8; 64];
        let result = unsafe { symphonia_read_packet(id, [0_u8; 8].as_mut_ptr(), 8, error.as_mut_ptr(), 64) };

        assert_eq!(result, -1);
        assert_eq!(text(&error), format!("no decoder has the id {id}"));
        assert_eq!(unsafe { symphonia_push(id, [1_u8].as_ptr(), 1) }, -1);
        assert_eq!(symphonia_finish(id), -1);

        symphonia_close(id);
    }

    assert_eq!(symphonia_open_count(), start);
}

#[test]
fn an_unknown_field_is_minus_one() {
    let _serial = serial();
    let (id, _) = open(&wav(48_000, 1, 10), None);

    assert_eq!(symphonia_info(id, 6), 0, "field 6 exists: not ended early");
    assert_eq!(symphonia_info(id, 7), 1, "field 7 exists: open");
    assert_eq!(symphonia_info(id, 8), -1);
    assert_eq!(symphonia_info(id, -1), -1);
    assert_eq!(unsafe { symphonia_describe(id, 2, [0xAA_u8; 8].as_mut_ptr(), 8) }, 0, "field 2 exists: no failure");
    assert_eq!(unsafe { symphonia_describe(id, 3, [0_u8; 8].as_mut_ptr(), 8) }, -1);

    symphonia_close(id);
}

#[test]
fn a_guarded_panic_becomes_an_error_and_fails_the_session() {
    let _serial = serial();
    let (id, _) = open(&wav(48_000, 2, 4_800), None);
    let (other, _) = open(&wav(48_000, 2, 4_800), None);
    let mut error = [0xAA_u8; ERROR_CAPACITY as usize];
    let buffer = unsafe { TextBuffer::new(error.as_mut_ptr(), ERROR_CAPACITY) };
    let result: i32 = guarded(buffer, -1, || with_session(id, |_| panic!("a deliberate panic")));

    assert_eq!(result, -1);
    assert_eq!(text(&error), "symphonia wrapper panicked: a deliberate panic");
    assert_eq!(symphonia_info(id, 5), 1, "the session is marked failed");
    assert_eq!(symphonia_info(id, 7), 3);

    let mut failure = [0xAA_u8; ERROR_CAPACITY as usize];

    unsafe { symphonia_describe(id, 2, failure.as_mut_ptr(), ERROR_CAPACITY) };

    assert_eq!(text(&failure), "symphonia wrapper panicked: a deliberate panic");

    let (frames, message) = read(id, 10);

    assert_eq!(frames, -1);
    assert_eq!(message, "symphonia wrapper panicked: a deliberate panic", "later calls repeat it");

    let (frames, message) = read(other, 10);

    assert_eq!(frames, 10, "other sessions still work after the lock was poisoned: {message}");
    assert_eq!(symphonia_info(other, 5), 0);

    symphonia_close(id);
    symphonia_close(other);
}

#[test]
fn a_panic_in_an_open_becomes_an_error() {
    let mut error = [0xAA_u8; 64];
    let buffer = unsafe { TextBuffer::new(error.as_mut_ptr(), 64) };
    let result: i32 = guarded(buffer, -1, || panic!("{}", String::from("formatted")));

    assert_eq!(result, -1);
    assert_eq!(text(&error), "symphonia wrapper panicked: formatted");
}

#[test]
fn read_on_opus_and_read_packet_on_pcm_are_errors() {
    let _serial = serial();
    let (id, _) = open(&wav(48_000, 2, 100), None);
    let mut error = [0xAA_u8; 64];
    let result = unsafe { symphonia_read_packet(id, [0_u8; 8].as_mut_ptr(), 8, error.as_mut_ptr(), 64) };

    assert_eq!(result, -1);
    assert_eq!(text(&error), "this audio is not Opus; read it with read");

    symphonia_close(id);
}

#[test]
fn read_rejects_a_null_or_empty_output() {
    let _serial = serial();
    let (id, _) = open(&wav(48_000, 2, 100), None);
    let mut error = [0xAA_u8; 64];
    let result = unsafe { symphonia_read(id, std::ptr::null_mut(), 10, error.as_mut_ptr(), 64) };

    assert_eq!(result, -1);
    assert_eq!(text(&error), "the output buffer is null");

    let (result, message) = read(id, 0);

    assert_eq!(result, -1);
    assert_eq!(message, "the output buffer has room for no frames");

    symphonia_close(id);
}

#[test]
fn hostile_rates_fail_at_open() {
    let (id, message) = open(&wav(2_147_483_647, 1, 2_000), None);

    assert_eq!(id, -1);
    assert_eq!(message, "the sample rate of 2147483647 Hz is outside 1000 to 384000 Hz");

    let (id, message) = open(&wav(1, 1, 2_000), None);

    assert_eq!(id, -1);
    assert_eq!(message, "the sample rate of 1 Hz is outside 1000 to 384000 Hz");
}

#[test]
fn open_file_streams_a_file_from_disk() {
    let _serial = serial();
    let path = std::env::temp_dir().join(format!("discord-luau-symphonia-{}.wav", std::process::id()));

    std::fs::write(&path, wav(22_050, 1, 11_025)).unwrap();

    let path_text = std::ffi::CString::new(path.to_str().unwrap()).unwrap();
    let mut error = [0xAA_u8; ERROR_CAPACITY as usize];
    let id = unsafe { symphonia_open_file(path_text.as_ptr(), std::ptr::null(), error.as_mut_ptr(), ERROR_CAPACITY) };

    std::fs::remove_file(&path).unwrap();

    assert!(id > 0, "{}", text(&error));
    assert_eq!(symphonia_info(id, 7), 1, "open");
    assert_eq!(read_to_end(id, 48_000), 24_000);
    assert_eq!(symphonia_info(id, 7), 2, "ended");

    symphonia_close(id);

    let missing = c"/nonexistent/tone.mp3";
    let id = unsafe { symphonia_open_file(missing.as_ptr(), std::ptr::null(), error.as_mut_ptr(), ERROR_CAPACITY) };

    assert_eq!(id, -1);
    assert!(text(&error).starts_with("/nonexistent/tone.mp3: "));

    let id = unsafe { symphonia_open_file(std::ptr::null(), std::ptr::null(), error.as_mut_ptr(), ERROR_CAPACITY) };

    assert_eq!(id, -1);
    assert_eq!(text(&error), "the path is null");
}

#[test]
fn output_is_little_endian_f32_at_any_alignment() {
    let _serial = serial();
    let (id, _) = open(&wav(48_000, 1, 1_000), None);
    let mut storage = vec![0_u8; 1 + 100 * 8];
    let output = unsafe { storage.as_mut_ptr().add(1) };
    let mut error = [0_u8; 64];
    let frames = unsafe { symphonia_read(id, output, 100, error.as_mut_ptr(), 64) };

    assert_eq!(frames, 100);

    let sample = f32::from(tone_sample(10, 48_000));
    let expected = sample / 32_768.0;
    let at = |offset: usize| f32::from_le_bytes(storage[1 + offset..1 + offset + 4].try_into().unwrap());

    assert_eq!(at(80), expected, "frame 10, left");
    assert_eq!(at(84), expected, "frame 10, right");

    symphonia_close(id);
}
