//! Stream blocks and chunked pushes: a long decoded block reaches the output in pieces, and audio pushed in chunks of
//! any size decodes like a source that never runs dry.

#![expect(clippy::cast_possible_truncation, reason = "the frame and chunk counts here are small")]

use std::borrow::Cow;
use std::io::Cursor;
use std::path::{Path, PathBuf};
use std::task::Poll;
use std::thread;
use std::time::{Duration, Instant};

use discord_luau_symphonia::testing::{BLOCK_FRAMES, stream_failure, stream_state};
use discord_luau_symphonia::{
    BYTES_PER_FRAME, DescribeField, Error, Info, PushOutcome, Session, State, StreamSession, symphonia_worker_count,
};
use symphonia::core::io::ReadOnlySource;

use crate::files::tone_sample;
use crate::util::{WAIT, read_session, serial, wait_for_workers};

/// The chunked runs per file.
const SEEDS: u64 = 10;
const MAX_CHUNK: usize = 65_536;
const READ_FRAMES: usize = 4_800;
const MAX_PCM_BYTES: usize = 2 * 60 * 48_000 * BYTES_PER_FRAME;
const MAX_PACKETS: usize = 100_000;
/// Names the folder of the streaming spike's generated files, which the chunked runs add when it is set.
const SPIKE_FILES: &str = "DISCORD_LUAU_STREAM_FILES";

/// The FLAC frame and header checksum: a CRC of `width` bits with `polynomial`, starting at 0.
fn flac_crc(bytes: &[u8], width: u32, polynomial: u32) -> u32 {
    let top = 1 << (width - 1);
    let mask = (1 << width) - 1;

    bytes.iter().fold(0, |crc, &byte| {
        (0..8).fold(crc ^ (u32::from(byte) << (width - 8)), |crc, _| {
            (match crc & top {
                0 => crc << 1,
                _ => (crc << 1) ^ polynomial,
            }) & mask
        })
    })
}

/// A 48 kHz stereo 16-bit FLAC of one frame of `frames` frames of the test tone, stored verbatim.
fn one_block_flac(frames: u16) -> Vec<u8> {
    // A verbatim subframe: its header, then every sample.
    let subframe: Vec<u8> = std::iter::once(0x02)
        .chain((0..frames).flat_map(|frame| tone_sample(usize::from(frame), 48_000).to_be_bytes()))
        .collect();
    // STREAMINFO: 20 bits of rate, 3 of channels less one, 5 of bits per sample less one, and 36 of total frames.
    let format = (48_000_u64 << 44) | (1 << 41) | (15 << 36) | u64::from(frames);
    let mut bytes = b"fLaC\x80\0\0\x22".to_vec();

    bytes.extend_from_slice(&frames.to_be_bytes());
    bytes.extend_from_slice(&frames.to_be_bytes());
    bytes.extend_from_slice(&[0; 6]);
    bytes.extend_from_slice(&format.to_be_bytes());
    bytes.extend_from_slice(&[0; 16]);

    // The frame header: a fixed block size given at its end, 48 kHz, left and right, 16 bits, frame 0, then the block
    // size less one, then its CRC-8.
    let frame_start = bytes.len();

    bytes.extend_from_slice(&[0xFF, 0xF8, 0x7A, 0x18, 0x00]);
    bytes.extend_from_slice(&(frames - 1).to_be_bytes());
    bytes.push(flac_crc(&bytes[frame_start..], 8, 0x07) as u8);
    bytes.extend_from_slice(&subframe);
    bytes.extend_from_slice(&subframe);

    let frame_crc = flac_crc(&bytes[frame_start..], 16, 0x8005) as u16;

    bytes.extend_from_slice(&frame_crc.to_be_bytes());
    bytes
}

#[test]
fn a_65535_frame_flac_block_reaches_the_output_in_4800_frame_pieces() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let bytes = one_block_flac(u16::MAX);
    let mut whole = Session::open_memory(bytes.clone(), None).unwrap();
    let expected = read_session(&mut whole, usize::from(u16::MAX) + 1).unwrap();
    let mut session = StreamSession::open().unwrap();
    let mut pieces = Vec::new();
    let mut decoded = Vec::new();

    assert_eq!(expected.len(), usize::from(u16::MAX) * BYTES_PER_FRAME);
    assert_eq!(session.push(bytes), PushOutcome::Queued);
    session.finish();

    let mut deadline = Instant::now() + WAIT;

    let mut block = vec![0; BLOCK_FRAMES * BYTES_PER_FRAME];

    loop {
        // A read never spans two blocks, so a read with room for any block takes exactly one.
        match session.read(&mut block).unwrap() {
            Poll::Ready(0) => break,
            Poll::Ready(frames) => {
                pieces.push(frames);
                decoded.extend_from_slice(&block[..frames * BYTES_PER_FRAME]);
                deadline = Instant::now() + WAIT;
            }
            Poll::Pending => {
                assert!(Instant::now() < deadline, "no block within {WAIT:?}");
                thread::sleep(Duration::from_micros(200));
            }
        }

        assert!(pieces.len() <= 100, "{} pieces", pieces.len());
    }

    assert_eq!(stream_state(&session), State::Ended);
    assert!(decoded == expected, "the pieces join into the block");
    assert!(pieces.iter().all(|&frames| frames <= BLOCK_FRAMES), "pieces of {pieces:?} frames");
    assert_eq!(pieces[..13], [BLOCK_FRAMES; 13]);
    assert_eq!(pieces[13..], [3_135]);

    drop(session);
    wait_for_workers(workers_before);
}

/// Chunk sizes from 1 byte to 64 KB covering `total`, log-uniform so small chunks are common. The streaming spike's
/// generator.
fn chunk_sizes(seed: u64, total: usize) -> Vec<usize> {
    let mut state = seed.wrapping_mul(0x9e37_79b9_7f4a_7c15) | 1;
    let mut next = move || {
        state ^= state << 13;
        state ^= state >> 7;
        state ^= state << 17;
        state
    };
    let mut sizes = Vec::new();
    let mut covered = 0;

    while covered < total {
        let exponent = next() % 17;
        let low = 1_usize << exponent;
        let size = (low + (next() as usize % low)).clamp(1, MAX_CHUNK);
        let size = size.min(total - covered);

        sizes.push(size);
        covered += size;
    }

    sizes
}

/// What a session gave.
#[derive(Default)]
struct Decoded {
    /// The info and the codec and container names, once open.
    opened: Option<(Info, Vec<Cow<'static, str>>)>,
    pcm: Vec<u8>,
    packets: Vec<Box<[u8]>>,
    failure: Option<Error>,
}

impl Decoded {
    fn add_packet(&mut self, packet: Option<Box<[u8]>>) -> bool {
        let more = packet.is_some();

        self.packets.extend(packet);
        more
    }

    fn add_pcm(&mut self, pcm: &[u8]) -> bool {
        self.pcm.extend_from_slice(pcm);
        !pcm.is_empty()
    }

    fn check_bounds(&self) {
        assert!(self.pcm.len() <= MAX_PCM_BYTES, "more than 2 minutes");
        assert!(self.packets.len() <= MAX_PACKETS, "too many packets");
    }

    fn difference(&self, actual: &Self) -> Option<String> {
        let frame = self
            .pcm
            .iter()
            .zip(&actual.pcm)
            .position(|(left, right)| left != right)
            .map(|index| index / BYTES_PER_FRAME);
        let packet = self.packets.iter().zip(&actual.packets).position(|(left, right)| left != right);

        if self.failure != actual.failure {
            return Some(format!("failure {:?}, not {:?}", actual.failure, self.failure));
        }

        if self.opened != actual.opened {
            return Some(format!("opened {:?}, not {:?}", actual.opened, self.opened));
        }

        if let Some(frame) = frame {
            return Some(format!("frame {frame} differs"));
        }

        if self.pcm.len() != actual.pcm.len() {
            return Some(format!("{} bytes, not {}", actual.pcm.len(), self.pcm.len()));
        }

        if let Some(packet) = packet {
            return Some(format!("packet {packet} differs"));
        }

        (self.packets.len() != actual.packets.len())
            .then(|| format!("{} packets, not {}", actual.packets.len(), self.packets.len()))
    }
}

/// What a source holding the whole file, unseekable and of unknown length, gives: what every chunked run must equal.
fn reference(bytes: &[u8]) -> Decoded {
    let source = ReadOnlySource::new(Cursor::new(bytes.to_vec()));
    let mut session = match Session::open(Box::new(source), None, None) {
        Ok(session) => session,
        Err(failure) => return Decoded { failure: Some(failure), ..Decoded::default() },
    };
    let is_opus = session.is_opus();
    let mut decoded = Decoded::default();

    loop {
        let read = if is_opus {
            session.read_packet(usize::MAX).map(|packet| decoded.add_packet(packet))
        } else {
            read_session(&mut session, READ_FRAMES).map(|bytes| decoded.add_pcm(&bytes))
        };

        decoded.check_bounds();

        match read {
            Ok(true) => {}
            Ok(false) => break,
            Err(failure) => {
                decoded.failure = Some(failure);
                break;
            }
        }
    }

    decoded.opened = Some((
        session.info(),
        [DescribeField::Codec, DescribeField::Container].map(|field| session.describe(field)).to_vec(),
    ));
    decoded
}

/// Reads once from `session` into `decoded`: `Ready(true)` when it gave frames or a packet, `Ready(false)` at the end
/// or a failure, `Pending` when nothing was ready.
fn read_once(session: &mut StreamSession, decoded: &mut Decoded) -> Poll<bool> {
    let read = match session.info().map(|info| info.is_opus) {
        Some(true) => session.read_packet(usize::MAX).map(|read| read.map(|packet| decoded.add_packet(packet))),
        Some(false) => {
            let mut output = vec![0; READ_FRAMES * BYTES_PER_FRAME];

            session
                .read(&mut output)
                .map(|read| read.map(|frames| decoded.add_pcm(&output[..frames * BYTES_PER_FRAME])))
        }
        None => stream_failure(session).map_or(Ok(Poll::Pending), Err),
    };

    decoded.check_bounds();

    read.unwrap_or_else(|failure| {
        decoded.failure = Some(failure);
        Poll::Ready(false)
    })
}

fn take_ready(session: &mut StreamSession, decoded: &mut Decoded) {
    while read_once(session, decoded) == Poll::Ready(true) {}
}

fn push_retrying(session: &mut StreamSession, decoded: &mut Decoded, chunk: &[u8]) -> PushOutcome {
    let deadline = Instant::now() + WAIT;

    loop {
        match session.push(chunk.to_vec()) {
            PushOutcome::Full => take_ready(session, decoded),
            outcome => return outcome,
        }

        assert!(Instant::now() < deadline, "the input stayed full");
        thread::yield_now();
    }
}

/// Pushes `bytes` into a new stream in chunks sized by `seed`, retrying a full input and reading what is ready along
/// the way; then finishes and reads to the end, waiting at most `WAIT` for each output.
fn decode_pushed(bytes: &[u8], seed: u64) -> Decoded {
    let mut session = StreamSession::open().unwrap();
    let mut decoded = Decoded::default();
    let mut offset = 0;

    for size in chunk_sizes(seed, bytes.len()) {
        if push_retrying(&mut session, &mut decoded, &bytes[offset..offset + size]) == PushOutcome::Refused {
            break;
        }

        offset += size;
        take_ready(&mut session, &mut decoded);
    }

    session.finish();

    let mut deadline = Instant::now() + WAIT;

    loop {
        match read_once(&mut session, &mut decoded) {
            Poll::Ready(true) => deadline = Instant::now() + WAIT,
            Poll::Ready(false) => break,
            Poll::Pending => {
                assert!(Instant::now() < deadline, "no output for {WAIT:?}");
                thread::sleep(Duration::from_micros(200));
            }
        }
    }

    if let Some(info) = session.info() {
        decoded.opened = Some((
            info,
            [DescribeField::Codec, DescribeField::Container].map(|field| session.describe(field)).to_vec(),
        ));
    }

    decoded
}

/// The files of the chunked runs: the package's fixtures, and the streaming spike's generated files when
/// `DISCORD_LUAU_STREAM_FILES` names their folder.
#[expect(clippy::print_stdout, reason = "the run says when it leaves the spike's files out")]
fn stream_files() -> Vec<(String, Vec<u8>)> {
    let mut folders = vec![Path::new(env!("CARGO_MANIFEST_DIR")).join("../tests/fixtures")];

    match std::env::var_os(SPIKE_FILES) {
        Some(folder) => folders.push(PathBuf::from(folder)),
        None => println!("{SPIKE_FILES} is not set, so only the package's fixtures run"),
    }

    let mut files = Vec::new();

    for folder in folders {
        let mut paths: Vec<PathBuf> = std::fs::read_dir(&folder)
            .unwrap_or_else(|failure| panic!("{}: {failure}", folder.display()))
            .map(|entry| entry.unwrap().path())
            .filter(|path| path.extension().is_some_and(|extension| extension != "sh" && extension != "png"))
            .collect();

        paths.sort();

        for path in paths {
            let name = path.file_name().unwrap().to_string_lossy().into_owned();

            files.push((name, std::fs::read(&path).unwrap()));
        }
    }

    files
}

#[test]
fn chunked_pushes_decode_like_a_source_that_never_runs_dry() {
    let _serial = serial();
    let workers_before = symphonia_worker_count();
    let files = stream_files();
    let mut runs = 0;

    for (name, bytes) in &files {
        let expected = reference(bytes);
        let results: Vec<(u64, Decoded)> = thread::scope(|scope| {
            #[expect(clippy::needless_collect, reason = "every run starts before the first is joined")]
            let started: Vec<_> =
                (0..SEEDS).map(|seed| scope.spawn(move || (seed, decode_pushed(bytes, seed)))).collect();

            started.into_iter().map(|run| run.join().expect("a chunked run panicked")).collect()
        });

        for (seed, actual) in &results {
            assert_eq!(expected.difference(actual), None, "{name}, seed {seed}");
            runs += 1;
        }

        println!(
            "{name}: {SEEDS} seeds equal: {} frames, {} packets, failure {:?}",
            expected.pcm.len() / BYTES_PER_FRAME,
            expected.packets.len(),
            expected.failure
        );
    }

    println!("{runs} chunked runs over {} files equal the reference", files.len());
    assert!(runs >= 19 * SEEDS, "the package's fixtures ran");
    wait_for_workers(workers_before);
}
