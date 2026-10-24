//! The resampler's exact output length, dropped delay and kept frequency.

#![expect(
    clippy::cast_possible_truncation,
    clippy::cast_precision_loss,
    reason = "the frame counts and rates here are small"
)]

use super::*;

/// Resamples `frames` frames of a 440 Hz tone at `rate`, pushed in packets of `packet_frames`.
fn resample(rate: u32, frames: usize, packet_frames: usize) -> (Vec<f32>, StereoResampler) {
    let mut resampler = StereoResampler::new(rate).unwrap();
    let mut output = Vec::new();
    let input: Vec<f32> = (0..frames)
        .flat_map(|frame| {
            let value = (frame as f32 * 440.0 * std::f32::consts::TAU / rate as f32).sin() * 0.5;
            [value, value]
        })
        .collect();

    for packet in input.chunks(packet_frames.max(1) * OUTPUT_CHANNELS) {
        resampler.push(packet, &mut output).unwrap();
    }

    resampler.finish(&mut output).unwrap();

    (output, resampler)
}

fn expected_length(rate: u32, frames: usize) -> usize {
    (frames as u64 * 48_000).div_ceil(u64::from(rate)) as usize
}

/// Whether the flush reached the expected length before it ran out of rounds.
fn flushed_in_full(resampler: &StereoResampler) -> bool {
    resampler.trim.output_frames >= resampler.expected_frames()
}

#[test]
fn the_output_length_is_exact_for_common_and_odd_rates() {
    for rate in [8_000, 11_025, 22_050, 44_100, 47_999, 48_000] {
        for frames in [1, 100, 1023, 1024, 1025, 4_410, 22_050, 100_003] {
            let (output, resampler) = resample(rate, frames, 1152);

            assert_eq!(output.len() / OUTPUT_CHANNELS, expected_length(rate, frames), "{rate} Hz, {frames} frames");
            assert_eq!(resampler.trim.output_frames as usize, expected_length(rate, frames));
            assert!(flushed_in_full(&resampler), "{rate} Hz, {frames} frames");
        }
    }
}

#[test]
fn no_input_makes_no_output() {
    for rate in [8_000, 44_100, 47_999, 48_000] {
        let (output, resampler) = resample(rate, 0, 1152);

        assert!(output.is_empty(), "{rate} Hz");
        assert!(flushed_in_full(&resampler));
    }
}

#[test]
fn input_shorter_than_the_delay_is_exact() {
    for rate in [8_000, 11_025, 44_100, 47_999] {
        let delay = Fft::<f32>::new(rate as usize, 48_000, CHUNK_FRAMES, OUTPUT_CHANNELS, FixedSync::Input)
            .unwrap()
            .output_delay();
        let frames = (delay as u64 * u64::from(rate) / 48_000).max(2) as usize - 1;
        let (output, resampler) = resample(rate, frames, 64);

        assert!(expected_length(rate, frames) < delay, "{rate} Hz: the case is shorter than the delay");
        assert_eq!(output.len() / OUTPUT_CHANNELS, expected_length(rate, frames), "{rate} Hz");
        assert!(flushed_in_full(&resampler));
    }
}

#[test]
fn the_packet_size_does_not_change_the_length() {
    for packet_frames in [1, 47, 576, 1024, 4096, 100_000] {
        let (output, _) = resample(44_100, 22_050, packet_frames);

        assert_eq!(output.len() / OUTPUT_CHANNELS, 24_000, "packets of {packet_frames}");
    }
}

#[test]
fn the_delay_is_dropped() {
    // A step from silence to 0.5 at frame 0 must start at output frame 0, not after the resampler's delay.
    let mut resampler = StereoResampler::new(44_100).unwrap();
    let mut output = Vec::new();

    resampler.push(&vec![0.5; 44_100 * OUTPUT_CHANNELS], &mut output).unwrap();
    resampler.finish(&mut output).unwrap();

    assert_eq!(output.len() / OUTPUT_CHANNELS, 48_000);
    assert!(output[20 * OUTPUT_CHANNELS] > 0.4, "the step is at the start: {}", output[20 * OUTPUT_CHANNELS]);
    assert!((output[24_000 * OUTPUT_CHANNELS] - 0.5).abs() < 0.01);
}

#[test]
fn a_tone_keeps_its_frequency() {
    let (output, _) = resample(22_050, 22_050, 1152);
    let left: Vec<f32> = output.iter().step_by(OUTPUT_CHANNELS).copied().collect();
    let middle = &left[9_600..38_400];
    let crossings = middle.windows(2).filter(|pair| (pair[0] < 0.0) != (pair[1] < 0.0)).count();
    let frequency = crossings as f32 / 2.0 / (middle.len() as f32 / 48_000.0);

    assert!((frequency - 440.0).abs() < 3.0, "{frequency} Hz");
}

#[test]
fn a_high_coprime_rate_is_exact() {
    let (output, resampler) = resample(383_999, 20_000, 4096);

    assert_eq!(output.len() / OUTPUT_CHANNELS, expected_length(383_999, 20_000));
    assert!(flushed_in_full(&resampler));
}
