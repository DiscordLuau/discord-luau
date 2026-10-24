//! Stereo resampling to 48 kHz with an exact output length: `n` frames at `rate` Hz make `ceil(n * 48000 / rate)`.
//! The resampler's delay is dropped from the start, and the end is flushed in a bounded number of rounds.

use audioadapter_buffers::direct::InterleavedSlice;
use rubato::{Fft, FixedSync, Indexing, Resampler};

use crate::error::Error;
use crate::mix::OUTPUT_CHANNELS;

const OUTPUT_SAMPLE_RATE: u32 = 48_000;
const CHUNK_FRAMES: usize = 1024;
const CHUNK_SAMPLES: usize = CHUNK_FRAMES * OUTPUT_CHANNELS;

pub struct StereoResampler {
    source_rate: u32,
    /// `None` at 48 kHz, where the input passes through.
    fft: Option<Fft<f32>>,
    pending: Vec<f32>,
    scratch: Vec<f32>,
    input_frames: u64,
    trim: Trim,
    finished: bool,
}

/// What comes off the output: the resampler's delay from the start, and anything past the expected length.
struct Trim {
    delay_remaining: usize,
    output_frames: u64,
}

impl StereoResampler {
    /// `source_rate` must not be 0.
    pub fn new(source_rate: u32) -> Result<Self, Error> {
        let fft = if source_rate == OUTPUT_SAMPLE_RATE {
            None
        } else {
            let fft = Fft::<f32>::new(
                source_rate as usize,
                OUTPUT_SAMPLE_RATE as usize,
                CHUNK_FRAMES,
                OUTPUT_CHANNELS,
                FixedSync::Input,
            )
            .map_err(|failure| Error::ResamplerUnavailable { source_rate, detail: failure.to_string() })?;

            Some(fft)
        };
        let delay = fft.as_ref().map_or(0, Resampler::output_delay);

        Ok(Self {
            source_rate,
            fft,
            pending: Vec::new(),
            scratch: Vec::new(),
            input_frames: 0,
            trim: Trim::new(delay),
            finished: false,
        })
    }

    /// Takes interleaved stereo `input`, and appends the output that is ready to `output`.
    pub fn push(&mut self, input: &[f32], output: &mut Vec<f32>) -> Result<(), Error> {
        self.input_frames += (input.len() / OUTPUT_CHANNELS) as u64;

        let expected = self.expected_frames();
        let Some(fft) = self.fft.as_mut() else {
            output.extend_from_slice(input);
            self.trim.output_frames += (input.len() / OUTPUT_CHANNELS) as u64;
            return Ok(());
        };

        self.pending.extend_from_slice(input);

        let mut consumed = 0;

        while self.pending.len() - consumed >= CHUNK_SAMPLES {
            let chunk = &self.pending[consumed..consumed + CHUNK_SAMPLES];
            let produced = process(fft, chunk, None, &mut self.scratch)?;

            consumed += CHUNK_SAMPLES;
            self.trim.emit(&self.scratch[..produced * OUTPUT_CHANNELS], expected, output);
        }

        self.pending.drain(..consumed);

        Ok(())
    }

    /// Appends the rest of the output, up to exactly the expected length; later calls do nothing.
    ///
    /// The first round gives the pending input as a partial chunk, and later rounds give silence, for at most
    /// `flush_rounds` rounds.
    pub fn finish(&mut self, output: &mut Vec<f32>) -> Result<(), Error> {
        if self.finished {
            return Ok(());
        }

        self.finished = true;

        let expected = self.expected_frames();
        let Some(fft) = self.fft.as_mut() else {
            return Ok(());
        };
        let rounds = flush_rounds(fft, expected.saturating_sub(self.trim.output_frames), self.trim.delay_remaining);
        let silence = vec![0.0_f32; CHUNK_SAMPLES];

        for _ in 0..rounds {
            if self.trim.output_frames >= expected {
                break;
            }

            let pending_frames = self.pending.len() / OUTPUT_CHANNELS;
            let produced = if pending_frames > 0 {
                let mut chunk = std::mem::take(&mut self.pending);

                chunk.resize(CHUNK_SAMPLES, 0.0);

                let indexing = Indexing { partial_len: Some(pending_frames), ..Indexing::new() };

                process(fft, &chunk, Some(&indexing), &mut self.scratch)?
            } else {
                process(fft, &silence, None, &mut self.scratch)?
            };

            self.trim.emit(&self.scratch[..produced * OUTPUT_CHANNELS], expected, output);
        }

        Ok(())
    }

    fn expected_frames(&self) -> u64 {
        (self.input_frames * u64::from(OUTPUT_SAMPLE_RATE)).div_ceil(u64::from(self.source_rate))
    }
}

impl Trim {
    fn new(delay: usize) -> Self {
        Self { delay_remaining: delay, output_frames: 0 }
    }

    /// Drops what is left of the delay from `produced`, caps the total at `expected` frames, and appends the rest.
    fn emit(&mut self, produced: &[f32], expected: u64, output: &mut Vec<f32>) {
        let produced_frames = produced.len() / OUTPUT_CHANNELS;
        let dropped = self.delay_remaining.min(produced_frames);

        self.delay_remaining -= dropped;

        let room = usize::try_from(expected.saturating_sub(self.output_frames)).unwrap_or(usize::MAX);
        let kept = (produced_frames - dropped).min(room);
        let start = dropped * OUTPUT_CHANNELS;

        output.extend_from_slice(&produced[start..start + kept * OUTPUT_CHANNELS]);
        self.output_frames += kept as u64;
    }
}

/// Runs one round over exactly `CHUNK_FRAMES` frames, and returns the frames written to `scratch`.
fn process(
    fft: &mut Fft<f32>,
    chunk: &[f32],
    indexing: Option<&Indexing>,
    scratch: &mut Vec<f32>,
) -> Result<usize, Error> {
    let capacity = fft.output_frames_max();

    scratch.resize(capacity * OUTPUT_CHANNELS, 0.0);

    let input = InterleavedSlice::new(chunk, OUTPUT_CHANNELS, CHUNK_FRAMES)
        .map_err(|failure| Error::ResampleFailed(failure.to_string()))?;
    let mut output = InterleavedSlice::new_mut(scratch.as_mut_slice(), OUTPUT_CHANNELS, capacity)
        .map_err(|failure| Error::ResampleFailed(failure.to_string()))?;
    let (_, produced) = fft
        .process_into_buffer(&input, &mut output, indexing)
        .map_err(|failure| Error::ResampleFailed(failure.to_string()))?;

    Ok(produced)
}

/// Enough rounds for `missing` output frames plus the undropped `delay`, and one more. Every `fft_size_in` input
/// frames make `fft_size_out` output frames, so the count is known in advance.
fn flush_rounds(fft: &Fft<f32>, missing: u64, delay: usize) -> u64 {
    let subchunks = (missing + delay as u64).div_ceil(fft.fft_size_out() as u64);

    (subchunks * fft.fft_size_in() as u64).div_ceil(CHUNK_FRAMES as u64) + 1
}

#[cfg(test)]
mod tests;
