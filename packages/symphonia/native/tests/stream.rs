//! Stream sessions through the ABI and directly: codes, states, closing and failures. Also how the worker's reader
//! ends: `Ok(0)` after `finish`, `BrokenPipe` after close, and never `Interrupted`.

#![expect(clippy::undocumented_unsafe_blocks, reason = "every ABI call passes buffers the test owns")]
#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    reason = "the frame and chunk counts here are small"
)]

use std::io::{self, ErrorKind, Read};
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
    Error, FULL, InfoField, NOT_READY, PushOutcome, State, StreamSession, symphonia_close, symphonia_describe,
    symphonia_finish, symphonia_info, symphonia_open_count, symphonia_open_stream, symphonia_push,
    symphonia_read_packet, symphonia_worker_count,
};
use symphonia::core::io::{MediaSourceStream, MediaSourceStreamOptions, ReadBytes, ReadOnlySource};

use crate::files::{corrupted_adpcm_wav, ogg_opus, opus_packet, wav};
use crate::util::{ERROR_CAPACITY, EXIT_WAIT, WAIT, open, read, serial, text, wait_for_workers, wait_until};

/// How long a call that must not block may take, generously.
const AT_ONCE: Duration = Duration::from_millis(500);
const FAILING_RUNS: usize = 1_000;
const TEST_CHUNKS: usize = 64;

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
    discord_luau_symphonia::with_stream(id, |stream| check(stream))
        .unwrap_or_else(|| panic!("{id} is not a stream session"))
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
    let sent_before = blocks_sent();

    assert_eq!(push(id, &wav(48_000, 2, 480_000)), 0);
    wait_until("the output fills", WAIT, || blocks_sent() - sent_before == OUTPUT_BLOCKS);
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
            let (closed, failure_stored) = output_closed(stream);

            assert!(!closed || failure_stored, "run {run}: the output closed before the failure was stored");

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
    wait_until("the stream fails", WAIT, || stream_state(&session) == State::Failed);

    assert_eq!(
        stream_failure(&session).map(|failure| failure.to_string()).as_deref(),
        Some("the audio has more than 10000 undecodable packets in a row")
    );
    assert_eq!(session.info(InfoField::SkippedPackets), 10_001);

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

#[test]
fn media_source_stream_retries_interrupted_reads() {
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
