//! Synthetic audio files built byte by byte, and the Luau package's fixtures.

#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    clippy::cast_precision_loss,
    reason = "the builders write header fields and samples of known small values"
)]

use std::path::Path;

pub(crate) const ADPCM_BLOCK_FRAMES: u32 = 2041;
const ADPCM_DATA_OFFSET: usize = 60;
const WAVE_FORMAT_PCM: u16 = 1;
const TONE_FREQUENCY: f64 = 440.0;
/// Half scale.
const TONE_PEAK: f64 = 16_384.0;
const WAVE_FORMAT_IEEE_FLOAT: u16 = 3;

/// A WAV file with a 16-byte `fmt ` chunk and `data` as its samples.
pub(crate) fn wav_file(
    format: u16,
    bits_per_sample: u16,
    sample_rate: u32,
    channel_count: u16,
    data: &[u8],
) -> Vec<u8> {
    let block_align = channel_count * bits_per_sample / 8;
    let data_length = data.len() as u32;
    let mut bytes = Vec::new();

    bytes.extend_from_slice(b"RIFF");
    bytes.extend_from_slice(&(36 + data_length).to_le_bytes());
    bytes.extend_from_slice(b"WAVEfmt ");
    bytes.extend_from_slice(&16_u32.to_le_bytes());
    bytes.extend_from_slice(&format.to_le_bytes());
    bytes.extend_from_slice(&channel_count.to_le_bytes());
    bytes.extend_from_slice(&sample_rate.to_le_bytes());
    bytes.extend_from_slice(&sample_rate.wrapping_mul(u32::from(block_align)).to_le_bytes());
    bytes.extend_from_slice(&block_align.to_le_bytes());
    bytes.extend_from_slice(&bits_per_sample.to_le_bytes());
    bytes.extend_from_slice(b"data");
    bytes.extend_from_slice(&data_length.to_le_bytes());
    bytes.extend_from_slice(data);

    bytes
}

pub(crate) fn s16_wav(sample_rate: u32, channel_count: u16, samples: &[i16]) -> Vec<u8> {
    let data: Vec<u8> = samples.iter().flat_map(|sample| sample.to_le_bytes()).collect();

    wav_file(WAVE_FORMAT_PCM, 16, sample_rate, channel_count, &data)
}

pub(crate) fn tone_phase(frame: usize, sample_rate: u32) -> f64 {
    frame as f64 * TONE_FREQUENCY * std::f64::consts::TAU / f64::from(sample_rate)
}

pub(crate) fn tone_sample(frame: usize, sample_rate: u32) -> i16 {
    (tone_phase(frame, sample_rate).sin() * TONE_PEAK) as i16
}

/// A 16-bit PCM WAV with the test tone on the `active` channels and silence on the rest.
pub(crate) fn wav_with(sample_rate: u32, channel_count: u16, frames: usize, active: &[u16]) -> Vec<u8> {
    let mut samples = Vec::with_capacity(frames * usize::from(channel_count));

    for frame in 0..frames {
        let sample = tone_sample(frame, sample_rate);

        samples.extend((0..channel_count).map(|channel| if active.contains(&channel) { sample } else { 0 }));
    }

    s16_wav(sample_rate, channel_count, &samples)
}

/// A 16-bit PCM WAV with the test tone on every channel.
pub(crate) fn wav(sample_rate: u32, channel_count: u16, frames: usize) -> Vec<u8> {
    let active: Vec<u16> = (0..channel_count).collect();

    wav_with(sample_rate, channel_count, frames, &active)
}

/// A silent mono IMA ADPCM WAV of `blocks` 1024-byte blocks (2041 frames each) whose `fact` chunk says
/// `fact_frames`, as ffmpeg writes it.
pub(crate) fn adpcm_wav(sample_rate: u32, fact_frames: u32, blocks: usize) -> Vec<u8> {
    let data_length = blocks as u32 * 1024;
    let mut bytes = Vec::new();

    bytes.extend_from_slice(b"RIFF");
    bytes.extend_from_slice(&(4 + 28 + 12 + 8 + data_length).to_le_bytes());
    bytes.extend_from_slice(b"WAVEfmt ");
    bytes.extend_from_slice(&20_u32.to_le_bytes());
    bytes.extend_from_slice(&0x11_u16.to_le_bytes());
    bytes.extend_from_slice(&1_u16.to_le_bytes());
    bytes.extend_from_slice(&sample_rate.to_le_bytes());
    bytes.extend_from_slice(&(sample_rate * 1024 / 2041).to_le_bytes());
    bytes.extend_from_slice(&1024_u16.to_le_bytes());
    bytes.extend_from_slice(&4_u16.to_le_bytes());
    bytes.extend_from_slice(&2_u16.to_le_bytes());
    bytes.extend_from_slice(&2041_u16.to_le_bytes());
    bytes.extend_from_slice(b"fact");
    bytes.extend_from_slice(&4_u32.to_le_bytes());
    bytes.extend_from_slice(&fact_frames.to_le_bytes());
    bytes.extend_from_slice(b"data");
    bytes.extend_from_slice(&data_length.to_le_bytes());
    bytes.resize(bytes.len() + data_length as usize, 0);

    bytes
}

/// Inserts a `fact` chunk saying `frames` after the 16-byte `fmt ` chunk of a PCM WAV.
pub(crate) fn with_fact(mut wav: Vec<u8>, frames: u32) -> Vec<u8> {
    let mut fact = Vec::from(&b"fact"[..]);

    fact.extend_from_slice(&4_u32.to_le_bytes());
    fact.extend_from_slice(&frames.to_le_bytes());
    wav.splice(36..36, fact);

    let riff_length = wav.len() as u32 - 8;

    wav[4..8].copy_from_slice(&riff_length.to_le_bytes());
    wav
}

/// A 368-byte CAF of 100 frames of mono 24-bit big-endian LPCM whose description claims `frames_per_packet` frames in
/// every 3-byte packet.
pub(crate) fn caf_lpcm(frames_per_packet: u32) -> Vec<u8> {
    let data_length = 300_u32;
    let mut bytes = Vec::from(&b"caff"[..]);

    bytes.extend_from_slice(&1_u16.to_be_bytes());
    bytes.extend_from_slice(&0_u16.to_be_bytes());
    bytes.extend_from_slice(b"desc");
    bytes.extend_from_slice(&32_i64.to_be_bytes());
    bytes.extend_from_slice(&44_100_f64.to_be_bytes());
    bytes.extend_from_slice(b"lpcm");
    bytes.extend_from_slice(&0_u32.to_be_bytes());
    bytes.extend_from_slice(&3_u32.to_be_bytes());
    bytes.extend_from_slice(&frames_per_packet.to_be_bytes());
    bytes.extend_from_slice(&1_u32.to_be_bytes());
    bytes.extend_from_slice(&24_u32.to_be_bytes());
    bytes.extend_from_slice(b"data");
    bytes.extend_from_slice(&(i64::from(data_length) + 4).to_be_bytes());
    bytes.extend_from_slice(&0_u32.to_be_bytes());
    bytes.resize(bytes.len() + data_length as usize, 0);

    bytes
}

/// A 48 kHz `adpcm_wav` of `blocks` blocks with no padding, where the blocks in `corrupt` have an invalid step index,
/// which the decoder rejects with `DecodeError`.
pub(crate) fn corrupted_adpcm_wav(blocks: usize, corrupt: impl Iterator<Item = usize>) -> Vec<u8> {
    let mut bytes = adpcm_wav(48_000, blocks as u32 * ADPCM_BLOCK_FRAMES, blocks);

    for block in corrupt {
        bytes[ADPCM_DATA_OFFSET + block * 1024 + 2] = 0xFF;
    }

    bytes
}

/// The Ogg page checksum: CRC-32 with polynomial 0x04c11db7, no reflection, zero start.
fn ogg_crc(bytes: &[u8]) -> u32 {
    let mut crc = 0_u32;

    for &byte in bytes {
        crc ^= u32::from(byte) << 24;

        for _ in 0..8 {
            crc = match crc & 0x8000_0000 {
                0 => crc << 1,
                _ => (crc << 1) ^ 0x04c1_1db7,
            };
        }
    }

    crc
}

/// One Ogg page holding whole `packets`. `header_type` is 0x02 for the first page of a stream and 0x04 for its last.
fn ogg_page(header_type: u8, granule: u64, serial: u32, sequence: u32, packets: &[&[u8]]) -> Vec<u8> {
    let mut lacing = Vec::new();

    for packet in packets {
        lacing.extend(std::iter::repeat_n(255_u8, packet.len() / 255));
        lacing.push((packet.len() % 255) as u8);
    }

    assert!(lacing.len() <= 255, "too many segments for one page");

    let mut page = Vec::from(&b"OggS\0"[..]);

    page.push(header_type);
    page.extend_from_slice(&granule.to_le_bytes());
    page.extend_from_slice(&serial.to_le_bytes());
    page.extend_from_slice(&sequence.to_le_bytes());
    page.extend_from_slice(&0_u32.to_le_bytes());
    page.push(lacing.len() as u8);
    page.extend_from_slice(&lacing);

    for packet in packets {
        page.extend_from_slice(packet);
    }

    let crc = ogg_crc(&page);

    page[22..26].copy_from_slice(&crc.to_le_bytes());
    page
}

/// A 20 ms stereo CELT packet followed by `filler` bytes of `1`. It is never decoded.
pub(crate) fn opus_packet(filler: usize) -> Vec<u8> {
    let mut packet = vec![0xFC];

    packet.resize(1 + filler, 1);
    packet
}

/// A complete Ogg Opus stream with serial `serial`: an `OpusHead` (family 0, pre-skip 312), `OpusTags`, then
/// `packets`, 200 to a page.
pub(crate) fn ogg_opus(serial: u32, channel_count: u8, packets: &[Vec<u8>]) -> Vec<u8> {
    let mut head = Vec::from(&b"OpusHead\x01"[..]);

    head.push(channel_count);
    head.extend_from_slice(&312_u16.to_le_bytes());
    head.extend_from_slice(&48_000_u32.to_le_bytes());
    head.extend_from_slice(&[0, 0, 0]);

    let tags = b"OpusTags\x04\0\0\0test\0\0\0\0";
    let mut bytes = ogg_page(0x02, 0, serial, 0, &[&head]);

    bytes.extend(ogg_page(0x00, 0, serial, 1, &[tags]));

    let pages: Vec<&[Vec<u8>]> = packets.chunks(200).collect();
    let mut granule = 0;

    for (index, page_packets) in pages.iter().enumerate() {
        let header_type = if index + 1 == pages.len() { 0x04 } else { 0x00 };
        let slices: Vec<&[u8]> = page_packets.iter().map(Vec::as_slice).collect();

        granule += 960 * page_packets.iter().filter(|packet| !packet.is_empty()).count() as u64;
        bytes.extend(ogg_page(header_type, granule, serial, index as u32 + 2, &slices));
    }

    bytes
}

pub(crate) fn float_wav(sample_rate: u32, channel_count: u16, samples: &[f32]) -> Vec<u8> {
    let data: Vec<u8> = samples.iter().flat_map(|sample| sample.to_le_bytes()).collect();

    wav_file(WAVE_FORMAT_IEEE_FLOAT, 32, sample_rate, channel_count, &data)
}

/// The test tone peaking at `amplitude`, where 1 is full scale, with the same sample on both sides.
pub(crate) fn stereo_sine(sample_rate: u32, frames: usize, amplitude: f64) -> Vec<f32> {
    (0..frames)
        .flat_map(|frame| {
            let sample = (tone_phase(frame, sample_rate).sin() * amplitude) as f32;

            [sample, sample]
        })
        .collect()
}

/// A 16-bit AIFF, which can state any channel count. Channel `n` holds the constant `(n % 32 + 1) * 1000`.
pub(crate) fn aiff(sample_rate: u32, channel_count: u16, frames: u32) -> Vec<u8> {
    let data_length = frames * u32::from(channel_count) * 2;
    let exponent = sample_rate.ilog2();
    let mut bytes = Vec::new();

    bytes.extend_from_slice(b"FORM");
    bytes.extend_from_slice(&(4 + 26 + 16 + data_length).to_be_bytes());
    bytes.extend_from_slice(b"AIFFCOMM");
    bytes.extend_from_slice(&18_u32.to_be_bytes());
    bytes.extend_from_slice(&channel_count.to_be_bytes());
    bytes.extend_from_slice(&frames.to_be_bytes());
    bytes.extend_from_slice(&16_u16.to_be_bytes());
    bytes.extend_from_slice(&(16_383 + exponent as u16).to_be_bytes());
    bytes.extend_from_slice(&(u64::from(sample_rate) << (63 - exponent)).to_be_bytes());
    bytes.extend_from_slice(b"SSND");
    bytes.extend_from_slice(&(8 + data_length).to_be_bytes());
    bytes.extend_from_slice(&[0; 8]);

    for _ in 0..frames {
        for channel in 0..channel_count {
            bytes.extend_from_slice(&(((channel % 32) as i16 + 1) * 1000).to_be_bytes());
        }
    }

    bytes
}

/// A fixture of the Luau package, made by `tests/fixtures/generate.sh`.
pub(crate) fn fixture(name: &str) -> Vec<u8> {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("../tests/fixtures").join(name);

    std::fs::read(&path).unwrap_or_else(|failure| panic!("{}: {failure}", path.display()))
}
