//! The panic guard. Every export that can panic, and every stream worker, runs under `catch_quietly`, so no panic
//! crosses the ABI and none takes another session down with it.

use std::any::Any;
use std::cell::Cell;
use std::panic::{self, AssertUnwindSafe};
use std::sync::{Mutex, MutexGuard, Once, PoisonError};

use crate::error::Error;
use crate::ffi::TextBuffer;

static QUIET_HOOK: Once = Once::new();

thread_local! {
    static GUARDED_DEPTH: Cell<u32> = const { Cell::new(0) };
}

/// Runs `body`, turning a panic into `Error::Panicked` without printing it.
pub fn catch_quietly<T>(body: impl FnOnce() -> T) -> Result<T, Error> {
    install_quiet_hook();
    GUARDED_DEPTH.with(|depth| depth.set(depth.get() + 1));

    let outcome = panic::catch_unwind(AssertUnwindSafe(body));

    GUARDED_DEPTH.with(|depth| depth.set(depth.get() - 1));

    outcome.map_err(|payload| panic_error(payload.as_ref()))
}

/// Runs `body` under `catch_quietly`; on an error or a panic, writes its text to `error_out` and returns `failure`.
pub fn guarded<T>(error_out: TextBuffer, failure: T, body: impl FnOnce() -> Result<T, Error>) -> T {
    match catch_quietly(body) {
        Ok(Ok(value)) => value,
        Ok(Err(error)) | Err(error) => {
            error_out.write(&error.to_string());
            failure
        }
    }
}

/// Locks `mutex`, recovering it if a panic poisoned it.
pub fn lock<T>(mutex: &Mutex<T>) -> MutexGuard<'_, T> {
    mutex.lock().unwrap_or_else(PoisonError::into_inner)
}

/// Installs, once, a panic hook that is silent inside a guarded call; other panics, such as a failed test assertion,
/// still reach the previous hook.
fn install_quiet_hook() {
    QUIET_HOOK.call_once(|| {
        let previous = panic::take_hook();

        panic::set_hook(Box::new(move |info| {
            let is_guarded = GUARDED_DEPTH.try_with(|depth| depth.get() > 0).unwrap_or(false);

            if !is_guarded {
                previous(info);
            }
        }));
    });
}

fn panic_error(payload: &(dyn Any + Send)) -> Error {
    let message = match payload.downcast_ref::<&str>() {
        Some(text) => Some((*text).to_string()),
        None => payload.downcast_ref::<String>().cloned(),
    };

    Error::Panicked(message)
}

#[cfg(test)]
mod tests;
