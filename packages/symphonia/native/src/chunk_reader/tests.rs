//! How the worker's reader ends: `Ok(0)` after `finish`, `BrokenPipe` after close, and never `Interrupted`. Also the
//! hook the stream tests use to fail a worker on request.

use super::*;

use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc::{self, SyncSender};
use std::thread;
use std::time::Duration;

use symphonia::core::io::{MediaSourceStream, MediaSourceStreamOptions, ReadBytes, ReadOnlySource};

use crate::tests::{EXIT_WAIT, PANIC, wait_until};

const TEST_CHUNKS: usize = 64;

pub fn panic_on_request(chunk: &[u8]) {
    if let Some(message) = chunk.strip_prefix(PANIC) {
        panic!("{}", String::from_utf8_lossy(message));
    }
}

fn reader() -> (SyncSender<Vec<u8>>, ChunkReader) {
    let (input, chunks) = mpsc::sync_channel(TEST_CHUNKS);
    let reader = ChunkReader::new(Arc::new(Mutex::new(chunks)), Arc::new(Mutex::new(Status::new())));

    (input, reader)
}

#[test]
fn the_reader_ends_with_ok_0_after_finish_and_broken_pipe_after_close() {
    let mut buffer = [0_u8; 8];

    // Finish: the chunks, then the end, every time.
    let (input, mut finished) = reader();

    input.send(b"abc".to_vec()).unwrap();
    drop(input);

    assert_eq!(finished.read(&mut buffer).unwrap(), 3);
    assert_eq!(&buffer[..3], b"abc");
    assert_eq!(finished.read(&mut buffer).unwrap(), 0);
    assert_eq!(finished.read(&mut buffer).unwrap(), 0);

    // Close, as `StreamSession::drop` does it: the stop error, even with a chunk queued.
    let (input, mut closed) = reader();

    input.send(vec![1; 4]).unwrap();
    lock(&closed.status).stop();
    drop(input);

    for _ in 0..2 {
        let failure = closed.read(&mut buffer).unwrap_err();

        assert_eq!((failure.kind(), failure.to_string()), (ErrorKind::BrokenPipe, Error::StreamClosed.to_string()));
    }
}

#[test]
fn close_ends_a_read_waiting_inside_read_buf_exact_with_broken_pipe() {
    let (input, waiting) = reader();
    let status = Arc::clone(&waiting.status);

    input.send(vec![1; 10]).unwrap();

    let reader = thread::spawn(move || {
        let mut stream =
            MediaSourceStream::new(Box::new(ReadOnlySource::new(waiting)), MediaSourceStreamOptions::default());
        let mut sixteen = [0_u8; 16];

        ReadBytes::read_buf_exact(&mut stream, &mut sixteen).map_err(|failure| (failure.kind(), failure.to_string()))
    });

    thread::sleep(Duration::from_millis(20));
    lock(&status).stop();
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
