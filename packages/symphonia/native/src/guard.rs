use std::any::Any;
use std::panic::{self, AssertUnwindSafe};
use std::sync::{Mutex, MutexGuard, PoisonError};

use crate::error::Error;
use crate::ffi::TextBuffer;
use crate::handle::Handle;

pub(crate) fn catch<T>(body: impl FnOnce() -> T) -> Result<T, Error> {
    panic::catch_unwind(AssertUnwindSafe(body)).map_err(|payload| panic_error(payload.as_ref()))
}

pub(crate) fn guarded<T>(error_out: TextBuffer, failure: T, body: impl FnOnce() -> Result<T, Error>) -> T {
    value_or_failure(catch(body).and_then(|outcome| outcome), error_out, failure)
}

pub(crate) fn guarded_session<T>(
    handle: Option<&mut Handle>,
    error_out: TextBuffer,
    failure: T,
    body: impl FnOnce(&mut Handle) -> Result<T, Error>,
) -> T {
    let outcome = match handle {
        None => Err(Error::NullSession),
        Some(handle) => catch(|| match handle.failure() {
            Some(error) => Err(error),
            None => body(&mut *handle),
        })
        .unwrap_or_else(|panicked| {
            handle.mark_failed(panicked.clone());
            Err(panicked)
        }),
    };

    value_or_failure(outcome, error_out, failure)
}

pub(crate) fn lock<T>(mutex: &Mutex<T>) -> MutexGuard<'_, T> {
    mutex.lock().unwrap_or_else(PoisonError::into_inner)
}

pub(crate) fn panic_error(payload: &(dyn Any + Send)) -> Error {
    let message = match payload.downcast_ref::<&str>() {
        Some(text) => Some((*text).to_string()),
        None => payload.downcast_ref::<String>().cloned(),
    };

    Error::Panicked(message)
}

fn value_or_failure<T>(outcome: Result<T, Error>, error_out: TextBuffer, failure: T) -> T {
    outcome.unwrap_or_else(|error| {
        error_out.write(&error.to_string());
        failure
    })
}
