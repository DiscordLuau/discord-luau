//! The live sessions by id, behind one lock. Ids count up from 1 and are never reused, so the counter stops at
//! `i32::MAX`.

use std::collections::HashMap;
use std::sync::atomic::{AtomicI32, Ordering};
use std::sync::{LazyLock, Mutex};
use std::task::Poll;

use crate::error::Error;
use crate::fields::{DescribeField, InfoField};
use crate::guard::{catch_quietly, lock};
use crate::session::Session;
use crate::stream::StreamSession;

static SESSIONS: LazyLock<Mutex<HashMap<i32, Entry>>> = LazyLock::new(|| Mutex::new(HashMap::new()));
static NEXT_ID: AtomicI32 = AtomicI32::new(1);

pub enum Entry {
    /// A file or memory session, decoded on the calling thread.
    Direct(Session),
    /// A stream session, decoded on its worker thread.
    Stream(StreamSession),
}

impl Entry {
    pub fn info(&self, field: InfoField) -> i32 {
        match self {
            Self::Direct(session) => session.info(field),
            Self::Stream(stream) => stream.info(field),
        }
    }

    pub fn describe(&self, field: DescribeField) -> String {
        match self {
            Self::Direct(session) => session.describe(field),
            Self::Stream(stream) => stream.describe(field),
        }
    }

    pub fn read(&mut self, capacity_frames: usize) -> Result<Poll<&[u8]>, Error> {
        match self {
            Self::Direct(session) => session.read(capacity_frames).map(Poll::Ready),
            Self::Stream(stream) => stream.read(capacity_frames),
        }
    }

    pub fn read_packet(&mut self, capacity: usize) -> Result<Poll<Option<Box<[u8]>>>, Error> {
        match self {
            Self::Direct(session) => session.read_packet(capacity).map(Poll::Ready),
            Self::Stream(stream) => stream.read_packet(capacity),
        }
    }

    /// The error a call returns before it runs, if the session has failed. A stream has none: its reads deliver the
    /// blocks already decoded, then its failure.
    fn failure(&self) -> Option<Error> {
        match self {
            Self::Direct(session) => session.failure().cloned(),
            Self::Stream(_) => None,
        }
    }

    fn mark_failed(&mut self, error: Error) {
        match self {
            Self::Direct(session) => session.mark_failed(error),
            Self::Stream(stream) => stream.mark_failed(error),
        }
    }
}

pub fn insert(entry: Entry) -> Result<i32, Error> {
    let id = NEXT_ID
        .try_update(Ordering::SeqCst, Ordering::SeqCst, |id| id.checked_add(1))
        .map_err(|_| Error::IdsExhausted)?;

    lock(&SESSIONS).insert(id, entry);

    Ok(id)
}

pub fn with_entry<T>(id: i32, body: impl FnOnce(&mut Entry) -> T) -> Option<T> {
    lock(&SESSIONS).get_mut(&id).map(body)
}

pub fn with_stream<T>(id: i32, body: impl FnOnce(&mut StreamSession) -> T) -> Option<T> {
    match lock(&SESSIONS).get_mut(&id) {
        Some(Entry::Stream(stream)) => Some(body(stream)),
        Some(Entry::Direct(_)) | None => None,
    }
}

/// Runs `body` on session `id`, and marks the session failed if it panics.
///
/// An unknown id is an error, and a failed file or memory session returns its failure without running `body`.
pub fn with_session<T>(id: i32, body: impl FnOnce(&mut Entry) -> Result<T, Error>) -> Result<T, Error> {
    catch_quietly(|| {
        let mut sessions = lock(&SESSIONS);
        let entry = sessions.get_mut(&id).ok_or(Error::UnknownId(id))?;

        if let Some(error) = entry.failure() {
            return Err(error);
        }

        body(entry)
    })
    .unwrap_or_else(|panicked| {
        with_entry(id, |entry| entry.mark_failed(panicked.clone()));
        Err(panicked)
    })
}

/// Removes session `id`, releasing the lock before it returns, so a stream's `Drop` never runs under the lock.
pub fn remove(id: i32) -> Option<Entry> {
    lock(&SESSIONS).remove(&id)
}

pub fn count() -> usize {
    lock(&SESSIONS).len()
}
