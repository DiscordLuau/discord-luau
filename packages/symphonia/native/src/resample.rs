use audioadapter_buffers::direct::InterleavedSlice;
use rubato::{Fft, FixedSync, Indexing, Resampler};

use crate::error::Error;
use crate::mix::OUTPUT_CHANNELS;

pub(crate) const OUTPUT_SAMPLE_RATE: u32 = 48_000;
pub(crate) const CHUNK_FRAMES: usize = 1024;
const CHUNK_SAMPLES: usize = CHUNK_FRAMES * OUTPUT_CHANNELS;

pub struct StereoResampler {
    source_rate: u32,
    fft: Fft<f32>,
    pending: Vec<f32>,
    scratch: Vec<f32>,
    input_frames: u64,
    pub(crate) trim: Trim,
    finished: bool,
}

pub(crate) struct Trim {
    delay_remaining: usize,
    pub(crate) output_frames: u64,
}

impl StereoResampler {
    pub fn new(source_rate: u32) -> Result<Self, Error> {
        let fft = Fft::<f32>::new(
            source_rate as usize,
            OUTPUT_SAMPLE_RATE as usize,
            CHUNK_FRAMES,
            OUTPUT_CHANNELS,
            FixedSync::Input,
        )
        .map_err(|failure| Error::ResamplerUnavailable { source_rate, detail: failure.to_string() })?;
        let delay = fft.output_delay();
        let pending = Vec::with_capacity(CHUNK_SAMPLES);
        let scratch = vec![0.0; fft.output_frames_max() * OUTPUT_CHANNELS];

        Ok(Self { source_rate, fft, pending, scratch, input_frames: 0, trim: Trim::new(delay), finished: false })
    }

    pub fn push(&mut self, input: &[f32], output: &mut Vec<f32>) -> Result<(), Error> {
        self.input_frames += (input.len() / OUTPUT_CHANNELS) as u64;

        let expected = self.expected_frames();
        let missing = CHUNK_SAMPLES.saturating_sub(self.pending.len()).min(input.len());
        let (head, input) = if self.pending.is_empty() { (&[][..], input) } else { input.split_at(missing) };

        self.pending.extend_from_slice(head);

        if self.pending.len() == CHUNK_SAMPLES {
            let produced = process(&mut self.fft, &self.pending, None, &mut self.scratch)?;

            self.pending.clear();
            self.trim.emit(&self.scratch[..produced * OUTPUT_CHANNELS], expected, output);
        }

        let (chunks, remainder) = input.as_chunks::<CHUNK_SAMPLES>();

        for chunk in chunks {
            let produced = process(&mut self.fft, chunk, None, &mut self.scratch)?;

            self.trim.emit(&self.scratch[..produced * OUTPUT_CHANNELS], expected, output);
        }

        self.pending.extend_from_slice(remainder);

        Ok(())
    }

    pub fn finish(&mut self, output: &mut Vec<f32>) -> Result<(), Error> {
        if self.finished {
            return Ok(());
        }

        self.finished = true;

        let expected = self.expected_frames();
        let mut rounds =
            flush_rounds(&self.fft, expected.saturating_sub(self.trim.output_frames), self.trim.delay_remaining);

        while rounds > 0 && self.trim.output_frames < expected {
            let indexing = Indexing { partial_len: Some(self.pending.len() / OUTPUT_CHANNELS), ..Indexing::new() };
            let produced = process(&mut self.fft, &self.pending, Some(&indexing), &mut self.scratch)?;

            self.pending.clear();
            self.trim.emit(&self.scratch[..produced * OUTPUT_CHANNELS], expected, output);
            rounds -= 1;
        }

        Ok(())
    }

    pub(crate) fn output_frames_max(&self, input_frames: usize) -> usize {
        input_frames.div_ceil(CHUNK_FRAMES) * self.fft.output_frames_max()
    }

    pub(crate) fn expected_frames(&self) -> u64 {
        (self.input_frames * u64::from(OUTPUT_SAMPLE_RATE)).div_ceil(u64::from(self.source_rate))
    }
}

impl Trim {
    fn new(delay: usize) -> Self {
        Self { delay_remaining: delay, output_frames: 0 }
    }

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

fn process(
    fft: &mut Fft<f32>,
    input: &[f32],
    indexing: Option<&Indexing>,
    scratch: &mut [f32],
) -> Result<usize, Error> {
    let capacity = scratch.len() / OUTPUT_CHANNELS;
    let input = InterleavedSlice::new(input, OUTPUT_CHANNELS, input.len() / OUTPUT_CHANNELS)?;
    let mut output = InterleavedSlice::new_mut(scratch, OUTPUT_CHANNELS, capacity)?;
    let (_, produced) = fft.process_into_buffer(&input, &mut output, indexing)?;

    Ok(produced)
}

fn flush_rounds(fft: &Fft<f32>, missing: u64, delay: usize) -> u64 {
    let subchunks = (missing + delay as u64).div_ceil(fft.fft_size_out() as u64);

    (subchunks * fft.fft_size_in() as u64).div_ceil(CHUNK_FRAMES as u64) + 1
}
