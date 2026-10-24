//! Stream sessions through the ABI and directly: codes, states, closing and failures. Also how the worker's reader
//! ends: `Ok(0)` after `finish`, `BrokenPipe` after close, and never `Interrupted`.

#![expect(clippy::undocumented_unsafe_blocks, reason = "every ABI call passes buffers the test owns")]
#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    reason = "the frame and chunk counts here are small"
)]

use std::io::{self, ErrorKind, Read};
use std::ptr;
use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc::{self, SyncSender};
use std::thread;
use std::time::{Duration, Instant};

use discord_luau_symphonia::testing::{
    BLOCK_FRAMES, INPUT_CHUNKS, OUTPUT_BLOCKS, PANIC, blocks_sent, chunk_reader, output_closed, stream_failure,
    stream_state,
};
use discord_luau_symphonia::{
    Error, FULL, Handle, InfoField, NOT_READY, PushOutcome, State, StreamSession, symphonia_describe,
    symphonia_open_count, symphonia_open_stream, symphonia_push, symphonia_read_packet, symphonia_worker_count,
};
use symphonia::core::io::{MediaSourceStream, MediaSourceStreamOptions, ReadBytes, ReadOnlySource};

use crate::files::{corrupted_adpcm_wav, ogg_opus, opus_packet, wav};
use crate::util::{
    ERROR_CAPACITY, EXIT_WAIT, WAIT, close, finish, info, open, read, serial, text, wait_for_workers, wait_until,
};

/// How long a call that must not block may take, generously.
const AT_ONCE: Duration = Duration::from_millis(500);
const FAILING_RUNS: usize = 1_000;
const TEST_CHUNKS: usize = 64;

fn open_stream() -> *mut Handle {
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let handle = unsafe { symphonia_open_stream(error.as_mut_ptr(), ERROR_CAPACITY) };

    assert!(!handle.is_null(), "{}", text(&error));

    handle
}

fn push(handle: *mut Handle, bytes: &[u8]) -> i32 {
    unsafe { symphonia_push(handle, bytes.as_ptr(), bytes.len() as u32) }
}

/// Checks on every call that field 5 is 1 exactly when the state is 3.
fn state(handle: *mut Handle) -> i32 {
    let state = info(handle, InfoField::State as i32);

    assert_eq!(
        info(handle, InfoField::IsFailed as i32),
        i32::from(state == State::Failed as i32),
        "field 5 is tied to state 3, and the state is {state}"
    );

    state
}

fn describe(handle: *mut Handle, field: i32) -> String {
    let mut output = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let written = unsafe { symphonia_describe(handle, field, output.as_mut_ptr(), ERROR_CAPACITY) };

    assert!(written >= 0, "field {field}");

    text(&output)
}

fn read_packet(handle: *mut Handle) -> (i32, String) {
    let mut output = vec![0_u8; 4_000];
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let result =
        unsafe { symphonia_read_packet(handle, output.as_mut_ptr(), 4_000, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if result == -1 { text(&error) } else { String::new() };

    (result, message)
}

fn with_stream<T>(handle: *mut Handle, check: impl FnOnce(&StreamSession) -> T) -> T {
    match unsafe { &*handle } {
        Handle::Stream(stream) => check(stream),
        Handle::Direct(_) => panic!("not a stream session"),
    }
}

/// Closes on another thread, so a close that blocks fails the test instead of hanging it.
fn close_at_once(handle: *mut Handle, point: &str, baseline: i32) {
    let (closed, returned) = mpsc::channel();
    let address = handle.expose_provenance();

    thread::spawn(move || {
        close(ptr::with_exposed_provenance_mut(address));
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
    let handle = open_stream();

    assert_eq!(symphonia_open_count(), sessions_before + 1);
    assert_eq!(symphonia_worker_count(), workers_before + 1);
    assert_eq!(state(handle), 0, "probing");

    for field in 0..=3 {
        assert_eq!(info(handle, field), -1, "field {field} while probing");
    }

    for field in 0..=2 {
        assert_eq!(describe(handle, field), "", "describe {field} while probing");
    }

    assert_eq!(read(handle, 4800), (NOT_READY, String::new()));
    assert_eq!(read_packet(handle), (NOT_READY, String::new()));

    assert_eq!(push(handle, &wav(44_100, 2, 22_050)), 0);
    assert_eq!(finish(handle), 0);
    assert_eq!(finish(handle), 0, "a second finish");
    wait_until("the stream opens", WAIT, || state(handle) != 0);

    assert_eq!(info(handle, 0), 44_100);
    assert_eq!(info(handle, 1), 2);
    assert_eq!(info(handle, 2), 0);
    assert_eq!(info(handle, 3), 500);
    assert_eq!(describe(handle, 0), "pcm_s16le");
    assert_eq!(describe(handle, 1), "wave");
    assert_eq!(read_packet(handle), (-1, Error::NotOpus.to_string()), "a PCM stream is read with read");

    let mut total = 0;

    wait_until("the stream reads to its end", WAIT, || {
        let (frames, message) = read(handle, 4800);

        assert!(frames >= 0 || frames == NOT_READY, "{message}");
        total += frames.max(0);
        assert!(total <= 48_000, "more frames than the file holds");

        frames == 0
    });

    assert_eq!(total, 24_000);
    assert_eq!(state(handle), 2);
    assert_eq!(read(handle, 4800).0, 0, "the end stays the end");

    close(handle);

    assert_eq!(symphonia_open_count(), sessions_before);
    wait_for_workers(workers_before);
}

#[test]
fn push_and_finish_return_their_codes() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let (file, _) = open(&wav(48_000, 2, 100), None);

    assert_eq!(push(file, &[1]), -1, "a memory session takes no bytes");
    assert_eq!(finish(file), -1, "nor a finish");

    close(file);

    let handle = open_stream();

    assert_eq!(unsafe { symphonia_push(handle, ptr::null(), 4) }, -1, "a null pointer with a length");
    assert_eq!(unsafe { symphonia_push(handle, ptr::null(), 0) }, 0, "an empty push queues nothing");
    assert_eq!(finish(handle), 0);
    assert_eq!(push(handle, &[1]), -1, "after finish");

    close(handle);

    // A WAV that states its length ends there, with no finish, and takes no more.
    let handle = open_stream();

    assert_eq!(push(handle, &wav(48_000, 2, 1_000)), 0);
    wait_until("decoding ends", WAIT, || state(handle) == 2);

    assert_eq!(push(handle, &[0; 16]), -1, "an ended stream");
    assert_eq!(finish(handle), 0, "finish still answers");

    close(handle);

    // Bytes that are not audio fail the stream with Symphonia's message.
    let handle = open_stream();

    assert_eq!(push(handle, &b"not audio ".repeat(400)), 0);
    assert_eq!(finish(handle), 0);
    wait_until("the stream fails", WAIT, || state(handle) == 3);

    let failure = describe(handle, 2);

    assert!(failure.starts_with("not a supported audio file: "), "{failure}");
    assert_eq!(read(handle, 10), (-1, failure.clone()), "reads fail with it");
    assert_eq!(read_packet(handle), (-1, failure));

    for field in 0..=3 {
        assert_eq!(info(handle, field), -1, "field {field}: never opened");
    }

    close(handle);
    wait_for_workers(workers_before);
}

#[test]
fn push_is_full_at_64_chunks_and_never_blocks() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let (results, received) = mpsc::channel();

    // On its own thread, so a push that blocks fails the test instead of hanging it.
    thread::spawn(move || {
        let handle = open_stream();

        // The worker holds this one chunk of 10 s until it has decoded all of it, which a full output stops at
        // 6.4 s, so every later chunk stays queued.
        assert_eq!(push(handle, &wav(48_000, 2, 480_000)), 0);
        wait_until("the stream opens", WAIT, || state(handle) == State::Open as i32);

        let started = Instant::now();
        let codes: Vec<i32> = (0..=INPUT_CHUNKS).map(|_| push(handle, &[0; 16])).collect();

        results.send((codes, started.elapsed())).ok();
        close(handle);
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
    let handle = open_stream();

    assert_eq!(state(handle), 0);
    close_at_once(handle, "probing", workers_before);

    // Waiting for input mid-stream: half a WAV, read until no more is coming.
    let handle = open_stream();
    let bytes = wav(48_000, 2, 48_000);

    assert_eq!(push(handle, &bytes[..bytes.len() / 2]), 0);
    wait_until("the worker waits for input", WAIT, || {
        read(handle, 4800).0 == NOT_READY && {
            thread::sleep(Duration::from_millis(20));
            read(handle, 4800).0 == NOT_READY
        }
    });

    assert_eq!(state(handle), 1);
    close_at_once(handle, "waiting for input", workers_before);

    // Blocked on a full output: 10 s of WAV, unread.
    let handle = open_stream();
    let sent_before = blocks_sent();

    assert_eq!(push(handle, &wav(48_000, 2, 480_000)), 0);
    wait_until("the output fills", WAIT, || blocks_sent() - sent_before == OUTPUT_BLOCKS);
    close_at_once(handle, "blocked on a full output", workers_before);
}

#[test]
fn panics_before_and_after_the_open_fail_the_stream_with_their_messages() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();

    // Before the open: the panic comes inside the probe.
    let handle = open_stream();

    assert_eq!(push(handle, &[PANIC, b"before the open"].concat()), 0);
    wait_until("the stream fails", WAIT, || state(handle) == 3);

    let message = "symphonia wrapper panicked: before the open";

    assert_eq!(describe(handle, 2), message);
    assert_eq!(describe(handle, 0), "");

    for field in 0..=3 {
        assert_eq!(info(handle, field), -1, "field {field}: never opened");
    }

    assert_eq!(push(handle, &[0]), -1);
    assert_eq!(read(handle, 10), (-1, message.to_string()));

    close(handle);

    // After the open: half a WAV opens it, then the panic comes while it decodes.
    let handle = open_stream();
    let bytes = wav(48_000, 2, 48_000);

    assert_eq!(push(handle, &bytes[..bytes.len() / 2]), 0);
    wait_until("the stream opens", WAIT, || state(handle) == 1);
    assert_eq!(push(handle, &[PANIC, b"after the open"].concat()), 0);
    wait_until("the stream fails", WAIT, || state(handle) == 3);

    let message = "symphonia wrapper panicked: after the open";

    assert_eq!(describe(handle, 2), message);
    assert_eq!(info(handle, 0), 48_000, "it had opened");
    assert_eq!(describe(handle, 1), "wave");

    // The blocks decoded before the panic come first: the half held 20 whole packets of 1152 frames, which filled
    // four blocks. Then the failure.
    let mut frames = 0;

    loop {
        match read(handle, 4800) {
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

    close(handle);
    wait_for_workers(workers_before);
}

fn read_until_ready(handle: *mut Handle) -> (i32, String) {
    let deadline = Instant::now() + WAIT;

    loop {
        let read = read(handle, 4800);

        if read.0 != NOT_READY {
            return read;
        }

        assert!(Instant::now() < deadline, "nothing was ready within {WAIT:?}");
        thread::yield_now();
    }
}

fn read_packets_until_failure(handle: *mut Handle, run: usize, deadline: Instant) -> (usize, String) {
    let mut packets = 0;

    loop {
        match read_packet(handle) {
            (-1, message) => return (packets, message),
            (0, _) => panic!("run {run}: the failure read as the end"),
            (NOT_READY, _) => {
                assert!(Instant::now() < deadline, "run {run}: no failure");
                thread::yield_now();
            }
            _ => packets += 1,
        }
    }
}

#[test]
fn a_failure_before_the_open_is_stored_before_the_output_closes() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let junk = b"not audio ".repeat(400);

    for run in 0..FAILING_RUNS {
        let handle = open_stream();
        let deadline = Instant::now() + WAIT;

        push(handle, &junk);
        finish(handle);

        // While this holds the status lock the worker cannot store its failure, so an output seen closed under the
        // lock must already have the failure stored.
        while !with_stream(handle, |stream| {
            let (closed, failure_stored) = output_closed(stream);

            assert!(!closed || failure_stored, "run {run}: the output closed before the failure was stored");

            closed
        }) {
            assert!(Instant::now() < deadline, "run {run}: the worker never ended");
            thread::yield_now();
        }

        let (result, message) = read_until_ready(handle);

        assert_eq!(result, -1, "run {run}: not audio read as {result}");
        assert!(message.starts_with("not a supported audio file"), "{message}");
        assert_eq!(state(handle), 3);

        close(handle);
    }

    wait_for_workers(workers_before);
}

#[test]
fn a_refused_push_finds_the_failure() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let panic = [PANIC, b"in a run"].concat();

    for run in 0..FAILING_RUNS {
        let handle = open_stream();
        let deadline = Instant::now() + WAIT;

        push(handle, &panic);

        while push(handle, &[0]) != -1 {
            assert!(Instant::now() < deadline, "run {run}: no push was refused");
            thread::yield_now();
        }

        assert_eq!(state(handle), 3, "run {run}: a refused push");
        assert_eq!(read_until_ready(handle), (-1, "symphonia wrapper panicked: in a run".to_string()), "run {run}");

        close(handle);
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
        let handle = open_stream();
        let deadline = Instant::now() + WAIT;

        push(handle, &chained);
        finish(handle);

        // Even runs read only once the stream has failed, so both packets wait behind the failure; odd runs read
        // while the worker decodes.
        if run % 2 == 0 {
            wait_until("the stream fails", WAIT, || state(handle) == 3);
        }

        let (packets, message) = read_packets_until_failure(handle, run, deadline);

        assert_eq!(message, Error::StreamChanged.to_string(), "run {run}");
        assert_eq!(packets, 2, "run {run}: the first stream's packets come first");

        close(handle);
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
    wait_until("the stream fails", WAIT, || stream_state(&session) == State::Failed);

    assert_eq!(
        stream_failure(&session).map(|failure| failure.to_string()).as_deref(),
        Some("the audio has more than 10000 undecodable packets in a row")
    );
    assert_eq!(session.info().map(|info| info.skipped_packets), Some(10_001));

    drop(session);
    wait_for_workers(workers_before);
}

/// The input of a new channel, a worker's reader over it, and the function that stops the reader.
fn reader() -> (SyncSender<Vec<u8>>, impl Read + Send + Sync, impl Fn()) {
    let (input, chunks) = mpsc::sync_channel(TEST_CHUNKS);
    let (reader, stop) = chunk_reader(chunks);

    (input, reader, stop)
}

#[test]
fn the_reader_ends_with_ok_0_after_finish_and_broken_pipe_after_close() {
    let mut buffer = [0_u8; 8];

    // Finish: the chunks, then the end, every time.
    let (input, mut finished, _) = reader();

    input.send(b"abc".to_vec()).unwrap();
    drop(input);

    assert_eq!(finished.read(&mut buffer).unwrap(), 3);
    assert_eq!(&buffer[..3], b"abc");
    assert_eq!(finished.read(&mut buffer).unwrap(), 0);
    assert_eq!(finished.read(&mut buffer).unwrap(), 0);

    // Close, as `StreamSession::drop` does it: the stop error, even with a chunk queued.
    let (input, mut closed, stop) = reader();

    input.send(vec![1; 4]).unwrap();
    stop();
    drop(input);

    for _ in 0..2 {
        let failure = closed.read(&mut buffer).unwrap_err();

        assert_eq!((failure.kind(), failure.to_string()), (ErrorKind::BrokenPipe, Error::StreamClosed.to_string()));
    }
}

#[test]
fn close_ends_a_read_waiting_inside_read_buf_exact_with_broken_pipe() {
    let (input, waiting, stop) = reader();

    input.send(vec![1; 10]).unwrap();

    let reader = thread::spawn(move || {
        let mut stream =
            MediaSourceStream::new(Box::new(ReadOnlySource::new(waiting)), MediaSourceStreamOptions::default());
        let mut sixteen = [0_u8; 16];

        ReadBytes::read_buf_exact(&mut stream, &mut sixteen).map_err(|failure| (failure.kind(), failure.to_string()))
    });

    thread::sleep(Duration::from_millis(20));
    stop();
    drop(input);
    wait_until("the read returns", EXIT_WAIT, || reader.is_finished());

    assert_eq!(
        reader.join().unwrap(),
        Err((ErrorKind::BrokenPipe, Error::StreamClosed.to_string())),
        "the stop error, not the end of the file"
    );
}

/// Interrupted a thousand times, then bytes of 7.
struct Flaky(Arc<AtomicUsize>);

impl Read for Flaky {
    fn read(&mut self, buffer: &mut [u8]) -> io::Result<usize> {
        if self.0.fetch_add(1, Ordering::SeqCst) < 1_000 {
            return Err(io::Error::from(ErrorKind::Interrupted));
        }

        buffer.fill(7);

        Ok(buffer.len())
    }
}

#[test]
fn media_source_stream_retries_interrupted_reads() {
    // Why a closed stream's reader does not return `Interrupted`: Symphonia calls it again.
    let calls = Arc::new(AtomicUsize::new(0));
    let mut stream = MediaSourceStream::new(
        Box::new(ReadOnlySource::new(Flaky(Arc::clone(&calls)))),
        MediaSourceStreamOptions::default(),
    );
    let mut four = [0_u8; 4];

    ReadBytes::read_buf_exact(&mut stream, &mut four).unwrap();

    assert_eq!(four, [7; 4]);
    assert_eq!(calls.load(Ordering::SeqCst), 1_001);
}
