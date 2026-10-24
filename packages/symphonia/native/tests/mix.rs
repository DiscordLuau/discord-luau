use discord_luau_symphonia::testing::decode_with;
use discord_luau_symphonia::{BYTES_PER_FRAME, OUTPUT_CHANNELS, StereoMix};
use symphonia::core::audio::{AudioBuffer, AudioSpec, Channels, GenericAudioBufferRef, Position, layouts};
use symphonia::core::codecs::CodecInfo;
use symphonia::core::codecs::audio::{AudioCodecParameters, AudioDecoder, FinalizeResult};
use symphonia::core::errors::Result as SymphoniaResult;
use symphonia::core::formats::{FormatReader, TrackType};
use symphonia::core::packet::PacketRef;

use crate::util::Replay;

const MINUS_3_DB: f32 = std::f32::consts::FRAC_1_SQRT_2;
const OPPOSITE_CENTRE: f32 = 1.0 - MINUS_3_DB;
const REAR_CENTRE: f32 = 0.5;
const RELAYOUT_FRAMES: usize = 4;
const STEREO_VALUES: [f32; 2] = [0.25, -0.5];
const FIVE_ONE_VALUES: [f32; 6] = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6];
const RELAYOUT_INFO: CodecInfo = CodecInfo { short_name: "relayout", long_name: "relayout", profiles: &[] };

struct Relayout {
    parameters: AudioCodecParameters,
    buffers: [AudioBuffer<f32>; 2],
    decoded: usize,
}

impl Relayout {
    fn stereo_then_five_one() -> Self {
        Self {
            parameters: AudioCodecParameters::default(),
            buffers: [
                constant_buffer(layouts::CHANNEL_LAYOUT_STEREO, &STEREO_VALUES),
                constant_buffer(layouts::CHANNEL_LAYOUT_5P1, &FIVE_ONE_VALUES),
            ],
            decoded: 0,
        }
    }
}

impl AudioDecoder for Relayout {
    fn reset(&mut self) {}

    fn codec_info(&self) -> &CodecInfo {
        &RELAYOUT_INFO
    }

    fn codec_params(&self) -> &AudioCodecParameters {
        &self.parameters
    }

    fn decode_ref(&mut self, _packet: &PacketRef<'_>) -> SymphoniaResult<GenericAudioBufferRef<'_>> {
        let index = self.decoded.min(1);

        self.decoded += 1;

        Ok((&self.buffers[index]).into())
    }

    fn finalize(&mut self) -> FinalizeResult {
        FinalizeResult::default()
    }

    fn last_decoded(&self) -> GenericAudioBufferRef<'_> {
        (&self.buffers[self.decoded.saturating_sub(1).min(1)]).into()
    }
}

fn constant_buffer(channels: Channels, values: &[f32]) -> AudioBuffer<f32> {
    let mut buffer = AudioBuffer::new(AudioSpec::new(48_000, channels), RELAYOUT_FRAMES);

    buffer.render(None, values);
    buffer
}

fn fresh_mix(channels: &Channels, values: &[f32]) -> Vec<f32> {
    let planes: Vec<Vec<f32>> = values.iter().map(|&value| vec![value; RELAYOUT_FRAMES]).collect();
    let mut output = Vec::new();

    StereoMix::for_channels(channels, planes.len()).apply(&planes, RELAYOUT_FRAMES, &mut output);
    output
}

fn mix_frame(channels: &Channels, values: &[f32]) -> (f32, f32) {
    let planes: Vec<Vec<f32>> = values.iter().map(|&value| vec![value]).collect();
    let mix = StereoMix::for_channels(channels, planes.len());
    let mut output = Vec::new();

    mix.apply(&planes, 1, &mut output);

    (output[0], output[1])
}

fn only(channels: &Channels, active: Position) -> Vec<f32> {
    let index = channels.get_canonical_index_for_positioned_channel(active).unwrap();
    let mut values = vec![0.0; channels.count()];

    values[index] = 1.0;
    values
}

fn close(actual: f32, expected: f32) -> bool {
    (actual - expected).abs() < 1e-5
}

#[test]
fn mono_is_duplicated() {
    let (left, right) = mix_frame(&layouts::CHANNEL_LAYOUT_MONO, &[0.25]);

    assert!(close(left, 0.25) && close(right, 0.25));
}

#[test]
fn a_single_side_channel_is_duplicated() {
    let channels = Channels::Positioned(Position::FRONT_LEFT);
    let (left, right) = mix_frame(&channels, &[0.5]);

    assert!(close(left, 0.5) && close(right, 0.5));
}

#[test]
fn stereo_passes_through() {
    let (left, right) = mix_frame(&layouts::CHANNEL_LAYOUT_STEREO, &[0.25, -0.75]);

    assert!(close(left, 0.25) && close(right, -0.75));
}

#[test]
fn five_one_uses_the_coefficient_table() {
    let channels = layouts::CHANNEL_LAYOUT_5P1;
    let left_total = 1.0 + MINUS_3_DB + MINUS_3_DB;

    let (left, right) = mix_frame(&channels, &only(&channels, Position::FRONT_LEFT));
    assert!(close(left, 1.0 / left_total) && close(right, 0.0));

    let (left, right) = mix_frame(&channels, &only(&channels, Position::FRONT_CENTER));
    assert!(close(left, MINUS_3_DB / left_total) && close(right, MINUS_3_DB / left_total));

    let (left, right) = mix_frame(&channels, &only(&channels, Position::LFE1));
    assert!(close(left, 0.0) && close(right, 0.0), "LFE is dropped");

    let (left, right) = mix_frame(&channels, &only(&channels, Position::REAR_RIGHT));
    assert!(close(left, 0.0) && close(right, MINUS_3_DB / left_total));
}

#[test]
fn five_one_keeps_distinct_channels_apart() {
    let channels = layouts::CHANNEL_LAYOUT_5P1;
    let mut values = only(&channels, Position::FRONT_LEFT);
    let rear_right = channels.get_canonical_index_for_positioned_channel(Position::REAR_RIGHT);

    values[rear_right.unwrap()] = -1.0;

    let (left, right) = mix_frame(&channels, &values);

    assert!(left > 0.3, "left carries FL");
    assert!(right < -0.2, "right carries RR");
}

#[test]
fn seven_one_uses_both_the_side_and_the_rear_pairs() {
    let channels = layouts::CHANNEL_LAYOUT_7P1;
    let total = 1.0 + MINUS_3_DB * 3.0;

    for (position, expected_left, expected_right) in [
        (Position::SIDE_LEFT, MINUS_3_DB / total, 0.0),
        (Position::REAR_LEFT, MINUS_3_DB / total, 0.0),
        (Position::SIDE_RIGHT, 0.0, MINUS_3_DB / total),
        (Position::REAR_RIGHT, 0.0, MINUS_3_DB / total),
    ] {
        let (left, right) = mix_frame(&channels, &only(&channels, position));

        assert!(close(left, expected_left) && close(right, expected_right), "{position:?}");
    }
}

#[test]
fn front_centre_pairs_and_rear_centre_split() {
    let channels = Channels::Positioned(
        Position::FRONT_LEFT
            | Position::FRONT_RIGHT
            | Position::FRONT_LEFT_CENTER
            | Position::FRONT_RIGHT_CENTER
            | Position::REAR_CENTER,
    );
    let total = 1.0 + MINUS_3_DB + OPPOSITE_CENTRE + REAR_CENTRE;

    let (left, right) = mix_frame(&channels, &only(&channels, Position::FRONT_LEFT_CENTER));
    assert!(close(left, MINUS_3_DB / total) && close(right, OPPOSITE_CENTRE / total));

    let (left, right) = mix_frame(&channels, &only(&channels, Position::REAR_CENTER));
    assert!(close(left, REAR_CENTRE / total) && close(right, REAR_CENTRE / total));
}

#[test]
fn top_and_wide_positions_follow_their_side() {
    let channels = Channels::Positioned(
        Position::FRONT_LEFT
            | Position::FRONT_RIGHT
            | Position::TOP_FRONT_LEFT
            | Position::FRONT_RIGHT_WIDE
            | Position::TOP_REAR_LEFT,
    );

    let (left, right) = mix_frame(&channels, &only(&channels, Position::TOP_FRONT_LEFT));
    assert!(left > 0.0 && close(right, 0.0));

    let (left, right) = mix_frame(&channels, &only(&channels, Position::FRONT_RIGHT_WIDE));
    assert!(close(left, 0.0) && right > 0.0);

    let (left, right) = mix_frame(&channels, &only(&channels, Position::TOP_REAR_LEFT));
    assert!(left > 0.0 && close(right, 0.0));
}

#[test]
fn full_scale_cannot_clip() {
    let layouts = [
        layouts::CHANNEL_LAYOUT_5P1,
        layouts::CHANNEL_LAYOUT_7P1,
        Channels::Positioned(Position::from_bits_retain((1 << 26) - 1)),
        Channels::Ambisonic(1),
        Channels::Discrete(6),
    ];

    for channels in &layouts {
        for value in [1.0_f32, -1.0] {
            let (left, right) = mix_frame(channels, &vec![value; channels.count()]);

            assert!(left.abs() <= 1.0 + 1e-6 && right.abs() <= 1.0 + 1e-6, "{channels}");
            assert!(close(left.abs(), 1.0) && close(right.abs(), 1.0), "{channels}");
        }

        let values: Vec<f32> = (0..channels.count()).map(|index| if index % 2 == 0 { 1.0 } else { -1.0 }).collect();
        let (left, right) = mix_frame(channels, &values);

        assert!(left.abs() <= 1.0 + 1e-6 && right.abs() <= 1.0 + 1e-6, "{channels}");
    }
}

#[test]
fn ambisonic_uses_w_as_mono() {
    let mut values = vec![0.0; 4];
    values[0] = 0.5;
    values[1] = 1.0;

    let (left, right) = mix_frame(&Channels::Ambisonic(1), &values);

    assert!(close(left, 0.5) && close(right, 0.5));
}

#[test]
fn discrete_uses_the_first_two_channels() {
    let (left, right) = mix_frame(&Channels::Discrete(4), &[0.1, 0.2, 0.3, 0.4]);

    assert!(close(left, 0.1) && close(right, 0.2));

    let (left, right) = mix_frame(&Channels::Discrete(1), &[0.3]);

    assert!(close(left, 0.3) && close(right, 0.3));
}

#[test]
fn custom_uses_the_first_two_channels() {
    let channels = Channels::Custom(Box::new([
        Position::REAR_CENTER.into(),
        Position::FRONT_CENTER.into(),
        Position::LFE1.into(),
    ]));
    let (left, right) = mix_frame(&channels, &[0.1, 0.2, 0.3]);

    assert!(close(left, 0.1) && close(right, 0.2));
}

#[test]
fn none_uses_the_buffers_planes() {
    let (left, right) = mix_frame(&Channels::None, &[0.1, 0.2]);

    assert!(close(left, 0.1) && close(right, 0.2));

    let mix = StereoMix::for_channels(&Channels::None, 0);
    let mut output = Vec::new();

    mix.apply(&[], 3, &mut output);

    assert_eq!(output, vec![0.0; 6], "no planes keep the length as silence");
}

#[test]
fn lfe_only_falls_back_to_the_first_planes() {
    let channels = Channels::Positioned(Position::LFE1 | Position::LFE2);
    let (left, right) = mix_frame(&channels, &[0.1, 0.2]);

    assert!(close(left, 0.1) && close(right, 0.2));
}

#[test]
fn a_layout_with_one_side_only_feeds_both() {
    let channels = Channels::Positioned(Position::FRONT_LEFT | Position::SIDE_LEFT);
    let (left, right) = mix_frame(&channels, &[1.0, 0.0]);
    let expected = 1.0 / (1.0 + MINUS_3_DB);

    assert!(close(left, expected) && close(right, expected));
}

#[test]
fn a_layout_change_mid_stream_mixes_with_the_new_layouts_table() {
    let replay = Replay::demux("tone.flac");
    let track_id = replay.default_track(TrackType::Audio).unwrap().id;
    let codec = Box::new(Relayout::stereo_then_five_one());
    let mut output = vec![0_u8; 4_096 * BYTES_PER_FRAME];
    let frames = decode_with(codec, Box::new(replay), track_id, 48_000, &mut output).unwrap();
    let samples: Vec<f32> =
        output[..frames * BYTES_PER_FRAME].as_chunks::<4>().0.iter().map(|&bytes| f32::from_le_bytes(bytes)).collect();
    let packet_samples = RELAYOUT_FRAMES * OUTPUT_CHANNELS;

    assert_eq!(&samples[..packet_samples], fresh_mix(&layouts::CHANNEL_LAYOUT_STEREO, &STEREO_VALUES).as_slice());
    assert_eq!(
        &samples[packet_samples..2 * packet_samples],
        fresh_mix(&layouts::CHANNEL_LAYOUT_5P1, &FIVE_ONE_VALUES).as_slice()
    );
}

#[test]
fn an_infinite_lfe_sample_leaves_the_mix_unchanged() {
    let channels = layouts::CHANNEL_LAYOUT_5P1;
    let lfe = channels.get_canonical_index_for_positioned_channel(Position::LFE1).unwrap();
    let mut values = FIVE_ONE_VALUES.to_vec();

    values[lfe] = 0.0;

    let silent_lfe = mix_frame(&channels, &values);

    values[lfe] = f32::INFINITY;

    let infinite_lfe = mix_frame(&channels, &values);

    assert!(silent_lfe.0.is_finite() && silent_lfe.1.is_finite());
    assert_eq!(infinite_lfe, silent_lfe);
}

#[test]
fn a_mix_of_no_planes_appends_negative_zero() {
    let mut output = Vec::new();

    StereoMix::for_channels(&Channels::None, 0).apply(&[], 3, &mut output);

    assert_eq!(output.iter().map(|sample| sample.to_bits()).collect::<Vec<_>>(), vec![(-0.0_f32).to_bits(); 6]);
}
