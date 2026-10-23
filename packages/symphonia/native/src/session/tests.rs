//! Sessions over synthetic files and the Luau package's fixtures.

#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    clippy::cast_precision_loss,
    clippy::cast_sign_loss,
    reason = "the builders write header fields and samples of known small values"
)]

use super::*;

use std::collections::VecDeque;

use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::packet::Packet;

use crate::decoder::BYTES_PER_FRAME;
use crate::tests::{
    ADPCM_BLOCK_FRAMES, adpcm_wav, caf_lpcm, corrupted_adpcm_wav, ogg_opus, opus_packet, s16_wav, tone_phase, wav,
    wav_file, wav_with, with_fact,
};

const WAVE_FORMAT_IEEE_FLOAT: u16 = 3;
/// Ten times the longest audio these tests make.
const READ_ALL_MAX_FRAMES: usize = 480_000;
const READ_PACKETS_MAX: usize = 100_000;

fn float_wav(sample_rate: u32, channel_count: u16, samples: &[f32]) -> Vec<u8> {
    let data: Vec<u8> = samples.iter().flat_map(|sample| sample.to_le_bytes()).collect();

    wav_file(WAVE_FORMAT_IEEE_FLOAT, 32, sample_rate, channel_count, &data)
}

/// The test tone peaking at `amplitude`, where 1 is full scale, with the same sample on both sides.
fn stereo_sine(sample_rate: u32, frames: usize, amplitude: f64) -> Vec<f32> {
    (0..frames)
        .flat_map(|frame| {
            let sample = (tone_phase(frame, sample_rate).sin() * amplitude) as f32;

            [sample, sample]
        })
        .collect()
}

/// A 16-bit AIFF, which can state any channel count. Channel `n` holds the constant `(n % 32 + 1) * 1000`.
fn aiff(sample_rate: u32, channel_count: u16, frames: u32) -> Vec<u8> {
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

/// The Luau decoder's plain conversion of a float sample to s16: non-finite to 0, scaled by 32768, rounded half away
/// from zero, and clamped.
fn to_s16(sample: f32) -> i16 {
    if !sample.is_finite() {
        return 0;
    }

    (f64::from(sample) * 32_768.0).round().clamp(-32_768.0, 32_767.0) as i16
}

fn floats(bytes: &[u8]) -> Vec<f32> {
    bytes.as_chunks::<4>().0.iter().map(|&sample| f32::from_le_bytes(sample)).collect()
}

/// Panics after `READ_ALL_MAX_FRAMES`, so a session that never ends fails the test instead of growing forever.
fn read_floats(session: &mut Session, capacity: usize) -> Vec<f32> {
    let mut samples = Vec::new();

    loop {
        let bytes = session.read(capacity).unwrap();

        if bytes.is_empty() {
            return samples;
        }

        samples.extend(floats(bytes));

        assert!(
            samples.len() <= READ_ALL_MAX_FRAMES * 2,
            "read more than {READ_ALL_MAX_FRAMES} frames without reaching the end"
        );
    }
}

/// The left and right samples to the end, converted to s16 as the Luau decoder converts them.
fn read_all(session: &mut Session) -> (Vec<i16>, Vec<i16>) {
    read_all_in(session, 4800)
}

fn read_all_in(session: &mut Session, capacity: usize) -> (Vec<i16>, Vec<i16>) {
    let samples: Vec<i16> = read_floats(session, capacity).into_iter().map(to_s16).collect();
    let left = samples.iter().step_by(2).copied().collect();
    let right = samples.iter().skip(1).step_by(2).copied().collect();

    (left, right)
}

/// The frequency of `samples` at 48 kHz, from the zero crossings of their middle three fifths.
fn frequency(samples: &[i16]) -> f64 {
    let middle = &samples[samples.len() / 5..samples.len() * 4 / 5];
    let crossings = middle.windows(2).filter(|pair| (pair[0] < 0) != (pair[1] < 0)).count();

    crossings as f64 / 2.0 / (middle.len() as f64 / 48_000.0)
}

fn peak(samples: &[i16]) -> i32 {
    samples.iter().map(|&sample| i32::from(sample).abs()).max().unwrap_or(0)
}

#[test]
fn a_wav_decodes_to_48_khz_stereo_with_the_exact_length() {
    for (rate, channels) in [(8_000, 1), (22_050, 2), (44_100, 2), (48_000, 1), (47_999, 2)] {
        let frames = rate as usize / 2;
        let mut session = Session::open_memory(wav(rate, channels, frames), None).unwrap();
        let (left, right) = read_all(&mut session);

        assert_eq!(left.len(), (frames as u64 * 48_000).div_ceil(u64::from(rate)) as usize, "{rate} Hz");
        assert!((frequency(&left) - 440.0).abs() < 3.0, "{rate} Hz: {} Hz", frequency(&left));
        assert!(peak(&left) > 1000 && peak(&right) > 1000);
        assert_eq!(session.info(InfoField::SampleRate), rate as i32);
        assert_eq!(session.info(InfoField::Channels), i32::from(channels));
        assert_eq!(session.info(InfoField::DurationMilliseconds), 500);
    }
}

#[test]
fn a_wav_names_its_codec_and_container() {
    let session = Session::open_memory(wav(44_100, 2, 100), Some("wav")).unwrap();

    assert_eq!(session.describe(DescribeField::Codec), "pcm_s16le");
    assert_eq!(session.describe(DescribeField::Container), "wave");
    assert_eq!(session.info(InfoField::IsOpus), 0);
    assert_eq!(session.info(InfoField::IsFailed), 0);
}

#[test]
fn five_one_keeps_front_left_and_rear_right_apart() {
    // The 5.1 order is FL, FR, FC, LFE, RL, RR. The tone is on FL alone, then on RR alone.
    let bytes = wav_with(48_000, 6, 24_000, &[0]);
    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, right) = read_all(&mut session);

    assert!(peak(&left) > 1000, "left carries FL");
    assert_eq!(peak(&right), 0, "right has nothing from FL");

    let bytes = wav_with(48_000, 6, 24_000, &[5]);
    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, right) = read_all(&mut session);

    assert_eq!(peak(&left), 0, "left has nothing from RR");
    assert!(peak(&right) > 1000, "right carries RR");
}

#[test]
fn discrete_channels_use_the_first_two() {
    // AIFF states four or more channels as discrete.
    let mut session = Session::open_memory(aiff(48_000, 4, 1_600), None).unwrap();

    assert_eq!(session.info(InfoField::Channels), 4);
    assert_eq!(session.describe(DescribeField::Container), "aiff");

    let (left, right) = read_all(&mut session);

    assert_eq!(left.len(), 1_600);
    assert!(left.iter().all(|&sample| sample == 1000), "left is channel 0");
    assert!(right.iter().all(|&sample| sample == 2000), "right is channel 1");
}

#[test]
fn reads_after_the_end_stay_empty() {
    let mut session = Session::open_memory(wav(44_100, 2, 441), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 480);
    assert_eq!(session.read(4800).unwrap(), b"");
    assert_eq!(session.read(4800).unwrap(), b"");
}

#[test]
fn reads_respect_the_capacity() {
    let mut session = Session::open_memory(wav(48_000, 2, 1_000), None).unwrap();

    assert_eq!(session.read(300).unwrap().len(), 300 * BYTES_PER_FRAME);
    assert_eq!(session.read(1).unwrap().len(), BYTES_PER_FRAME);
}

#[test]
fn hostile_sample_rates_fail_at_open() {
    for rate in [1, 999, 384_001, 2_147_483_647] {
        let failure = Session::open_memory(wav(rate, 1, 2_000), None).err().unwrap();

        assert_eq!(failure, Error::SampleRateOutOfRange(rate));
    }
}

#[test]
fn too_many_channels_fail_at_open() {
    let failure = Session::open_memory(aiff(48_000, 33, 10), None).err().unwrap();

    assert_eq!(failure, Error::ChannelCountOutOfRange(33));
    assert!(Session::open_memory(aiff(48_000, 32, 10), None).is_ok());
}

#[test]
fn empty_and_unrecognised_audio_fail_at_open() {
    assert_eq!(Session::open_memory(Vec::new(), None).err().unwrap(), Error::EmptyAudio);

    let failure = Session::open_memory(b"not audio ".repeat(400), Some("mp3")).err().unwrap().to_string();

    assert!(failure.starts_with("not a supported audio file"), "{failure}");
}

#[test]
fn a_missing_file_fails_at_open() {
    let failure = Session::open_file("/nonexistent/tone.mp3", None).err().unwrap().to_string();

    assert!(failure.starts_with("/nonexistent/tone.mp3: "), "{failure}");
}

#[test]
fn read_packet_needs_opus_and_read_needs_pcm() {
    let mut session = Session::open_memory(wav(48_000, 2, 100), None).unwrap();

    assert_eq!(session.read_packet(8000).err().unwrap(), Error::NotOpus);
}

#[test]
fn adpcm_block_padding_is_trimmed_to_the_fact_chunk() {
    // 0.5 s at 22050 Hz in six blocks holds 12246 frames, 1221 of them padding.
    let mut session = Session::open_memory(adpcm_wav(22_050, 11_025, 6), None).unwrap();

    assert_eq!(session.describe(DescribeField::Codec), "adpcm_ima_wav");
    assert_eq!(session.info(InfoField::DurationMilliseconds), 500);

    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 24_000);
}

#[test]
fn adpcm_from_a_file_is_trimmed_too() {
    let path = std::env::temp_dir().join(format!("discord-luau-symphonia-adpcm-{}.wav", std::process::id()));

    std::fs::write(&path, adpcm_wav(22_050, 11_025, 6)).unwrap();

    let opened = Session::open_file(path.to_str().unwrap(), None);

    std::fs::remove_file(&path).unwrap();

    let mut session = opened.unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 24_000);
    assert_eq!(session.info(InfoField::DurationMilliseconds), 500);
}

#[test]
fn a_huge_packet_size_fails_at_open() {
    // The PCM decoder allocates the claimed frames per packet times the channel count when it is made, so this
    // 368-byte file asked for 16 GB.
    let bytes = caf_lpcm(u32::MAX);

    assert_eq!(bytes.len(), 368);
    assert_eq!(
        Session::open_memory(bytes, None).err().unwrap().to_string(),
        "the audio declares packets of 4294967295 frames; at most 262144 are supported"
    );
}

/// Panics after `READ_PACKETS_MAX`, so a session that never ends fails the test instead of growing forever.
fn read_packets(session: &mut Session) -> Vec<Box<[u8]>> {
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

#[test]
fn a_hand_made_ogg_opus_stream_passes_through() {
    let packets = vec![opus_packet(10), opus_packet(20), opus_packet(30)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(session.describe(DescribeField::Codec), "opus");
    assert_eq!(session.describe(DescribeField::Container), "ogg");

    let read: Vec<Vec<u8>> = read_packets(&mut session).into_iter().map(Vec::from).collect();

    assert_eq!(read, packets);
}

#[test]
fn empty_opus_packets_are_skipped_and_counted() {
    let packets = vec![opus_packet(10), Vec::new(), opus_packet(20)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&packets[0][..]));
    assert_eq!(
        session.read_packet(8000).unwrap().as_deref(),
        Some(&packets[2][..]),
        "the empty packet is not returned, so it cannot look like the end"
    );
    assert_eq!(session.read_packet(8000).unwrap(), None);
    assert_eq!(session.info(InfoField::SkippedPackets), 1);
}

#[test]
fn a_chained_ogg_stream_is_the_stream_changed_error() {
    let mut bytes = ogg_opus(7, 2, &[opus_packet(10), opus_packet(20)]);

    bytes.extend(ogg_opus(8, 1, &[opus_packet(30)]));

    let mut session = Session::open_memory(bytes, None).unwrap();

    assert!(session.read_packet(8000).unwrap().is_some());
    assert!(session.read_packet(8000).unwrap().is_some());
    assert_eq!(session.read_packet(8000).err().unwrap(), Error::StreamChanged);
}

#[test]
fn a_decoded_rate_that_differs_from_the_tracks_is_an_error() {
    let mut session = Session::open_memory(wav(48_000, 2, 1_000), None).unwrap();

    session.sample_rate = 44_100;

    assert_eq!(
        session.read(4800).err().unwrap(),
        Error::SampleRateChanged { track_rate: 44_100, decoded_rate: 48_000 }
    );
}

#[test]
fn an_undecodable_packet_is_skipped_and_counted() {
    let mut session = Session::open_memory(corrupted_adpcm_wav(6, [2].into_iter()), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 5 * ADPCM_BLOCK_FRAMES as usize);
    assert_eq!(session.info(InfoField::SkippedPackets), 1);
}

#[test]
fn ten_thousand_undecodable_packets_in_a_row_are_allowed() {
    let bytes = corrupted_adpcm_wav(10_001, 0..10_000);
    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), ADPCM_BLOCK_FRAMES as usize);
    assert_eq!(session.info(InfoField::SkippedPackets), 10_000);
}

#[test]
fn more_than_ten_thousand_undecodable_packets_in_a_row_are_an_error() {
    let bytes = corrupted_adpcm_wav(10_002, 0..10_001);
    let mut session = Session::open_memory(bytes, None).unwrap();

    assert_eq!(
        session.read(4800).err().unwrap().to_string(),
        "the audio has more than 10000 undecodable packets in a row"
    );
}

#[test]
fn a_decoded_packet_resets_the_run_of_skips() {
    // Two runs of 6000 with one good block between them never reach 10000 in a row.
    let corrupt = (0..6_000).chain(6_001..12_001);
    let mut session = Session::open_memory(corrupted_adpcm_wav(12_001, corrupt), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), ADPCM_BLOCK_FRAMES as usize);
    assert_eq!(session.info(InfoField::SkippedPackets), 12_000);
}

#[test]
fn more_than_ten_thousand_empty_opus_packets_in_a_row_are_an_error() {
    let mut packets = vec![Vec::new(); 10_000];

    packets.push(opus_packet(10));

    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(read_packets(&mut session).len(), 1, "10000 in a row are allowed");
    assert_eq!(session.info(InfoField::SkippedPackets), 10_000);

    let packets = vec![Vec::new(); 10_001];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(
        session.read_packet(8000).err().unwrap().to_string(),
        "the audio has more than 10000 undecodable packets in a row"
    );
}

#[test]
fn a_packet_too_large_for_the_buffer_stays_pending() {
    let packets = vec![opus_packet(99), opus_packet(9)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();
    let too_large = Error::PacketTooLarge { length: 100, capacity: 50 };

    assert_eq!(session.read_packet(50).err().unwrap(), too_large);
    assert_eq!(session.read_packet(50).err().unwrap(), too_large, "a second small read still sees the same packet");
    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&packets[0][..]));
    assert_eq!(session.read_packet(50).unwrap().as_deref(), Some(&packets[1][..]));
    assert_eq!(session.read_packet(8000).unwrap(), None);
}

#[test]
fn a_truncated_wav_ends_early_and_cleanly() {
    // The data chunk still claims 4800 frames, but the last 1000 bytes are gone.
    let mut bytes = wav(48_000, 2, 4_800);

    bytes.truncate(bytes.len() - 1_000);

    let wav_frame_bytes = 4;
    let present = (bytes.len() - 44) / wav_frame_bytes;
    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, _) = read_all(&mut session);

    assert!(!left.is_empty() && left.len() <= present, "{} of {present} frames", left.len());
    assert_eq!(session.info(InfoField::EndedEarly), 1);
    assert_eq!(session.read(4800).unwrap(), b"", "the end stays the end");
}

#[test]
fn a_complete_wav_does_not_end_early() {
    let mut session = Session::open_memory(wav(48_000, 2, 4_800), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 4_800);
    assert_eq!(session.info(InfoField::EndedEarly), 0);
}

#[test]
fn a_truncated_adpcm_wav_skips_its_partial_last_block() {
    // The reader hands the decoder a partial last block, which it cannot fill.
    let mut bytes = adpcm_wav(48_000, 6 * ADPCM_BLOCK_FRAMES, 6);

    bytes.truncate(bytes.len() - 500);

    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 5 * ADPCM_BLOCK_FRAMES as usize);
    assert_eq!(session.info(InfoField::SkippedPackets), 1);
}

enum Step {
    /// A packet of the track with this id, holding these bytes.
    Packet(u32, Vec<u8>),
    /// The `UnexpectedEof` I/O error a reader returns when the bytes run out partway through a packet.
    UnexpectedEnd,
}

/// A format reader that plays back a list of steps, then ends.
struct ScriptedReader {
    steps: VecDeque<Step>,
    media_info: symphonia::core::formats::MediaInfo,
    metadata: symphonia::core::meta::MetadataLog,
}

static SCRIPTED_FORMAT_INFO: symphonia::core::formats::FormatInfo = symphonia::core::formats::FormatInfo {
    format: symphonia::core::formats::FormatId::new(symphonia::core::common::FourCc::new(*b"test")),
    short_name: "scripted",
    long_name: "Scripted test reader",
};

impl FormatReader for ScriptedReader {
    fn format_info(&self) -> &symphonia::core::formats::FormatInfo {
        &SCRIPTED_FORMAT_INFO
    }

    fn media_info(&self) -> &symphonia::core::formats::MediaInfo {
        &self.media_info
    }

    fn metadata(&mut self) -> symphonia::core::meta::Metadata<'_> {
        self.metadata.metadata()
    }

    fn seek(
        &mut self,
        _mode: symphonia::core::formats::SeekMode,
        _to: symphonia::core::formats::SeekTo,
    ) -> symphonia::core::errors::Result<symphonia::core::formats::SeekedTo> {
        Err(SymphoniaError::Unsupported("the scripted reader cannot seek"))
    }

    fn tracks(&self) -> &[Track] {
        &[]
    }

    fn next_packet(&mut self) -> symphonia::core::errors::Result<Option<Packet>> {
        match self.steps.pop_front() {
            Some(Step::Packet(track_id, data)) => Ok(Some(Packet::new(
                track_id,
                symphonia::core::units::Timestamp::new(0),
                symphonia::core::units::Duration::new(960),
                data,
            ))),
            Some(Step::UnexpectedEnd) => Err(SymphoniaError::IoError(std::io::Error::new(
                std::io::ErrorKind::UnexpectedEof,
                "unexpected end of file",
            ))),
            None => Ok(None),
        }
    }

    fn into_inner<'source>(self: Box<Self>) -> MediaSourceStream<'source>
    where
        Self: 'source,
    {
        MediaSourceStream::new(Box::new(Cursor::new(Vec::new())), MediaSourceStreamOptions::default())
    }
}

/// An Opus session over a `ScriptedReader` whose chosen track is track 1.
fn scripted_opus_session(steps: impl IntoIterator<Item = Step>) -> Session {
    let reader = ScriptedReader {
        steps: steps.into_iter().collect(),
        media_info: symphonia::core::formats::MediaInfo::default(),
        metadata: symphonia::core::meta::MetadataLog::default(),
    };

    Session {
        demuxer: Demuxer::new(Box::new(reader), 1),
        output: Output::Opus,
        sample_rate: 48_000,
        channel_count: Some(2),
        codec_name: OPUS_CODEC_NAME,
        container_name: "scripted",
        duration_milliseconds: None,
        ended: false,
        failure: None,
    }
}

#[test]
fn read_packet_ends_cleanly_at_an_unexpected_end_of_file() {
    let mut session = scripted_opus_session([
        Step::Packet(1, opus_packet(10)),
        Step::UnexpectedEnd,
        Step::Packet(1, opus_packet(20)),
    ]);

    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&opus_packet(10)[..]));
    assert_eq!(session.read_packet(8000).unwrap(), None);
    assert_eq!(session.info(InfoField::EndedEarly), 0, "Opus is passed through, not decoded, so it is never flagged");
    assert_eq!(session.read_packet(8000).unwrap(), None, "the end stays the end");
}

#[test]
fn packets_of_other_tracks_count_toward_the_run_of_skips() {
    let other = || Step::Packet(2, opus_packet(5));
    let mut allowed: Vec<Step> = (0..10_000).map(|_| other()).collect();

    allowed.push(Step::Packet(1, opus_packet(10)));

    let mut session = scripted_opus_session(allowed);

    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&opus_packet(10)[..]));
    assert_eq!(session.info(InfoField::SkippedPackets), 0, "other tracks are passed over, not counted as skipped");

    let mut session = scripted_opus_session((0..10_001).map(|_| other()));

    assert_eq!(
        session.read_packet(8000).err().unwrap().to_string(),
        "the audio has more than 10000 undecodable packets in a row"
    );
}

#[test]
fn other_track_and_empty_packets_share_one_run() {
    let steps =
        (0..5_000).map(|_| Step::Packet(2, opus_packet(5))).chain((0..5_001).map(|_| Step::Packet(1, Vec::new())));
    let mut session = scripted_opus_session(steps);

    assert_eq!(
        session.read_packet(8000).err().unwrap().to_string(),
        "the audio has more than 10000 undecodable packets in a row"
    );
}

/// A fixture of the Luau package, made by `tests/fixtures/generate.sh`.
fn fixture(name: &str) -> Vec<u8> {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("../tests/fixtures").join(name);

    std::fs::read(&path).unwrap_or_else(|failure| panic!("{}: {failure}", path.display()))
}

fn cut(mut bytes: Vec<u8>, percent: usize) -> Vec<u8> {
    bytes.truncate(bytes.len() * percent / 100);
    bytes
}

#[test]
fn a_flac_cut_before_its_first_frame_ends_early() {
    // The FLAC reader returns the end, not an error, when it runs out before a packet.
    let mut session = Session::open_memory(cut(fixture("tone.flac"), 60), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 0);
    assert_eq!(session.info(InfoField::EndedEarly), 1);
}

#[test]
fn a_flac_cut_late_ends_early() {
    let mut session = Session::open_memory(cut(fixture("tone.flac"), 90), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert!(left.len() < 24_000, "{} frames", left.len());
    assert_eq!(session.info(InfoField::EndedEarly), 1);
}

#[test]
fn a_streaming_wav_with_no_stated_length_does_not_end_early() {
    // ffmpeg writing to a pipe cannot go back to fill in the sizes, so it leaves 0xFFFFFFFF.
    let mut bytes = wav(22_050, 2, 11_025);

    bytes[4..8].copy_from_slice(&u32::MAX.to_le_bytes());
    bytes[40..44].copy_from_slice(&u32::MAX.to_le_bytes());

    let mut session = Session::open_memory(bytes, None).unwrap();

    assert_eq!(session.info(InfoField::DurationMilliseconds), -1, "no stated length");

    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 24_000, "it plays to its end");
    assert_eq!(session.info(InfoField::EndedEarly), 0);
}

#[test]
fn a_wav_whose_data_size_is_zero_does_not_end_early() {
    // Symphonia takes a data size of 0 as a stated length of 0 frames, so it reads nothing.
    let mut bytes = wav(22_050, 2, 11_025);

    bytes[40..44].copy_from_slice(&0_u32.to_le_bytes());

    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 0);
    assert_eq!(session.info(InfoField::EndedEarly), 0);
}

/// The Luau package's fixtures that decode to PCM.
const DECODED_FIXTURES: [&str; 14] = [
    "tone.wav",
    "tone-mono.wav",
    "tone-adpcm.wav",
    "tone.mp3",
    "tone.mp2",
    "tone.flac",
    "layout-51.flac",
    "tone.ogg",
    "tone.aac",
    "tone.m4a",
    "tone-alac.m4a",
    "tone.aiff",
    "tone.caf",
    "tone-vorbis.webm",
];

#[test]
fn complete_files_do_not_end_early() {
    for name in DECODED_FIXTURES {
        let mut session = Session::open_memory(fixture(name), None).unwrap();
        let (left, _) = read_all(&mut session);

        assert!(left.len() > 20_000, "{name}: {} frames", left.len());
        assert_eq!(session.info(InfoField::EndedEarly), 0, "{name}");
    }
}

#[test]
fn a_pcm_fact_chunk_is_ignored() {
    // PCM's length comes from its data; a stale fact chunk must not cut it short.
    let mut session = Session::open_memory(with_fact(wav(48_000, 1, 4_800), 10), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 4_800);
    assert_eq!(session.info(InfoField::DurationMilliseconds), 100);
}

fn fnv1a(bytes: impl IntoIterator<Item = u8>) -> u64 {
    bytes
        .into_iter()
        .fold(0xcbf2_9ce4_8422_2325, |hash, byte| (hash ^ u64::from(byte)).wrapping_mul(0x0000_0100_0000_01b3))
}

/// What the crate's A1-1 snapshot (8b33971a) read from each fixture that never passes full scale, through its limiter
/// at volume 1 and `to_i16`: the frame count and the FNV-1a hash of the interleaved s16le bytes. The overs fixture,
/// which the limiter changed, is left out.
const A1_1_OUTPUT: [(&str, usize, u64); 14] = [
    ("tone.wav", 24_000, 0xbad1_ce28_7268_f945),
    ("tone-mono.wav", 24_000, 0xbca9_74dc_7491_6049),
    ("tone-adpcm.wav", 24_000, 0xf747_5337_96f4_399d),
    ("tone.mp3", 24_000, 0x4661_fc2d_1cdc_e981),
    ("tone.mp2", 25_078, 0x4e1d_ce5a_a6f7_255d),
    ("tone.flac", 24_000, 0xcd2a_5c41_0b6a_6915),
    ("layout-51.flac", 24_000, 0x9138_bf5d_ca45_d7b1),
    ("tone.ogg", 24_000, 0xe29f_3295_12b6_f95d),
    ("tone.aac", 25_635, 0xe672_efef_8823_75b4),
    ("tone.m4a", 25_115, 0xbb82_9e35_0af9_c0cb),
    ("tone-alac.m4a", 24_000, 0x37b6_7759_d8c1_faf5),
    ("tone.aiff", 24_003, 0x751e_2abb_9373_632d),
    ("tone.caf", 24_000, 0x2378_6846_e03a_f529),
    ("tone-vorbis.webm", 24_033, 0xb110_02ac_b818_fe95),
];

#[test]
fn float_reads_with_the_plain_conversion_give_the_a1_1_output() {
    assert_eq!(A1_1_OUTPUT.map(|(name, _, _)| name), DECODED_FIXTURES, "every decoded fixture");

    for (name, frames, hash) in A1_1_OUTPUT {
        let mut session = Session::open_memory(fixture(name), None).unwrap();
        let (left, right) = read_all(&mut session);
        let bytes =
            left.iter().zip(&right).flat_map(|(left, right)| [left.to_le_bytes(), right.to_le_bytes()]).flatten();

        assert_eq!(left.len(), frames, "{name}");
        assert_eq!(fnv1a(bytes), hash, "{name}");
    }
}

#[test]
fn reads_are_the_decoded_floats_untouched() {
    // A 48 kHz float WAV comes out bit for bit, +6 dBFS peaks included: nothing in the crate scales, limits or clamps.
    let overs = stereo_sine(48_000, 24_000, 2.0);
    let mut session = Session::open_memory(float_wav(48_000, 2, &overs), None).unwrap();
    let read = read_floats(&mut session, 4_800);

    assert_eq!(
        read.iter().map(|sample| sample.to_bits()).collect::<Vec<_>>(),
        overs.iter().map(|sample| sample.to_bits()).collect::<Vec<_>>()
    );

    // A 48 kHz s16 WAV comes out as each sample over 32768, -32768 and 32767 included.
    let mut samples: Vec<i16> = (0..9_600).map(|index| (index * 7_919 % 65_536) as u16 as i16).collect();

    samples[..4].copy_from_slice(&[i16::MIN, i16::MAX, i16::MAX, i16::MIN]);

    let mut session = Session::open_memory(s16_wav(48_000, 2, &samples), None).unwrap();
    let expected: Vec<f32> = samples.iter().map(|&sample| f32::from(sample) / 32_768.0).collect();

    assert_eq!(read_floats(&mut session, 4_800), expected);
}

#[test]
fn short_audio_keeps_its_length_at_any_read_size() {
    for frames in [1, 2, 5, 100, 239, 240, 241, 481] {
        let mut samples: Vec<i16> = (0..frames * 2).map(|index| (index * 7_919 % 65_536) as u16 as i16).collect();

        samples[0] = i16::MIN;
        samples[1] = i16::MAX;

        let resampled = s16_wav(44_100, 2, &samples);
        let expected = read_all(&mut Session::open_memory(resampled.clone(), None).unwrap());

        assert_eq!(expected.0.len(), (frames as u64 * 48_000).div_ceil(44_100) as usize, "{frames} frames at 44.1 kHz");

        for capacity in [1, 7, 4_800] {
            let context = format!("{frames} frames, read {capacity} at a time");
            let mut session = Session::open_memory(s16_wav(48_000, 2, &samples), None).unwrap();
            let (left, right) = read_all_in(&mut session, capacity);
            let interleaved: Vec<i16> = left.iter().zip(&right).flat_map(|(&left, &right)| [left, right]).collect();

            assert_eq!(interleaved, samples, "{context} at 48 kHz");
            assert_eq!(session.read(capacity).unwrap(), b"", "{context}");

            let mut session = Session::open_memory(resampled.clone(), None).unwrap();

            assert_eq!(read_all_in(&mut session, capacity), expected, "{context} at 44.1 kHz");
        }
    }
}

#[test]
fn a_session_is_open_until_a_read_reaches_the_end() {
    let mut session = Session::open_memory(wav(48_000, 2, 4_800), None).unwrap();

    assert_eq!(session.info(InfoField::State), State::Open as i32);
    assert_eq!(session.read(4_800).unwrap().len(), 4_800 * BYTES_PER_FRAME);
    assert_eq!(session.info(InfoField::State), State::Open as i32, "the last frames are not yet the end");
    assert_eq!(session.read(4_800).unwrap(), b"");
    assert_eq!(session.info(InfoField::State), State::Ended as i32);

    let packets = vec![opus_packet(10)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(session.info(InfoField::State), State::Open as i32);
    assert_eq!(read_packets(&mut session).len(), 1);
    assert_eq!(session.info(InfoField::State), State::Ended as i32);
}

#[test]
fn a_failed_session_reports_state_3_and_its_failure() {
    let mut session = Session::open_memory(wav(48_000, 2, 100), None).unwrap();

    assert_eq!(session.describe(DescribeField::Failure), "");

    session.mark_failed(Error::Panicked(Some("a deliberate failure".to_string())));
    session.mark_failed(Error::Panicked(Some("a later failure".to_string())));

    assert_eq!(session.info(InfoField::State), State::Failed as i32);
    assert_eq!(session.info(InfoField::IsFailed), 1);
    assert_eq!(
        session.describe(DescribeField::Failure),
        "symphonia wrapper panicked: a deliberate failure",
        "the first failure is kept"
    );
}
