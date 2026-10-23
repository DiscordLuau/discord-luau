//! The stream worker's source: a reader over the pushed chunks that blocks until the next one arrives, so no format
//! reader ever sees a dry source. Test hook: `tests::panic_on_request`.

use std::io::{self, ErrorKind, Read};
use std::sync::mpsc::Receiver;
use std::sync::{Arc, Mutex};

use crate::error::Error;
use crate::guard::lock;
use crate::status::Status;

pub struct ChunkReader {
    /// Behind a `Mutex` because `ReadOnlySource` needs `Sync`. The worker holds a second handle, so the channel
    /// outlives the format reader that owns this one.
    chunks: Arc<Mutex<Receiver<Vec<u8>>>>,
    chunk: Vec<u8>,
    offset: usize,
    status: Arc<Mutex<Status>>,
}

impl ChunkReader {
    pub fn new(chunks: Arc<Mutex<Receiver<Vec<u8>>>>, status: Arc<Mutex<Status>>) -> Self {
        Self { chunks, chunk: Vec::new(), offset: 0, status }
    }
}

impl Read for ChunkReader {
    /// After `finish`, the end is `Ok(0)`. Once the session closes, every read is `BrokenPipe`, even with chunks
    /// queued: never `Ok(0)`, a clean end, nor `Interrupted`, which `MediaSourceStream::read_buf_exact` retries
    /// forever.
    fn read(&mut self, buffer: &mut [u8]) -> io::Result<usize> {
        while self.offset == self.chunk.len() && !buffer.is_empty() {
            let received = lock(&self.chunks).recv();

            if lock(&self.status).is_stopped() {
                return Err(io::Error::new(ErrorKind::BrokenPipe, Error::StreamClosed));
            }

            let Ok(chunk) = received else {
                return Ok(0);
            };

            #[cfg(test)]
            tests::panic_on_request(&chunk);

            self.chunk = chunk;
            self.offset = 0;
        }

        let copied = buffer.len().min(self.chunk.len() - self.offset);

        buffer[..copied].copy_from_slice(&self.chunk[self.offset..][..copied]);
        self.offset += copied;

        Ok(copied)
    }
}

#[cfg(test)]
mod tests;
