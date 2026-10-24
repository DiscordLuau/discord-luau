use symphonia::core::audio::Channels;
use symphonia::core::codecs::audio::AudioDecoder;
use symphonia::core::errors::Error as SymphoniaError;

use crate::demuxer::{Demuxer, is_unexpected_end};
use crate::error::Error;
use crate::mix::{OUTPUT_CHANNELS, StereoMix};
use crate::resample::{OUTPUT_SAMPLE_RATE, StereoResampler};

pub const BYTES_PER_FRAME: usize = OUTPUT_CHANNELS * size_of::<f32>();

pub(crate) struct Decoder {
    codec: Box<dyn AudioDecoder>,
    resampler: Option<StereoResampler>,
    frame_limit: Option<u64>,
    decoded_frames: u64,
    ended_early: bool,
    finished: bool,
    mix: StereoMix,
    mix_layout: Option<(Channels, usize)>,
    packet_samples_max: usize,
    planes: Vec<Vec<f32>>,
    stereo: Vec<f32>,
    ready: Vec<f32>,
    read_offset: usize,
}

impl Decoder {
    pub(crate) fn new(codec: Box<dyn AudioDecoder>, sample_rate: u32, frame_limit: Option<u64>) -> Result<Self, Error> {
        let resampler = match sample_rate {
            OUTPUT_SAMPLE_RATE => None,
            source_rate => Some(StereoResampler::new(source_rate)?),
        };

        Ok(Self {
            codec,
            resampler,
            frame_limit,
            decoded_frames: 0,
            ended_early: false,
            finished: false,
            mix: StereoMix::default(),
            mix_layout: None,
            packet_samples_max: 0,
            planes: Vec::new(),
            stereo: Vec::new(),
            ready: Vec::new(),
            read_offset: 0,
        })
    }

    pub(crate) fn ended_early(&self) -> bool {
        self.ended_early
    }

    pub(crate) fn read(&mut self, demuxer: &mut Demuxer, sample_rate: u32, output: &mut [u8]) -> Result<usize, Error> {
        let wanted_samples = output.len() / BYTES_PER_FRAME * OUTPUT_CHANNELS;

        if self.ready.len() - self.read_offset < wanted_samples {
            self.fill(demuxer, sample_rate, wanted_samples)?;
        }

        let samples = &self.ready[self.read_offset..];
        let taken = samples.len().min(wanted_samples);
        let (words, _) = output.as_chunks_mut::<{ size_of::<f32>() }>();

        for (word, sample) in words.iter_mut().zip(&samples[..taken]) {
            *word = sample.to_le_bytes();
        }

        self.read_offset += taken;

        Ok(taken / OUTPUT_CHANNELS)
    }

    fn fill(&mut self, demuxer: &mut Demuxer, sample_rate: u32, wanted_samples: usize) -> Result<(), Error> {
        self.ready.drain(..self.read_offset);
        self.read_offset = 0;

        while self.ready.len() < wanted_samples && !self.finished {
            self.decode_next(demuxer, sample_rate)?;
        }

        self.ready.reserve((wanted_samples + self.packet_samples_max).saturating_sub(self.ready.len()));

        Ok(())
    }

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
            // A truncated last packet underruns the decoder; skip it like any other bad packet.
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
        let channels = buffer.spec().channels();
        let plane_count = buffer.num_planes();

        if self.mix_layout.as_ref().is_none_or(|(mixed, count)| mixed != channels || *count != plane_count) {
            let capacity = buffer.capacity();
            let output_frames =
                self.resampler.as_ref().map_or(capacity, |resampler| resampler.output_frames_max(capacity));

            self.mix = StereoMix::for_channels(channels, plane_count);
            self.mix_layout = Some((channels.clone(), plane_count));
            self.packet_samples_max = output_frames * OUTPUT_CHANNELS;
        }

        buffer.copy_to_vecs_planar::<f32>(&mut self.planes);
        self.decoded_frames += frames as u64;
        self.append(frames)
    }

    fn append(&mut self, frames: usize) -> Result<(), Error> {
        match &mut self.resampler {
            None => {
                self.mix.apply(&self.planes, frames, &mut self.ready);
                Ok(())
            }
            Some(resampler) => {
                self.stereo.clear();
                self.mix.apply(&self.planes, frames, &mut self.stereo);
                resampler.push(&self.stereo, &mut self.ready)
            }
        }
    }

    fn finish(&mut self) -> Result<(), Error> {
        self.finished = true;
        self.ended_early = self.frame_limit.is_some_and(|limit| self.decoded_frames < limit);

        match &mut self.resampler {
            None => Ok(()),
            Some(resampler) => resampler.finish(&mut self.ready),
        }
    }
}
