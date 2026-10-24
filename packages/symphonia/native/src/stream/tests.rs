//! Stream sessions through the ABI and directly: codes, states, closing, failures, blocks, and chunked runs that must
//! decode like a source that never runs dry.

#![expect(clippy::undocumented_unsafe_blocks, reason = "every ABI call passes buffers the test owns")]
#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    reason = "the frame and chunk counts here are small"
)]

use super::*;

use std::io::Cursor;
use std::path::{Path, PathBuf};
use std::sync::atomic::AtomicUsize;
use std::sync::mpsc::RecvTimeoutError;
use std::time::{Duration, Instant};

use crate::tests::{
    ERROR_CAPACITY, EXIT_WAIT, PANIC, corrupted_adpcm_wav, ogg_opus, open, opus_packet, read, serial, text,
    tone_sample, wait_until, wav,
};
use crate::{
    FULL, NOT_READY, session_table, symphonia_close, symphonia_describe, symphonia_finish, symphonia_info,
    symphonia_open_count, symphonia_open_stream, symphonia_push, symphonia_read_packet, symphonia_worker_count,
};

/// Every worker's queued blocks, counted by the test hook in `decode`; only tests holding `serial` start workers.
static BLOCKS_SENT: AtomicUsize = AtomicUsize::new(0);

/// The longest a test waits for the worker at any one point.
const WAIT: Duration = Duration::from_secs(30);
/// How long a call that must not block may take, generously.
const AT_ONCE: Duration = Duration::from_millis(500);
const FAILING_RUNS: usize = 1_000;
/// The chunked runs per file.
const SEEDS: u64 = 10;
const MAX_CHUNK: usize = 65_536;
const READ_FRAMES: usize = 4_800;
const MAX_PCM_BYTES: usize = 2 * 60 * 48_000 * BYTES_PER_FRAME;
const MAX_PACKETS: usize = 100_000;
/// Names the folder of the streaming spike's generated files, which the chunked runs add when it is set.
const SPIKE_FILES: &str = "DISCORD_LUAU_STREAM_FILES";
const PUBLISHED_FIELDS: [InfoField; 6] = [
    InfoField::SampleRate,
    InfoField::Channels,
    InfoField::IsOpus,
    InfoField::DurationMilliseconds,
    InfoField::SkippedPackets,
    InfoField::EndedEarly,
];

pub fn count_block() {
    BLOCKS_SENT.fetch_add(1, Ordering::SeqCst);
}

fn wait_for_workers(baseline: i32) {
    wait_until("the workers exit", EXIT_WAIT, || symphonia_worker_count() == baseline);
}

fn open_stream() -> i32 {
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let id = unsafe { symphonia_open_stream(error.as_mut_ptr(), ERROR_CAPACITY) };

    assert!(id > 0, "{}", text(&error));

    id
}

fn push(id: i32, bytes: &[u8]) -> i32 {
    unsafe { symphonia_push(id, bytes.as_ptr(), bytes.len() as u32) }
}

/// Checks on every call that field 5 is 1 exactly when the state is 3.
fn state(id: i32) -> i32 {
    let state = symphonia_info(id, InfoField::State as i32);

    assert_eq!(
        symphonia_info(id, InfoField::IsFailed as i32),
        i32::from(state == State::Failed as i32),
        "field 5 is tied to state 3, and the state is {state}"
    );

    state
}

fn describe(id: i32, field: i32) -> String {
    let mut output = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let written = unsafe { symphonia_describe(id, field, output.as_mut_ptr(), ERROR_CAPACITY) };

    assert!(written >= 0, "field {field} of {id}");

    text(&output)
}

fn read_packet(id: i32) -> (i32, String) {
    let mut output = vec![0_u8; 4_000];
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let result = unsafe { symphonia_read_packet(id, output.as_mut_ptr(), 4_000, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if result == -1 { text(&error) } else { String::new() };

    (result, message)
}

fn with_stream<T>(id: i32, check: impl FnOnce(&StreamSession) -> T) -> T {
    session_table::with_stream(id, |stream| check(stream)).unwrap_or_else(|| panic!("{id} is not a stream session"))
}

/// Closes on another thread, so a close that blocks fails the test instead of hanging it.
fn close_at_once(id: i32, point: &str, baseline: i32) {
    let (closed, returned) = mpsc::channel();

    thread::spawn(move || {
        symphonia_close(id);
        closed.send(()).ok();
    });

    assert!(returned.recv_timeout(AT_ONCE).is_ok(), "{point}: close did not return within {AT_ONCE:?}");
    wait_for_workers(baseline);
}

#[test]
fn a_stream_opens_reads_and_ends_through_the_abi() {
    let _serial = serial();
    let sessions_before = symphonia_open_count();
    let workers_before = symphonia_worker_count();
    let id = open_stream();

    assert_eq!(symphonia_open_count(), sessions_before + 1);
    assert_eq!(symphonia_worker_count(), workers_before + 1);
    assert_eq!(state(id), 0, "probing");

    for field in 0..=3 {
        assert_eq!(symphonia_info(id, field), -1, "field {field} while probing");
    }

    for field in 0..=2 {
        assert_eq!(describe(id, field), "", "describe {field} while probing");
    }

    assert_eq!(read(id, 4800), (NOT_READY, String::new()));
    assert_eq!(read_packet(id), (NOT_READY, String::new()));

    assert_eq!(push(id, &wav(44_100, 2, 22_050)), 0);
    assert_eq!(symphonia_finish(id), 0);
    assert_eq!(symphonia_finish(id), 0, "a second finish");
    wait_until("the stream opens", WAIT, || state(id) != 0);

    assert_eq!(symphonia_info(id, 0), 44_100);
    assert_eq!(symphonia_info(id, 1), 2);
    assert_eq!(symphonia_info(id, 2), 0);
    assert_eq!(symphonia_info(id, 3), 500);
    assert_eq!(describe(id, 0), "pcm_s16le");
    assert_eq!(describe(id, 1), "wave");
    assert_eq!(read_packet(id), (-1, Error::NotOpus.to_string()), "a PCM stream is read with read");

    let mut total = 0;

    wait_until("the stream reads to its end", WAIT, || {
        let (frames, message) = read(id, 4800);

        assert!(frames >= 0 || frames == NOT_READY, "{message}");
        total += frames.max(0);
        assert!(total <= 48_000, "more frames than the file holds");

        frames == 0
    });

    assert_eq!(total, 24_000);
    assert_eq!(state(id), 2);
    assert_eq!(read(id, 4800).0, 0, "the end stays the end");

    symphonia_close(id);

    assert_eq!(symphonia_open_count(), sessions_before);
    wait_for_workers(workers_before);
}

#[test]
fn push_and_finish_return_their_codes() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let (file, _) = open(&wav(48_000, 2, 100), None);

    assert_eq!(push(file, &[1]), -1, "a memory session takes no bytes");
    assert_eq!(symphonia_finish(file), -1, "nor a finish");

    symphonia_close(file);

    let id = open_stream();

    assert_eq!(unsafe { symphonia_push(id, std::ptr::null(), 4) }, -1, "a null pointer with a length");
    assert_eq!(unsafe { symphonia_push(id, std::ptr::null(), 0) }, 0, "an empty push queues nothing");
    assert_eq!(symphonia_finish(id), 0);
    assert_eq!(push(id, &[1]), -1, "after finish");

    symphonia_close(id);

    assert_eq!(push(id, &[1]), -1, "a closed id");
    assert_eq!(symphonia_finish(id), -1, "a closed id");

    // A WAV that states its length ends there, with no finish, and takes no more.
    let id = open_stream();

    assert_eq!(push(id, &wav(48_000, 2, 1_000)), 0);
    wait_until("decoding ends", WAIT, || state(id) == 2);

    assert_eq!(push(id, &[0; 16]), -1, "an ended stream");
    assert_eq!(symphonia_finish(id), 0, "finish still answers");

    symphonia_close(id);

    // Bytes that are not audio fail the stream with Symphonia's message.
    let id = open_stream();

    assert_eq!(push(id, &b"not audio ".repeat(400)), 0);
    assert_eq!(symphonia_finish(id), 0);
    wait_until("the stream fails", WAIT, || state(id) == 3);

    let failure = describe(id, 2);

    assert!(failure.starts_with("not a supported audio file: "), "{failure}");
    assert_eq!(read(id, 10), (-1, failure.clone()), "reads fail with it");
    assert_eq!(read_packet(id), (-1, failure));

    for field in 0..=3 {
        assert_eq!(symphonia_info(id, field), -1, "field {field}: never opened");
    }

    symphonia_close(id);
    wait_for_workers(workers_before);
}

#[test]
fn push_is_full_at_64_chunks_and_never_blocks() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let (results, received) = mpsc::channel();

    // On its own thread, so a push that blocks fails the test instead of hanging it.
    thread::spawn(move || {
        let id = open_stream();

        // The worker holds this one chunk of 10 s until it has decoded all of it, which a full output stops at
        // 6.4 s, so every later chunk stays queued.
        assert_eq!(push(id, &wav(48_000, 2, 480_000)), 0);
        wait_until("the stream opens", WAIT, || state(id) == State::Open as i32);

        let started = Instant::now();
        let codes: Vec<i32> = (0..=INPUT_CHUNKS).map(|_| push(id, &[0; 16])).collect();

        results.send((codes, started.elapsed())).ok();
        symphonia_close(id);
    });

    let (codes, took) = received.recv_timeout(WAIT).expect("the pushes returned within the wait");

    assert_eq!(codes[..INPUT_CHUNKS], [0; INPUT_CHUNKS]);
    assert_eq!(codes[INPUT_CHUNKS], FULL);
    assert!(took < AT_ONCE, "65 pushes took {took:?}");
    wait_for_workers(workers_before);
}

#[test]
fn close_returns_at_once_wherever_the_worker_waits() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();

    // Probing: nothing pushed yet.
    let id = open_stream();

    assert_eq!(state(id), 0);
    close_at_once(id, "probing", workers_before);

    // Waiting for input mid-stream: half a WAV, read until no more is coming.
    let id = open_stream();
    let bytes = wav(48_000, 2, 48_000);

    assert_eq!(push(id, &bytes[..bytes.len() / 2]), 0);
    wait_until("the worker waits for input", WAIT, || {
        read(id, 4800).0 == NOT_READY && {
            thread::sleep(Duration::from_millis(20));
            read(id, 4800).0 == NOT_READY
        }
    });

    assert_eq!(state(id), 1);
    close_at_once(id, "waiting for input", workers_before);

    // Blocked on a full output: 10 s of WAV, unread.
    let id = open_stream();
    let sent_before = BLOCKS_SENT.load(Ordering::SeqCst);

    assert_eq!(push(id, &wav(48_000, 2, 480_000)), 0);
    wait_until("the output fills", WAIT, || BLOCKS_SENT.load(Ordering::SeqCst) - sent_before == OUTPUT_BLOCKS);
    close_at_once(id, "blocked on a full output", workers_before);
}

#[test]
fn panics_before_and_after_the_open_fail_the_stream_with_their_messages() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();

    // Before the open: the panic comes inside the probe.
    let id = open_stream();

    assert_eq!(push(id, &[PANIC, b"before the open"].concat()), 0);
    wait_until("the stream fails", WAIT, || state(id) == 3);

    let message = "symphonia wrapper panicked: before the open";

    assert_eq!(describe(id, 2), message);
    assert_eq!(describe(id, 0), "");

    for field in 0..=3 {
        assert_eq!(symphonia_info(id, field), -1, "field {field}: never opened");
    }

    assert_eq!(push(id, &[0]), -1);
    assert_eq!(read(id, 10), (-1, message.to_string()));

    symphonia_close(id);

    // After the open: half a WAV opens it, then the panic comes while it decodes.
    let id = open_stream();
    let bytes = wav(48_000, 2, 48_000);

    assert_eq!(push(id, &bytes[..bytes.len() / 2]), 0);
    wait_until("the stream opens", WAIT, || state(id) == 1);
    assert_eq!(push(id, &[PANIC, b"after the open"].concat()), 0);
    wait_until("the stream fails", WAIT, || state(id) == 3);

    let message = "symphonia wrapper panicked: after the open";

    assert_eq!(describe(id, 2), message);
    assert_eq!(symphonia_info(id, 0), 48_000, "it had opened");
    assert_eq!(describe(id, 1), "wave");

    // The blocks decoded before the panic come first: the half held 20 whole packets of 1152 frames, which filled
    // four blocks. Then the failure.
    let mut frames = 0;

    loop {
        match read(id, 4800) {
            (-1, failure) => {
                assert_eq!(failure, message);
                break;
            }
            (count, _) => {
                assert!(count > 0, "a read of {count} before the failure");
                frames += count;
                assert!(frames <= 48_000, "more frames than the file holds");
            }
        }
    }

    assert_eq!(frames, 4 * BLOCK_FRAMES as i32, "the decoded blocks drain first");

    symphonia_close(id);
    wait_for_workers(workers_before);
}

fn read_until_ready(id: i32) -> (i32, String) {
    let deadline = Instant::now() + WAIT;

    loop {
        let read = read(id, 4800);

        if read.0 != NOT_READY {
            return read;
        }

        assert!(Instant::now() < deadline, "nothing was ready within {WAIT:?}");
        thread::yield_now();
    }
}

#[test]
fn a_failure_before_the_open_is_stored_before_the_output_closes() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let junk = b"not audio ".repeat(400);

    for run in 0..FAILING_RUNS {
        let id = open_stream();
        let deadline = Instant::now() + WAIT;

        push(id, &junk);
        symphonia_finish(id);

        // While this holds the status lock the worker cannot store its failure, so an output seen closed under the
        // lock must already have the failure stored.
        while !with_stream(id, |stream| {
            let status = lock(&stream.status);
            let closed = matches!(stream.output.try_recv(), Err(TryRecvError::Disconnected));

            assert!(
                !closed || status.failure().is_some(),
                "run {run}: the output closed before the failure was stored"
            );

            closed
        }) {
            assert!(Instant::now() < deadline, "run {run}: the worker never ended");
            std::thread::yield_now();
        }

        let (result, message) = read_until_ready(id);

        assert_eq!(result, -1, "run {run}: not audio read as {result}");
        assert!(message.starts_with("not a supported audio file"), "{message}");
        assert_eq!(state(id), 3);

        symphonia_close(id);
    }

    wait_for_workers(workers_before);
}

#[test]
fn a_refused_push_finds_the_failure() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let panic = [PANIC, b"in a run"].concat();

    for run in 0..FAILING_RUNS {
        let id = open_stream();
        let deadline = Instant::now() + WAIT;

        push(id, &panic);

        while push(id, &[0]) != -1 {
            assert!(Instant::now() < deadline, "run {run}: no push was refused");
            thread::yield_now();
        }

        assert_eq!(state(id), 3, "run {run}: a refused push");
        assert_eq!(read_until_ready(id), (-1, "symphonia wrapper panicked: in a run".to_string()), "run {run}");

        symphonia_close(id);
    }

    wait_for_workers(workers_before);
}

#[test]
fn a_failure_after_the_open_drains_its_packets_and_is_never_read_as_the_end() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let mut chained = ogg_opus(7, 2, &[opus_packet(10), opus_packet(20)]);

    chained.extend(ogg_opus(8, 1, &[opus_packet(30)]));

    for run in 0..FAILING_RUNS {
        let id = open_stream();
        let deadline = Instant::now() + WAIT;
        let mut packets = 0;

        push(id, &chained);
        symphonia_finish(id);

        // Even runs read only once the stream has failed, so both packets wait behind the failure; odd runs read
        // while the worker decodes.
        if run % 2 == 0 {
            wait_until("the stream fails", WAIT, || state(id) == 3);
        }

        loop {
            match read_packet(id) {
                (-1, message) => {
                    assert_eq!(message, Error::StreamChanged.to_string(), "run {run}");
                    assert_eq!(packets, 2, "run {run}: the first stream's packets come first");
                    break;
                }
                (0, _) => panic!("run {run}: the failure read as the end"),
                (NOT_READY, _) => {
                    assert!(Instant::now() < deadline, "run {run}: no failure");
                    thread::yield_now();
                }
                _ => packets += 1,
            }
        }

        symphonia_close(id);
    }

    wait_for_workers(workers_before);
}

#[test]
fn a_failure_reports_the_skipped_packets_it_ended_on() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let mut session = StreamSession::open().unwrap();

    // 10,001 undecodable blocks in a row: one more than a read passes over.
    assert_eq!(session.push(corrupted_adpcm_wav(10_002, 0..10_001)), PushOutcome::Queued);
    session.finish();
    wait_until("the stream fails", WAIT, || session.state() == State::Failed);

    assert_eq!(
        session.failure().map(|failure| failure.to_string()).as_deref(),
        Some("the audio has more than 10000 undecodable packets in a row")
    );
    assert_eq!(session.info(InfoField::SkippedPackets), 10_001);

    drop(session);
    wait_for_workers(workers_before);
}

/// The FLAC frame and header checksum: a CRC of `width` bits with `polynomial`, starting at 0.
fn flac_crc(bytes: &[u8], width: u32, polynomial: u32) -> u32 {
    let top = 1 << (width - 1);
    let mask = (1 << width) - 1;

    bytes.iter().fold(0, |crc, &byte| {
        (0..8).fold(crc ^ (u32::from(byte) << (width - 8)), |crc, _| {
            (if crc & top == 0 { crc << 1 } else { (crc << 1) ^ polynomial }) & mask
        })
    })
}

/// A 48 kHz stereo 16-bit FLAC of one frame of `frames` frames of the test tone, stored verbatim.
fn one_block_flac(frames: u16) -> Vec<u8> {
    // A verbatim subframe: its header, then every sample.
    let subframe: Vec<u8> = std::iter::once(0x02)
        .chain((0..frames).flat_map(|frame| tone_sample(usize::from(frame), 48_000).to_be_bytes()))
        .collect();
    // STREAMINFO: 20 bits of rate, 3 of channels less one, 5 of bits per sample less one, and 36 of total frames.
    let format = (48_000_u64 << 44) | (1 << 41) | (15 << 36) | u64::from(frames);
    let mut bytes = b"fLaC\x80\0\0\x22".to_vec();

    bytes.extend_from_slice(&frames.to_be_bytes());
    bytes.extend_from_slice(&frames.to_be_bytes());
    bytes.extend_from_slice(&[0; 6]);
    bytes.extend_from_slice(&format.to_be_bytes());
    bytes.extend_from_slice(&[0; 16]);

    // The frame header: a fixed block size given at its end, 48 kHz, left and right, 16 bits, frame 0, then the block
    // size less one, then its CRC-8.
    let frame_start = bytes.len();

    bytes.extend_from_slice(&[0xFF, 0xF8, 0x7A, 0x18, 0x00]);
    bytes.extend_from_slice(&(frames - 1).to_be_bytes());
    bytes.push(flac_crc(&bytes[frame_start..], 8, 0x07) as u8);
    bytes.extend_from_slice(&subframe);
    bytes.extend_from_slice(&subframe);

    let frame_crc = flac_crc(&bytes[frame_start..], 16, 0x8005) as u16;

    bytes.extend_from_slice(&frame_crc.to_be_bytes());
    bytes
}

#[test]
fn a_65535_frame_flac_block_reaches_the_output_in_4800_frame_pieces() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let bytes = one_block_flac(u16::MAX);
    let mut whole = Session::open_memory(bytes.clone(), None).unwrap();
    let expected = whole.read(usize::from(u16::MAX) + 1).unwrap().to_vec();
    let mut session = StreamSession::open().unwrap();
    let mut pieces = Vec::new();
    let mut decoded = Vec::new();

    assert_eq!(expected.len(), usize::from(u16::MAX) * BYTES_PER_FRAME);
    assert_eq!(session.push(bytes), PushOutcome::Queued);
    session.finish();

    loop {
        match session.output.recv_timeout(WAIT) {
            Ok(block) => {
                pieces.push(block.len() / BYTES_PER_FRAME);
                decoded.extend(block);
            }
            Err(RecvTimeoutError::Disconnected) => break,
            Err(RecvTimeoutError::Timeout) => panic!("no block within {WAIT:?}"),
        }

        assert!(pieces.len() <= 100, "{} pieces", pieces.len());
    }

    assert_eq!(session.state(), State::Ended);
    assert!(decoded == expected, "the pieces join into the block");
    assert!(pieces.iter().all(|&frames| frames <= BLOCK_FRAMES), "pieces of {pieces:?} frames");
    assert_eq!(pieces[..13], [BLOCK_FRAMES; 13]);
    assert_eq!(pieces[13..], [3_135]);

    drop(session);
    wait_for_workers(workers_before);
}

/// Chunk sizes from 1 byte to 64 KB covering `total`, log-uniform so small chunks are common. The streaming spike's
/// generator.
fn chunk_sizes(seed: u64, total: usize) -> Vec<usize> {
    let mut state = seed.wrapping_mul(0x9e37_79b9_7f4a_7c15) | 1;
    let mut next = move || {
        state ^= state << 13;
        state ^= state >> 7;
        state ^= state << 17;
        state
    };
    let mut sizes = Vec::new();
    let mut covered = 0;

    while covered < total {
        let exponent = next() % 17;
        let low = 1_usize << exponent;
        let size = (low + (next() as usize % low)).clamp(1, MAX_CHUNK);
        let size = size.min(total - covered);

        sizes.push(size);
        covered += size;
    }

    sizes
}

/// What a session gave.
#[derive(Default)]
struct Decoded {
    /// The published info fields and the codec and container names, once open.
    opened: Option<(Vec<i32>, Vec<String>)>,
    pcm: Vec<u8>,
    packets: Vec<Box<[u8]>>,
    failure: Option<Error>,
}

impl Decoded {
    fn check_bounds(&self) {
        assert!(self.pcm.len() <= MAX_PCM_BYTES, "more than 2 minutes");
        assert!(self.packets.len() <= MAX_PACKETS, "too many packets");
    }

    fn difference(&self, actual: &Self) -> Option<String> {
        let frame = self
            .pcm
            .iter()
            .zip(&actual.pcm)
            .position(|(left, right)| left != right)
            .map(|index| index / BYTES_PER_FRAME);
        let packet = self.packets.iter().zip(&actual.packets).position(|(left, right)| left != right);

        if self.failure != actual.failure {
            Some(format!("failure {:?}, not {:?}", actual.failure, self.failure))
        } else if self.opened != actual.opened {
            Some(format!("opened {:?}, not {:?}", actual.opened, self.opened))
        } else if let Some(frame) = frame {
            Some(format!("frame {frame} differs"))
        } else if self.pcm.len() != actual.pcm.len() {
            Some(format!("{} bytes, not {}", actual.pcm.len(), self.pcm.len()))
        } else if let Some(packet) = packet {
            Some(format!("packet {packet} differs"))
        } else if self.packets.len() != actual.packets.len() {
            Some(format!("{} packets, not {}", actual.packets.len(), self.packets.len()))
        } else {
            None
        }
    }
}

/// What a source holding the whole file, unseekable and of unknown length, gives: what every chunked run must equal.
fn reference(bytes: &[u8]) -> Decoded {
    let source = ReadOnlySource::new(Cursor::new(bytes.to_vec()));
    let mut session = match Session::open(Box::new(source), None, None) {
        Ok(session) => session,
        Err(failure) => return Decoded { failure: Some(failure), ..Decoded::default() },
    };
    let is_opus = session.is_opus();
    let mut decoded = Decoded::default();

    loop {
        let read = if is_opus {
            session.read_packet(usize::MAX).map(|packet| {
                let more = packet.is_some();

                decoded.packets.extend(packet);
                more
            })
        } else {
            session.read(READ_FRAMES).map(|bytes| {
                decoded.pcm.extend_from_slice(bytes);
                !bytes.is_empty()
            })
        };

        decoded.check_bounds();

        match read {
            Ok(true) => {}
            Ok(false) => break,
            Err(failure) => {
                decoded.failure = Some(failure);
                break;
            }
        }
    }

    decoded.opened = Some((
        PUBLISHED_FIELDS.map(|field| session.info(field)).to_vec(),
        [DescribeField::Codec, DescribeField::Container].map(|field| session.describe(field)).to_vec(),
    ));
    decoded
}

/// Reads once from `session` into `decoded`: `Ready(true)` when it gave frames or a packet, `Ready(false)` at the end
/// or a failure, `Pending` when nothing was ready.
fn read_once(session: &mut StreamSession, decoded: &mut Decoded) -> Poll<bool> {
    let read = match session.info(InfoField::IsOpus) {
        1 => session.read_packet(usize::MAX).map(|read| {
            read.map(|packet| {
                let more = packet.is_some();

                decoded.packets.extend(packet);
                more
            })
        }),
        0 => session.read(READ_FRAMES).map(|read| {
            read.map(|bytes| {
                decoded.pcm.extend_from_slice(bytes);
                !bytes.is_empty()
            })
        }),
        _ => session.failure().map_or(Ok(Poll::Pending), Err),
    };

    decoded.check_bounds();

    read.unwrap_or_else(|failure| {
        decoded.failure = Some(failure);
        Poll::Ready(false)
    })
}

fn take_ready(session: &mut StreamSession, decoded: &mut Decoded) {
    while read_once(session, decoded) == Poll::Ready(true) {}
}

/// Pushes `bytes` into a new stream in chunks sized by `seed`, retrying a full input and reading what is ready along
/// the way; then finishes and reads to the end, waiting at most `WAIT` for each output.
fn decode_pushed(bytes: &[u8], seed: u64) -> Decoded {
    let mut session = StreamSession::open().unwrap();
    let mut decoded = Decoded::default();
    let mut offset = 0;

    'pushing: for size in chunk_sizes(seed, bytes.len()) {
        let deadline = Instant::now() + WAIT;

        loop {
            match session.push(bytes[offset..offset + size].to_vec()) {
                PushOutcome::Queued => break,
                PushOutcome::Full => {
                    take_ready(&mut session, &mut decoded);
                    assert!(Instant::now() < deadline, "the input stayed full");
                    thread::yield_now();
                }
                PushOutcome::Refused => break 'pushing,
            }
        }

        offset += size;
        take_ready(&mut session, &mut decoded);
    }

    session.finish();

    let mut deadline = Instant::now() + WAIT;

    loop {
        match read_once(&mut session, &mut decoded) {
            Poll::Ready(true) => deadline = Instant::now() + WAIT,
            Poll::Ready(false) => break,
            Poll::Pending => {
                assert!(Instant::now() < deadline, "no output for {WAIT:?}");
                thread::sleep(Duration::from_micros(200));
            }
        }
    }

    if session.info(InfoField::SampleRate) != -1 {
        decoded.opened = Some((
            PUBLISHED_FIELDS.map(|field| session.info(field)).to_vec(),
            [DescribeField::Codec, DescribeField::Container].map(|field| session.describe(field)).to_vec(),
        ));
    }

    decoded
}

/// The files of the chunked runs: the package's fixtures, and the streaming spike's generated files when
/// `DISCORD_LUAU_STREAM_FILES` names their folder.
fn stream_files() -> Vec<(String, Vec<u8>)> {
    let mut folders = vec![Path::new(env!("CARGO_MANIFEST_DIR")).join("../tests/fixtures")];

    match std::env::var_os(SPIKE_FILES) {
        Some(folder) => folders.push(PathBuf::from(folder)),
        None => println!("{SPIKE_FILES} is not set, so only the package's fixtures run"),
    }

    let mut files = Vec::new();

    for folder in folders {
        let mut paths: Vec<PathBuf> = std::fs::read_dir(&folder)
            .unwrap_or_else(|failure| panic!("{}: {failure}", folder.display()))
            .map(|entry| entry.unwrap().path())
            .filter(|path| path.extension().is_some_and(|extension| extension != "sh" && extension != "png"))
            .collect();

        paths.sort();

        for path in paths {
            let name = path.file_name().unwrap().to_string_lossy().into_owned();

            files.push((name, std::fs::read(&path).unwrap()));
        }
    }

    files
}

#[test]
fn chunked_pushes_decode_like_a_source_that_never_runs_dry() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let files = stream_files();
    let mut runs = 0;

    for (name, bytes) in &files {
        let expected = reference(bytes);
        let results: Vec<(u64, Decoded)> = thread::scope(|scope| {
            let started: Vec<_> =
                (0..SEEDS).map(|seed| scope.spawn(move || (seed, decode_pushed(bytes, seed)))).collect();

            started.into_iter().map(|run| run.join().expect("a chunked run panicked")).collect()
        });

        for (seed, actual) in &results {
            if let Some(found) = expected.difference(actual) {
                panic!("{name}, seed {seed}: {found}");
            }

            runs += 1;
        }

        println!(
            "{name}: {SEEDS} seeds equal: {} frames, {} packets, failure {:?}",
            expected.pcm.len() / BYTES_PER_FRAME,
            expected.packets.len(),
            expected.failure
        );
    }

    println!("{runs} chunked runs over {} files equal the reference", files.len());
    assert!(runs >= 19 * SEEDS, "the package's fixtures ran");
    wait_for_workers(workers_before);
}
