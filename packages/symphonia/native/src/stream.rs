//! Stream sessions: audio pushed in chunks, decoded on a worker thread under the panic guard, and read without
//! blocking. Test hook: `testing::count_block`.

use std::sync::atomic::{AtomicI32, Ordering};
use std::sync::mpsc::{self, Receiver, SyncSender, TryRecvError, TrySendError};
use std::sync::{Arc, Mutex};
use std::task::Poll;
use std::thread;

use symphonia::core::io::ReadOnlySource;

use crate::chunk_reader::ChunkReader;
use crate::decoder::BYTES_PER_FRAME;
use crate::error::Error;
use crate::fields::{DescribeField, InfoField, State};
use crate::guard::{catch_quietly, lock};
use crate::session::Session;
use crate::status::Status;

pub(crate) const INPUT_CHUNKS: usize = 64;
pub(crate) const OUTPUT_BLOCKS: usize = 64;
/// 100 ms; a longer decoded packet is split.
pub(crate) const BLOCK_FRAMES: usize = 4_800;
const WORKER_NAME: &str = "symphonia stream";

static WORKERS: AtomicI32 = AtomicI32::new(0);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PushOutcome {
    /// Also for an empty chunk, which needs no queueing.
    Queued,
    Full,
    /// After `finish`, or once the stream has ended or failed.
    Refused,
}

/// What `hold_block` holds once it is ready.
enum Held {
    Block,
    End,
}

pub struct StreamSession {
    input: Option<SyncSender<Vec<u8>>>,
    pub(crate) output: Receiver<Vec<u8>>,
    block: Vec<u8>,
    offset: usize,
    pub(crate) status: Arc<Mutex<Status>>,
}

impl StreamSession {
    pub fn open() -> Result<Self, Error> {
        let (input, chunks) = mpsc::sync_channel(INPUT_CHUNKS);
        let (blocks, output) = mpsc::sync_channel(OUTPUT_BLOCKS);
        let status = Arc::new(Mutex::new(Status::new()));
        let worker_status = Arc::clone(&status);

        WORKERS.fetch_add(1, Ordering::SeqCst);
        thread::Builder::new()
            .name(WORKER_NAME.to_string())
            .spawn(move || work(Arc::new(Mutex::new(chunks)), blocks, worker_status))
            .map_err(|failure| {
                WORKERS.fetch_sub(1, Ordering::SeqCst);
                Error::WorkerUnavailable(failure.to_string())
            })?;

        Ok(Self { input: Some(input), output, block: Vec::new(), offset: 0, status })
    }

    pub fn push(&self, chunk: Vec<u8>) -> PushOutcome {
        let Some(input) = &self.input else {
            return PushOutcome::Refused;
        };

        if !matches!(self.state(), State::Probing | State::Open) {
            return PushOutcome::Refused;
        }

        if chunk.is_empty() {
            return PushOutcome::Queued;
        }

        match input.try_send(chunk) {
            Ok(()) => PushOutcome::Queued,
            Err(TrySendError::Full(_)) => PushOutcome::Full,
            Err(TrySendError::Disconnected(_)) => PushOutcome::Refused,
        }
    }

    pub fn finish(&mut self) {
        self.input = None;
    }

    pub(crate) fn state(&self) -> State {
        lock(&self.status).state()
    }

    pub fn info(&self, field: InfoField) -> i32 {
        lock(&self.status).info(field)
    }

    pub fn describe(&self, field: DescribeField) -> String {
        lock(&self.status).describe(field)
    }

    pub(crate) fn failure(&self) -> Option<Error> {
        lock(&self.status).failure().cloned()
    }

    pub(crate) fn mark_failed(&self, error: Error) {
        lock(&self.status).mark_failed(error);
    }

    /// Reads up to `capacity_frames` frames from one ready block, keeping the rest of it for the next read.
    pub fn read(&mut self, capacity_frames: usize) -> Result<Poll<&[u8]>, Error> {
        let held = self.hold_block()?;

        self.check_pcm()?;

        match held {
            Poll::Pending => Ok(Poll::Pending),
            Poll::Ready(Held::End) => Ok(Poll::Ready(&[])),
            Poll::Ready(Held::Block) => {
                let start = self.offset;
                let wanted = capacity_frames.saturating_mul(BYTES_PER_FRAME);

                self.offset = self.block.len().min(start.saturating_add(wanted));

                Ok(Poll::Ready(&self.block[start..self.offset]))
            }
        }
    }

    /// A packet over `capacity` bytes is an error, and stays next for a bigger buffer.
    pub fn read_packet(&mut self, capacity: usize) -> Result<Poll<Option<Box<[u8]>>>, Error> {
        let held = self.hold_block()?;

        self.check_opus()?;

        match held {
            Poll::Pending => Ok(Poll::Pending),
            Poll::Ready(Held::End) => Ok(Poll::Ready(None)),
            Poll::Ready(Held::Block) if self.block.len() > capacity => {
                Err(Error::PacketTooLarge { length: self.block.len(), capacity })
            }
            Poll::Ready(Held::Block) => Ok(Poll::Ready(Some(std::mem::take(&mut self.block).into_boxed_slice()))),
        }
    }

    fn check_pcm(&self) -> Result<(), Error> {
        if self.info(InfoField::IsOpus) == 1 { Err(Error::OpusNeedsReadPacket) } else { Ok(()) }
    }

    fn check_opus(&self) -> Result<(), Error> {
        if self.info(InfoField::IsOpus) == 0 { Err(Error::NotOpus) } else { Ok(()) }
    }

    /// Holds a block with bytes left: `Ready(Held::Block)` once it holds one, `Pending` while none is ready, and
    /// `Ready(Held::End)` or the failure once none is left.
    ///
    /// The state is read before the queue, and the worker stores its final state after its last block, so an empty
    /// queue under a final state is the end of it, and every block decoded comes before the failure. The worker
    /// publishes the kind before its first block, so a held block always knows whether it is Opus.
    fn hold_block(&mut self) -> Result<Poll<Held>, Error> {
        while self.offset == self.block.len() {
            let settled = matches!(self.state(), State::Ended | State::Failed);

            match self.output.try_recv() {
                Ok(block) => {
                    self.block = block;
                    self.offset = 0;
                }
                Err(TryRecvError::Empty) if !settled => return Ok(Poll::Pending),
                Err(_) => return self.failure().map_or(Ok(Poll::Ready(Held::End)), Err),
            }
        }

        Ok(Poll::Ready(Held::Block))
    }
}

impl Drop for StreamSession {
    /// Stops the worker without waiting for it. The flag is set before the fields drop the channel ends, so a reader
    /// woken by the disconnect sees it.
    fn drop(&mut self) {
        lock(&self.status).stop();
    }
}

pub(crate) fn worker_count() -> i32 {
    WORKERS.load(Ordering::SeqCst)
}

/// Decodes under the panic guard, stores any failure, and only then drops its channel ends, so a disconnect always
/// finds the final state.
#[expect(clippy::needless_pass_by_value, reason = "the worker thread owns its handles until it exits")]
fn work(chunks: Arc<Mutex<Receiver<Vec<u8>>>>, output: SyncSender<Vec<u8>>, status: Arc<Mutex<Status>>) {
    let reader = ChunkReader::new(Arc::clone(&chunks), Arc::clone(&status));
    let outcome = catch_quietly(|| decode(reader, &output, &status));

    if let Ok(Err(error)) | Err(error) = outcome {
        lock(&status).mark_failed(error);
    }

    drop((output, chunks));
    WORKERS.fetch_sub(1, Ordering::SeqCst);
}

/// Publishes after every read, the failing one too, and returns early once the session has closed.
///
/// A stream cannot seek back for a WAV `fact` chunk, so an ADPCM WAV keeps the padding of its last block.
fn decode(reader: ChunkReader, output: &SyncSender<Vec<u8>>, status: &Mutex<Status>) -> Result<(), Error> {
    let mut session = Session::open(Box::new(ReadOnlySource::new(reader)), None, None)?;
    let is_opus = session.is_opus();

    lock(status).publish(&session, State::Open);

    loop {
        let block = if is_opus {
            session.read_packet(usize::MAX).map(|packet| packet.map(Vec::from))
        } else {
            session.read(BLOCK_FRAMES).map(|bytes| Some(bytes.to_vec()).filter(|block| !block.is_empty()))
        };

        lock(status).publish(&session, State::Open);

        let Some(block) = block? else {
            break;
        };

        if output.send(block).is_err() {
            return Ok(());
        }

        #[cfg(feature = "testing")]
        crate::testing::count_block();
    }

    lock(status).publish(&session, State::Ended);

    Ok(())
}
