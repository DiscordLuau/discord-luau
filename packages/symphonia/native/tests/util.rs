#![expect(clippy::undocumented_unsafe_blocks, reason = "every ABI call passes buffers the test owns")]

use std::ffi::CStr;
use std::io::Cursor;
use std::sync::{Mutex, MutexGuard, PoisonError};
use std::thread;
use std::time::{Duration, Instant};
use std::vec::IntoIter;

use symphonia::core::errors::Result as SymphoniaResult;
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatInfo, FormatOptions, FormatReader, MediaInfo, SeekMode, SeekTo, SeekedTo, Track};
use symphonia::core::io::{MediaSourceStream, MediaSourceStreamOptions};
use symphonia::core::meta::{Metadata, MetadataOptions};
use symphonia::core::packet::Packet;
use discord_luau_symphonia::{
    BYTES_PER_FRAME, Error, Handle, Session, symphonia_close, symphonia_finish, symphonia_info, symphonia_open_memory,
    symphonia_read, symphonia_worker_count,
};

use crate::files::fixture;

pub(crate) const ERROR_CAPACITY: u32 = 256;
pub(crate) const EXIT_WAIT: Duration = Duration::from_secs(1);
pub(crate) const WAIT: Duration = Duration::from_secs(30);
const READ_PACKETS_MAX: usize = 100_000;

pub(crate) fn serial() -> MutexGuard<'static, ()> {
    static LOCK: Mutex<()> = Mutex::new(());

    LOCK.lock().unwrap_or_else(PoisonError::into_inner)
}

pub(crate) fn text(buffer: &[u8]) -> String {
    let end = buffer.iter().position(|&byte| byte == 0).expect("a NUL");

    String::from_utf8(buffer[..end].to_vec()).unwrap()
}

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

pub(crate) fn open(bytes: &[u8], extension: Option<&CStr>) -> (*mut Handle, String) {
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let extension = extension.map_or(std::ptr::null(), CStr::as_ptr);
    let length = u32::try_from(bytes.len()).unwrap();
    let handle =
        unsafe { symphonia_open_memory(bytes.as_ptr(), length, extension, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if handle.is_null() { text(&error) } else { String::new() };

    (handle, message)
}

pub(crate) fn read(handle: *mut Handle, capacity_frames: u32) -> (i32, String) {
    let mut output = vec![0_u8; capacity_frames as usize * BYTES_PER_FRAME];
    let mut error = vec![0xAA_u8; ERROR_CAPACITY as usize];
    let result =
        unsafe { symphonia_read(handle, output.as_mut_ptr(), capacity_frames, error.as_mut_ptr(), ERROR_CAPACITY) };
    let message = if result == -1 { text(&error) } else { String::new() };

    (result, message)
}

pub(crate) fn info(handle: *mut Handle, field: i32) -> i32 {
    unsafe { symphonia_info(handle, field) }
}

pub(crate) fn finish(handle: *mut Handle) -> i32 {
    unsafe { symphonia_finish(handle) }
}

pub(crate) fn close(handle: *mut Handle) {
    unsafe { symphonia_close(handle) };
}

pub(crate) fn read_to_end(handle: *mut Handle, max_frames: i32) -> i32 {
    let mut total = 0;

    loop {
        let (frames, message) = read(handle, 4800);

        assert!(frames >= 0, "{message}");

        if frames == 0 {
            return total;
        }

        total += frames;

        assert!(total <= max_frames, "read more than {max_frames} frames without reaching the end");
    }
}

pub(crate) fn read_session(session: &mut Session, capacity_frames: usize) -> Result<Vec<u8>, Error> {
    let mut output = vec![0; capacity_frames * BYTES_PER_FRAME];
    let frames = session.read(&mut output)?;

    output.truncate(frames * BYTES_PER_FRAME);

    Ok(output)
}

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

pub(crate) struct Replay {
    reader: Box<dyn FormatReader>,
    packets: IntoIter<Packet>,
}

impl Replay {
    pub(crate) fn demux(name: &str) -> Self {
        let media = MediaSourceStream::new(Box::new(Cursor::new(fixture(name))), MediaSourceStreamOptions::default());
        let mut reader = symphonia::default::get_probe()
            .probe(&Hint::new(), media, FormatOptions::default(), MetadataOptions::default())
            .unwrap();
        let mut packets = Vec::new();

        while let Ok(Some(packet)) = reader.next_packet() {
            packets.push(packet);
        }

        Self { reader, packets: packets.into_iter() }
    }
}

impl FormatReader for Replay {
    fn format_info(&self) -> &FormatInfo {
        self.reader.format_info()
    }

    fn media_info(&self) -> &MediaInfo {
        self.reader.media_info()
    }

    fn metadata(&mut self) -> Metadata<'_> {
        self.reader.metadata()
    }

    fn seek(&mut self, mode: SeekMode, to: SeekTo) -> SymphoniaResult<SeekedTo> {
        self.reader.seek(mode, to)
    }

    fn tracks(&self) -> &[Track] {
        self.reader.tracks()
    }

    fn next_packet(&mut self) -> SymphoniaResult<Option<Packet>> {
        Ok(self.packets.next())
    }

    fn into_inner<'source>(self: Box<Self>) -> MediaSourceStream<'source>
    where
        Self: 'source,
    {
        self.reader.into_inner()
    }
}
