use std::io::{self, ErrorKind, Read};
use std::sync::mpsc::Receiver;
use std::sync::{Arc, Mutex};

use crate::error::Error;
use crate::guard::lock;
use crate::status::Status;

pub(crate) struct ChunkReader {
    chunks: Arc<Mutex<Receiver<Vec<u8>>>>,
    chunk: Vec<u8>,
    offset: usize,
    status: Arc<Mutex<Status>>,
}

impl ChunkReader {
    pub(crate) fn new(chunks: Arc<Mutex<Receiver<Vec<u8>>>>, status: Arc<Mutex<Status>>) -> Self {
        Self { chunks, chunk: Vec::new(), offset: 0, status }
    }

    fn hold(&mut self, chunk: Vec<u8>) {
        #[cfg(feature = "testing")]
        crate::testing::panic_on_request(&chunk);

        self.chunk = chunk;
        self.offset = 0;
    }
}

impl Read for ChunkReader {
    fn read(&mut self, buffer: &mut [u8]) -> io::Result<usize> {
        while self.offset == self.chunk.len() && !buffer.is_empty() {
            let received = lock(&self.chunks).recv();
            let stopped = lock(&self.status).is_stopped();

            match (stopped, received) {
                (true, _) => return Err(io::Error::new(ErrorKind::BrokenPipe, Error::StreamClosed)),
                (false, Ok(chunk)) => self.hold(chunk),
                (false, Err(_)) => return Ok(0),
            }
        }

        let copied = buffer.len().min(self.chunk.len() - self.offset);

        buffer[..copied].copy_from_slice(&self.chunk[self.offset..][..copied]);
        self.offset += copied;

        Ok(copied)
    }
}
