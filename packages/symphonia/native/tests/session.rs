//! Sessions over synthetic files and the Luau package's fixtures, and the limits and `fact` chunks they open with.

#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    clippy::cast_precision_loss,
    clippy::cast_sign_loss,
    reason = "the builders write header fields and samples of known small values"
)]

use discord_luau_symphonia::limits::{check_packet_size, check_sample_rate_and_channels};
use discord_luau_symphonia::testing::set_sample_rate;
use discord_luau_symphonia::wav::fact_frames;
use discord_luau_symphonia::{BYTES_PER_FRAME, DescribeField, Error, Session, State};

use crate::files::{
    ADPCM_BLOCK_FRAMES, adpcm_wav, aiff, caf_lpcm, corrupted_adpcm_wav, fixture, float_wav, ogg_opus, opus_packet,
    s16_wav, stereo_sine, wav, wav_with, with_fact,
};
use crate::util::read_packets;

/// Ten times the longest audio these tests make.
const READ_ALL_MAX_FRAMES: usize = 480_000;

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
        assert_eq!(session.info().sample_rate, rate);
        assert_eq!(session.info().channels, Some(usize::from(channels)));
        assert_eq!(session.info().duration_milliseconds, Some(500));
    }
}

#[test]
fn a_wav_names_its_codec_and_container() {
    let session = Session::open_memory(wav(44_100, 2, 100), Some("wav")).unwrap();

    assert_eq!(session.describe(DescribeField::Codec), "pcm_s16le");
    assert_eq!(session.describe(DescribeField::Container), "wave");
    assert!(!session.info().is_opus);
    assert_eq!(session.state(), State::Open);
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

    assert_eq!(session.info().channels, Some(4));
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
    assert_eq!(session.info().duration_milliseconds, Some(500));

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
    assert_eq!(session.info().duration_milliseconds, Some(500));
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

#[test]
fn a_decoded_rate_that_differs_from_the_tracks_is_an_error() {
    let mut session = Session::open_memory(wav(48_000, 2, 1_000), None).unwrap();

    set_sample_rate(&mut session, 44_100);

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
    assert_eq!(session.info().skipped_packets, 1);
}

#[test]
fn ten_thousand_undecodable_packets_in_a_row_are_allowed() {
    let bytes = corrupted_adpcm_wav(10_001, 0..10_000);
    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), ADPCM_BLOCK_FRAMES as usize);
    assert_eq!(session.info().skipped_packets, 10_000);
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
    assert_eq!(session.info().skipped_packets, 12_000);
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
    assert!(session.info().ended_early);
    assert_eq!(session.read(4800).unwrap(), b"", "the end stays the end");
}

#[test]
fn a_complete_wav_does_not_end_early() {
    let mut session = Session::open_memory(wav(48_000, 2, 4_800), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 4_800);
    assert!(!session.info().ended_early);
}

#[test]
fn a_truncated_adpcm_wav_skips_its_partial_last_block() {
    // The reader hands the decoder a partial last block, which it cannot fill.
    let mut bytes = adpcm_wav(48_000, 6 * ADPCM_BLOCK_FRAMES, 6);

    bytes.truncate(bytes.len() - 500);

    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 5 * ADPCM_BLOCK_FRAMES as usize);
    assert_eq!(session.info().skipped_packets, 1);
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
    assert!(session.info().ended_early);
}

#[test]
fn a_flac_cut_late_ends_early() {
    let mut session = Session::open_memory(cut(fixture("tone.flac"), 90), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert!(left.len() < 24_000, "{} frames", left.len());
    assert!(session.info().ended_early);
}

#[test]
fn a_streaming_wav_with_no_stated_length_does_not_end_early() {
    // ffmpeg writing to a pipe cannot go back to fill in the sizes, so it leaves 0xFFFFFFFF.
    let mut bytes = wav(22_050, 2, 11_025);

    bytes[4..8].copy_from_slice(&u32::MAX.to_le_bytes());
    bytes[40..44].copy_from_slice(&u32::MAX.to_le_bytes());

    let mut session = Session::open_memory(bytes, None).unwrap();

    assert_eq!(session.info().duration_milliseconds, None, "no stated length");

    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 24_000, "it plays to its end");
    assert!(!session.info().ended_early);
}

#[test]
fn a_wav_whose_data_size_is_zero_does_not_end_early() {
    // Symphonia takes a data size of 0 as a stated length of 0 frames, so it reads nothing.
    let mut bytes = wav(22_050, 2, 11_025);

    bytes[40..44].copy_from_slice(&0_u32.to_le_bytes());

    let mut session = Session::open_memory(bytes, None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 0);
    assert!(!session.info().ended_early);
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
        assert!(!session.info().ended_early, "{name}");
    }
}

#[test]
fn a_pcm_fact_chunk_is_ignored() {
    // PCM's length comes from its data; a stale fact chunk must not cut it short.
    let mut session = Session::open_memory(with_fact(wav(48_000, 1, 4_800), 10), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 4_800);
    assert_eq!(session.info().duration_milliseconds, Some(100));
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

    assert_eq!(session.state(), State::Open);
    assert_eq!(session.read(4_800).unwrap().len(), 4_800 * BYTES_PER_FRAME);
    assert_eq!(session.state(), State::Open, "the last frames are not yet the end");
    assert_eq!(session.read(4_800).unwrap(), b"");
    assert_eq!(session.state(), State::Ended);

    let packets = vec![opus_packet(10)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(session.state(), State::Open);
    assert_eq!(read_packets(&mut session).len(), 1);
    assert_eq!(session.state(), State::Ended);
}

#[test]
fn a_failed_session_reports_state_3_and_its_failure() {
    let mut session = Session::open_memory(wav(48_000, 2, 100), None).unwrap();

    assert_eq!(session.describe(DescribeField::Failure), "");

    session.mark_failed(Error::Panicked(Some("a deliberate failure".to_string())));
    session.mark_failed(Error::Panicked(Some("a later failure".to_string())));

    assert_eq!(session.state(), State::Failed);
    assert_eq!(
        session.describe(DescribeField::Failure),
        "symphonia wrapper panicked: a deliberate failure",
        "the first failure is kept"
    );
}

#[test]
fn the_sample_rate_limits_hold() {
    assert_eq!(check_sample_rate_and_channels(Some(1_000), Some(1)), Ok(1_000));
    assert_eq!(check_sample_rate_and_channels(Some(384_000), Some(32)), Ok(384_000));
    assert_eq!(check_sample_rate_and_channels(Some(48_000), None), Ok(48_000));

    for rate in [0, 1, 999, 384_001, 2_147_483_647, u32::MAX] {
        let failure = check_sample_rate_and_channels(Some(rate), Some(2)).unwrap_err().to_string();

        assert!(failure.contains(&format!("{rate} Hz")), "{failure}");
        assert!(failure.contains("1000 to 384000 Hz"), "{failure}");
    }

    assert_eq!(check_sample_rate_and_channels(None, Some(2)), Err(Error::UnknownSampleRate));
}

#[test]
fn the_channel_limits_hold() {
    for count in [0, 33, 255] {
        let failure = check_sample_rate_and_channels(Some(48_000), Some(count)).unwrap_err().to_string();

        assert!(failure.contains(&format!("{count}")) && failure.contains("1 to 32"), "{failure}");
    }
}

#[test]
fn the_packet_size_limit_holds() {
    assert_eq!(check_packet_size(None, None), Ok(()));
    assert_eq!(check_packet_size(Some(262_144), Some(262_144)), Ok(()));
    assert_eq!(
        check_packet_size(Some(262_145), None).unwrap_err().to_string(),
        "the audio declares packets of 262145 frames; at most 262144 are supported"
    );
    assert_eq!(
        check_packet_size(None, Some(262_145)).unwrap_err().to_string(),
        "the audio declares blocks of 262145 frames; at most 262144 are supported"
    );
    assert!(Session::open_memory(caf_lpcm(262_144), None).is_ok());
}

#[test]
fn the_fact_chunk_is_found() {
    assert_eq!(fact_frames(&adpcm_wav(22_050, 11_025, 6)), Some(11_025));
    assert_eq!(fact_frames(&with_fact(wav(8_000, 1, 10), 7)), Some(7));
    assert_eq!(fact_frames(&wav(8_000, 1, 10)), None, "no fact chunk");
    assert_eq!(fact_frames(b"OggS not a wav file"), None);
    assert_eq!(fact_frames(&adpcm_wav(22_050, 11_025, 6)[..50]), None, "truncated");

    // An odd-sized chunk is padded to an even length before the next one.
    let mut padded = Vec::from(&b"RIFF\0\0\0\0WAVEodd \x03\0\0\0abc\0"[..]);

    padded.extend_from_slice(b"fact\x04\0\0\0\x2a\0\0\0");

    assert_eq!(fact_frames(&padded), Some(42));
}

#[test]
fn frames_beyond_the_stated_count_are_dropped() {
    // One ADPCM block of 2041 frames whose `fact` chunk says 600, at 48 kHz so nothing is resampled.
    let mut session = Session::open_memory(adpcm_wav(48_000, 600, 1), None).unwrap();
    let (left, _) = read_all(&mut session);

    assert_eq!(left.len(), 600);
    assert!(!session.info().ended_early, "stopping at the stated length is not early");
}
