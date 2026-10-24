use std::borrow::Cow;
use std::sync::atomic::{AtomicI32, Ordering};
use std::sync::mpsc::{self, Receiver, SyncSender, TryRecvError, TrySendError};
use std::sync::{Arc, Mutex};
use std::task::Poll;
use std::thread;

use symphonia::core::io::ReadOnlySource;

use crate::chunk_reader::ChunkReader;
use crate::decoder::BYTES_PER_FRAME;
use crate::error::Error;
use crate::fields::{DescribeField, State};
use crate::guard::{catch, lock};
use crate::session::{Info, Session};
use crate::status::Status;

pub(crate) const INPUT_CHUNKS: usize = 64;
pub(crate) const OUTPUT_BLOCKS: usize = 64;
pub(crate) const BLOCK_FRAMES: usize = 4_800;
const WORKER_NAME: &str = "symphonia stream";

static WORKERS: AtomicI32 = AtomicI32::new(0);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PushOutcome {
    Queued,
    Full,
    Refused,
}

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

    pub fn state(&self) -> State {
        lock(&self.status).state()
    }

    pub fn info(&self) -> Option<Info> {
        lock(&self.status).info()
    }

    pub fn describe(&self, field: DescribeField) -> Cow<'static, str> {
        lock(&self.status).describe(field)
    }

    pub fn failure(&self) -> Option<Error> {
        lock(&self.status).failure().cloned()
    }

    pub(crate) fn mark_failed(&self, error: Error) {
        lock(&self.status).mark_failed(error);
    }

    pub fn read(&mut self, output: &mut [u8]) -> Result<Poll<usize>, Error> {
        let held = self.hold_block()?;

        self.check_pcm()?;

        match held {
            Poll::Pending => Ok(Poll::Pending),
            Poll::Ready(Held::End) => Ok(Poll::Ready(0)),
            Poll::Ready(Held::Block) => {
                let block = &self.block[self.offset..];
                let length = block.len().min(output.len() / BYTES_PER_FRAME * BYTES_PER_FRAME);

                output[..length].copy_from_slice(&block[..length]);
                self.offset += length;

                Ok(Poll::Ready(length / BYTES_PER_FRAME))
            }
        }
    }

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
        match self.info() {
            Some(info) if info.is_opus => Err(Error::OpusNeedsReadPacket),
            _ => Ok(()),
        }
    }

    fn check_opus(&self) -> Result<(), Error> {
        match self.info() {
            Some(info) if !info.is_opus => Err(Error::NotOpus),
            _ => Ok(()),
        }
    }

    fn hold_block(&mut self) -> Result<Poll<Held>, Error> {
        while self.offset == self.block.len() {
            let settled = matches!(self.state(), State::Ended | State::Failed);

            match self.output.try_recv() {
                Ok(block) => self.hold(block),
                Err(TryRecvError::Empty) if !settled => return Ok(Poll::Pending),
                Err(_) => return self.failure().map_or(Ok(Poll::Ready(Held::End)), Err),
            }
        }

        Ok(Poll::Ready(Held::Block))
    }

    fn hold(&mut self, block: Vec<u8>) {
        self.block = block;
        self.offset = 0;
    }
}

impl Drop for StreamSession {
    fn drop(&mut self) {
        lock(&self.status).stop();
    }
}

pub(crate) fn worker_count() -> i32 {
    WORKERS.load(Ordering::SeqCst)
}

#[expect(clippy::needless_pass_by_value, reason = "the worker thread owns its handles until it exits")]
fn work(chunks: Arc<Mutex<Receiver<Vec<u8>>>>, output: SyncSender<Vec<u8>>, status: Arc<Mutex<Status>>) {
    let reader = ChunkReader::new(Arc::clone(&chunks), Arc::clone(&status));
    let outcome = catch(|| decode(reader, &output, &status));

    if let Ok(Err(error)) | Err(error) = outcome {
        lock(&status).mark_failed(error);
    }

    drop((output, chunks));
    WORKERS.fetch_sub(1, Ordering::SeqCst);
}

fn decode(reader: ChunkReader, output: &SyncSender<Vec<u8>>, status: &Mutex<Status>) -> Result<(), Error> {
    let mut session = Session::open(Box::new(ReadOnlySource::new(reader)), None, None)?;
    let is_opus = session.is_opus();

    lock(status).publish(&session, State::Open);

    loop {
        let block = if is_opus {
            session.read_packet(usize::MAX).map(|packet| packet.map(Vec::from))
        } else {
            read_pcm_block(&mut session)
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

fn read_pcm_block(session: &mut Session) -> Result<Option<Vec<u8>>, Error> {
    let mut block = vec![0; BLOCK_FRAMES * BYTES_PER_FRAME];
    let frames = session.read(&mut block)?;

    block.truncate(frames * BYTES_PER_FRAME);

    Ok((frames > 0).then_some(block))
}
