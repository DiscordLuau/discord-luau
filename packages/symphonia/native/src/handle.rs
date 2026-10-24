use std::borrow::Cow;
use std::ffi::CStr;
use std::sync::atomic::{AtomicI32, Ordering};
use std::task::Poll;

use crate::decoder::BYTES_PER_FRAME;
use crate::error::Error;
use crate::fields::{DescribeField, State};
use crate::session::{Info, Session};
use crate::stream::StreamSession;

static OPEN_SESSIONS: AtomicI32 = AtomicI32::new(0);

pub enum Handle {
    Direct(Session),
    Stream(StreamSession),
}

impl Handle {
    pub(crate) fn open_memory(bytes: Option<&[u8]>, extension: Option<&CStr>) -> Result<Self, Error> {
        let bytes = bytes.ok_or(Error::NullAudio)?;
        let extension = extension.map(CStr::to_string_lossy);

        Ok(Self::Direct(Session::open_memory(bytes.to_vec(), extension.as_deref())?))
    }

    pub(crate) fn open_file(path: Option<&CStr>, extension: Option<&CStr>) -> Result<Self, Error> {
        let path = path.ok_or(Error::NullPath)?.to_str().map_err(|_| Error::PathNotUtf8)?;
        let extension = extension.map(CStr::to_string_lossy);

        Ok(Self::Direct(Session::open_file(path, extension.as_deref())?))
    }

    pub(crate) fn into_raw(self) -> *mut Self {
        OPEN_SESSIONS.fetch_add(1, Ordering::SeqCst);

        Box::into_raw(Box::new(self))
    }

    /// # Safety
    ///
    /// `pointer` must be null or come from `into_raw`, and is never used again.
    pub(crate) unsafe fn from_raw(pointer: *mut Self) -> Option<Box<Self>> {
        if pointer.is_null() {
            return None;
        }

        OPEN_SESSIONS.fetch_sub(1, Ordering::SeqCst);

        // SAFETY: `pointer` is not null, came from `into_raw`'s `Box`, and is never used again.
        Some(unsafe { Box::from_raw(pointer) })
    }

    pub(crate) fn state(&self) -> State {
        match self {
            Self::Direct(session) => session.state(),
            Self::Stream(stream) => stream.state(),
        }
    }

    pub(crate) fn info(&self) -> Option<Info> {
        match self {
            Self::Direct(session) => Some(session.info()),
            Self::Stream(stream) => stream.info(),
        }
    }

    pub(crate) fn describe(&self, field: DescribeField) -> Cow<'static, str> {
        match self {
            Self::Direct(session) => session.describe(field),
            Self::Stream(stream) => stream.describe(field),
        }
    }

    pub(crate) fn as_stream(&self) -> Option<&StreamSession> {
        match self {
            Self::Direct(_) => None,
            Self::Stream(stream) => Some(stream),
        }
    }

    pub(crate) fn as_stream_mut(&mut self) -> Option<&mut StreamSession> {
        match self {
            Self::Direct(_) => None,
            Self::Stream(stream) => Some(stream),
        }
    }

    pub(crate) fn read(&mut self, output: &mut [u8]) -> Result<Poll<usize>, Error> {
        if output.len() < BYTES_PER_FRAME {
            return Err(Error::ZeroCapacity);
        }

        match self {
            Self::Direct(session) => session.read(output).map(Poll::Ready),
            Self::Stream(stream) => stream.read(output),
        }
    }

    pub(crate) fn read_packet(&mut self, output: &mut [u8]) -> Result<Poll<Option<usize>>, Error> {
        let packet = match self {
            Self::Direct(session) => session.read_packet(output.len())?,
            Self::Stream(stream) => match stream.read_packet(output.len())? {
                Poll::Ready(packet) => packet,
                Poll::Pending => return Ok(Poll::Pending),
            },
        };

        Ok(Poll::Ready(packet.map(|packet| {
            output[..packet.len()].copy_from_slice(&packet);
            packet.len()
        })))
    }

    pub(crate) fn failure(&self) -> Option<Error> {
        match self {
            Self::Direct(session) => session.failure().cloned(),
            Self::Stream(_) => None,
        }
    }

    pub(crate) fn mark_failed(&mut self, error: Error) {
        match self {
            Self::Direct(session) => session.mark_failed(error),
            Self::Stream(stream) => stream.mark_failed(error),
        }
    }
}

pub(crate) fn open_count() -> i32 {
    OPEN_SESSIONS.load(Ordering::SeqCst)
}
