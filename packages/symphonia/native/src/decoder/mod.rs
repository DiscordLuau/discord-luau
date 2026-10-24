//! A track decoded to 48 kHz interleaved stereo f32 and trimmed to its playable length. Nothing here scales, limits
//! or clamps a sample.

use std::collections::VecDeque;

use symphonia::core::codecs::audio::AudioDecoder;
use symphonia::core::errors::Error as SymphoniaError;

use crate::demuxer::{Demuxer, is_unexpected_end};
use crate::error::Error;
use crate::mix::{OUTPUT_CHANNELS, StereoMix};
use crate::resample::StereoResampler;

pub const BYTES_PER_FRAME: usize = OUTPUT_CHANNELS * size_of::<f32>();

pub struct Decoder {
    codec: Box<dyn AudioDecoder>,
    resampler: StereoResampler,
    /// The playable frame count, when known; decoded frames past it are dropped.
    frame_limit: Option<u64>,
    decoded_frames: u64,
    ended_early: bool,
    finished: bool,
    planes: Vec<Vec<f32>>,
    stereo: Vec<f32>,
    resampled: Vec<f32>,
    ready: VecDeque<f32>,
    bytes: Vec<u8>,
}

impl Decoder {
    pub fn new(codec: Box<dyn AudioDecoder>, sample_rate: u32, frame_limit: Option<u64>) -> Result<Self, Error> {
        Ok(Self {
            codec,
            resampler: StereoResampler::new(sample_rate)?,
            frame_limit,
            decoded_frames: 0,
            ended_early: false,
            finished: false,
            planes: Vec::new(),
            stereo: Vec::new(),
            resampled: Vec::new(),
            ready: VecDeque::new(),
            bytes: Vec::new(),
        })
    }

    pub fn ended_early(&self) -> bool {
        self.ended_early
    }

    /// Reads up to `capacity_frames` frames as little-endian f32 bytes; an empty result is the end.
    ///
    /// Every decoded buffer must be at the track's `sample_rate`.
    pub fn read(&mut self, demuxer: &mut Demuxer, sample_rate: u32, capacity_frames: usize) -> Result<&[u8], Error> {
        let wanted_samples = capacity_frames.saturating_mul(OUTPUT_CHANNELS);

        while self.ready.len() < wanted_samples && !self.finished {
            self.decode_next(demuxer, sample_rate)?;
        }

        let taken = self.ready.len().min(wanted_samples);

        self.bytes.clear();
        self.bytes.extend(self.ready.drain(..taken).flat_map(f32::to_le_bytes));

        Ok(&self.bytes)
    }

    /// Decodes one packet, or flushes once the track or its playable frames end.
    fn decode_next(&mut self, demuxer: &mut Demuxer, sample_rate: u32) -> Result<(), Error> {
        if self.frame_limit.is_some_and(|limit| self.decoded_frames >= limit) {
            return self.finish();
        }

        let Some(packet) = demuxer.next_packet()? else {
            return self.finish();
        };
        let buffer = match self.codec.decode(&packet) {
            Ok(buffer) => buffer,
            Err(SymphoniaError::DecodeError(_)) => return demuxer.skip(),
            // A packet shorter than its own data says, like a truncated file's last packet, underruns the decoder. It
            // is a bad packet like any other.
            Err(failure) if is_unexpected_end(&failure) => return demuxer.skip(),
            Err(SymphoniaError::ResetRequired) => return Err(Error::StreamChanged),
            Err(failure) => return Err(Error::UndecodablePacket(failure.to_string())),
        };

        demuxer.reset_skips();

        let decoded_rate = buffer.spec().rate();

        if decoded_rate != sample_rate {
            return Err(Error::SampleRateChanged { track_rate: sample_rate, decoded_rate });
        }

        let remaining = self.frame_limit.map_or(u64::MAX, |limit| limit - self.decoded_frames);
        let frames = buffer.frames().min(usize::try_from(remaining).unwrap_or(usize::MAX));
        let mix = StereoMix::for_channels(buffer.spec().channels(), buffer.num_planes());

        buffer.copy_to_vecs_planar::<f32>(&mut self.planes);
        self.decoded_frames += frames as u64;
        self.stereo.clear();
        mix.apply(&self.planes, frames, &mut self.stereo);
        self.resampled.clear();
        self.resampler.push(&self.stereo, &mut self.resampled)?;
        self.ready.extend(&self.resampled);

        Ok(())
    }

    /// Ending short of the playable length, however the container ended, is ending early.
    fn finish(&mut self) -> Result<(), Error> {
        self.finished = true;
        self.ended_early = self.frame_limit.is_some_and(|limit| self.decoded_frames < limit);
        self.resampled.clear();
        self.resampler.finish(&mut self.resampled)?;
        self.ready.extend(&self.resampled);

        Ok(())
    }
}

#[cfg(test)]
mod tests;
