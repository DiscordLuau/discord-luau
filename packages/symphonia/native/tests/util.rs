//! The harness the tests share: the lock that serialises them, waiting, reading text back, and the ABI and session
//! calls more than one concern makes.

#![expect(clippy::undocumented_unsafe_blocks, reason = "every ABI call passes buffers the test owns")]

use std::ffi::CStr;
use std::sync::{Mutex, MutexGuard, PoisonError};
use std::thread;
use std::time::{Duration, Instant};

use discord_luau_symphonia::{BYTES_PER_FRAME, Session, symphonia_open_memory, symphonia_read, symphonia_worker_count};

pub(crate) const ERROR_CAPACITY: u32 = 256;
/// How long a stream's worker, or a read it is blocked in, may take to return once the stream is done or closed.
pub(crate) const EXIT_WAIT: Duration = Duration::from_secs(1);
/// The longest a test waits for the worker at any one point.
pub(crate) const WAIT: Duration = Duration::from_secs(30);
const READ_PACKETS_MAX: usize = 100_000;

/// Serialises the tests that open sessions or start stream workers, since they share one table and one worker count,
/// and count them.
pub(crate) fn serial() -> MutexGuard<'static, ()> {
    static LOCK: Mutex<()> = Mutex::new(());

    LOCK.lock().unwrap_or_else(PoisonError::into_inner)
}

/// The NUL-terminated text at the start of `buffer`.
pub(crate) fn text(buffer: &[u8]) -> String {
    let end = buffer.iter().position(|&byte| byte == 0).expect("a NUL");

    String::from_utf8(buffer[..end].to_vec()).unwrap()
}

/// Checks `condition` every millisecond, and panics past `bound`.
pub(crate) fn wait_until(what: &str, bound: Duration, mut condition: impl FnMut() -> bool) {
    let deadline = Instant::now() + bound;

    while !condition() {
        assert!(Instant::now() < deadline, "{what}: not within {bound:?}");
        thread::sleep(Duration::from_millis(1));
    }
}

pub(crate) fn wait_for_workers(baseline: i32) {
    wait_until("the workers exit", EXIT_WAIT, || symphonia_worker_count() == baseline);
}

/// Returns the id, and the error if the open failed.
pub(crate) fn open(bytes: &[u8], extension: Option<&CStr>) -> (i32, String) {
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let extension = extension.map_or(std::ptr::null(), CStr::as_ptr);
    let length = u32::try_from(bytes.len()).unwrap();
    let id = unsafe { symphonia_open_memory(bytes.as_ptr(), length, extension, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if id < 0 { text(&error) } else { String::new() };

    (id, message)
}

/// Returns the result, and the error if the read failed.
pub(crate) fn read(id: i32, capacity_frames: u32) -> (i32, String) {
    let mut output = vec![0_u8; capacity_frames as usize * BYTES_PER_FRAME];
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let result =
        unsafe { symphonia_read(id, output.as_mut_ptr(), capacity_frames, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if result == -1 { text(&error) } else { String::new() };

    (result, message)
}

/// Panics after `max_frames`, so a session that never ends fails the test instead of growing forever.
pub(crate) fn read_to_end(id: i32, max_frames: i32) -> i32 {
    let mut total = 0;

    loop {
        let (frames, message) = read(id, 4800);

        assert!(frames >= 0, "{message}");

        if frames == 0 {
            return total;
        }

        total += frames;

        assert!(total <= max_frames, "read more than {max_frames} frames without reaching the end");
    }
}

/// Panics after `READ_PACKETS_MAX`, so a session that never ends fails the test instead of growing forever.
pub(crate) fn read_packets(session: &mut Session) -> Vec<Box<[u8]>> {
    let mut packets = Vec::new();

    while let Some(packet) = session.read_packet(8000).unwrap() {
        packets.push(packet);

        assert!(
            packets.len() <= READ_PACKETS_MAX,
            "read more than {READ_PACKETS_MAX} packets without reaching the end"
        );
    }

    packets
}
