use std::borrow::Cow;
use std::ffi::OsStr;
use std::fs::File;
use std::io::{self, Cursor};
use std::path::Path;

use symphonia::core::audio::Channels;
use symphonia::core::codecs::CodecParameters;
use symphonia::core::codecs::audio::well_known::CODEC_ID_OPUS;
use symphonia::core::codecs::audio::{AudioCodecParameters, AudioDecoder, AudioDecoderOptions};
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatOptions, FormatReader, Track, TrackType};
use symphonia::core::io::{MediaSource, MediaSourceStream, MediaSourceStreamOptions};
use symphonia::core::meta::MetadataOptions;

use crate::decoder::Decoder;
use crate::demuxer::Demuxer;
use crate::error::Error;
use crate::fields::{DescribeField, State};
use crate::{limits, opus, wav};

const OPUS_CODEC_NAME: &str = "opus";
const MILLISECONDS_PER_SECOND: u32 = 1_000;

enum Output {
    Decoded(Box<Decoder>),
    Opus,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Info {
    pub sample_rate: u32,
    pub channels: Option<usize>,
    pub is_opus: bool,
    pub duration_milliseconds: Option<u64>,
    pub skipped_packets: u64,
    pub ended_early: bool,
}

pub struct Session {
    demuxer: Demuxer,
    output: Output,
    pub(crate) sample_rate: u32,
    channel_count: Option<usize>,
    pub(crate) codec_name: &'static str,
    pub(crate) container_name: &'static str,
    duration_milliseconds: Option<u64>,
    ended: bool,
    failure: Option<Error>,
}

impl Session {
    pub fn open_memory(bytes: Vec<u8>, extension: Option<&str>) -> Result<Self, Error> {
        if bytes.is_empty() {
            return Err(Error::EmptyAudio);
        }

        let fact_frames = wav::fact_frames(&bytes);

        Self::open(Box::new(Cursor::new(bytes)), extension, fact_frames)
    }

    pub fn open_file(path: &str, extension: Option<&str>) -> Result<Self, Error> {
        let file_error = |failure: io::Error| Error::File { path: path.to_string(), detail: failure.to_string() };
        let mut file = File::open(path).map_err(file_error)?;
        let fact_frames = wav::read_fact_frames(&mut file).map_err(file_error)?;
        let path_extension = Path::new(path).extension().and_then(OsStr::to_str);

        Self::open(Box::new(file), extension.or(path_extension), fact_frames)
    }

    pub fn open(
        source: Box<dyn MediaSource>,
        extension: Option<&str>,
        fact_frames: Option<u64>,
    ) -> Result<Self, Error> {
        Self::from_reader(probe(source, extension)?, fact_frames)
    }

    pub fn from_reader(reader: Box<dyn FormatReader>, fact_frames: Option<u64>) -> Result<Self, Error> {
        let track = reader.default_track(TrackType::Audio).ok_or(Error::NoAudioTrack)?;
        let Some(CodecParameters::Audio(parameters)) = &track.codec_params else {
            return Err(Error::NoCodecParameters);
        };
        let channel_count = parameters.channels.as_ref().map(Channels::count);
        let sample_rate = limits::check_sample_rate_and_channels(parameters.sample_rate, channel_count)?;

        limits::check_packet_size(parameters.max_frames_per_packet, parameters.frames_per_block)?;

        let container_name = reader.format_info().short_name;
        let (output, codec_name, frame_count) = if parameters.codec == CODEC_ID_OPUS {
            opus::check_passthrough(parameters.extra_data.as_deref(), channel_count)?;

            (Output::Opus, OPUS_CODEC_NAME, track.num_frames)
        } else {
            let codec = make_codec(parameters)?;
            let codec_name = codec.codec_info().short_name;
            let frame_count = wav::playable_frames(track.num_frames, container_name, codec_name, fact_frames);

            (Output::Decoded(Box::new(Decoder::new(codec, sample_rate, frame_count)?)), codec_name, frame_count)
        };
        let duration_milliseconds = duration_milliseconds(track, frame_count, sample_rate);
        let track_id = track.id;

        Ok(Self {
            demuxer: Demuxer::new(reader, track_id),
            output,
            sample_rate,
            channel_count,
            codec_name,
            container_name,
            duration_milliseconds,
            ended: false,
            failure: None,
        })
    }

    pub fn read(&mut self, output: &mut [u8]) -> Result<usize, Error> {
        let Output::Decoded(decoder) = &mut self.output else {
            return Err(Error::OpusNeedsReadPacket);
        };
        let frames = decoder.read(&mut self.demuxer, self.sample_rate, output)?;

        self.ended = frames == 0;

        Ok(frames)
    }

    pub fn read_packet(&mut self, capacity: usize) -> Result<Option<Box<[u8]>>, Error> {
        if !self.is_opus() {
            return Err(Error::NotOpus);
        }

        let packet = loop {
            match self.demuxer.next_packet()? {
                Some(packet) if packet.data.is_empty() => self.demuxer.skip()?,
                packet => break packet,
            }
        };

        match packet {
            None => {
                self.ended = true;
                Ok(None)
            }
            Some(packet) if packet.data.len() > capacity => {
                let error = Error::PacketTooLarge { length: packet.data.len(), capacity };

                self.demuxer.put_back(packet);
                Err(error)
            }
            Some(packet) => {
                self.demuxer.reset_skips();
                Ok(Some(packet.data))
            }
        }
    }

    pub fn is_opus(&self) -> bool {
        matches!(self.output, Output::Opus)
    }

    pub fn state(&self) -> State {
        match (&self.failure, self.ended) {
            (Some(_), _) => State::Failed,
            (None, true) => State::Ended,
            (None, false) => State::Open,
        }
    }

    pub fn info(&self) -> Info {
        Info {
            sample_rate: self.sample_rate,
            channels: self.channel_count,
            is_opus: self.is_opus(),
            duration_milliseconds: self.duration_milliseconds,
            skipped_packets: self.demuxer.skipped_packets(),
            ended_early: match &self.output {
                Output::Decoded(decoder) => decoder.ended_early(),
                Output::Opus => false,
            },
        }
    }

    pub fn describe(&self, field: DescribeField) -> Cow<'static, str> {
        match field {
            DescribeField::Codec => Cow::Borrowed(self.codec_name),
            DescribeField::Container => Cow::Borrowed(self.container_name),
            DescribeField::Failure => self.failure.as_ref().map_or(Cow::Borrowed(""), |error| error.to_string().into()),
        }
    }

    pub(crate) fn failure(&self) -> Option<&Error> {
        self.failure.as_ref()
    }

    pub fn mark_failed(&mut self, error: Error) {
        self.failure.get_or_insert(error);
    }
}

fn probe(source: Box<dyn MediaSource>, extension: Option<&str>) -> Result<Box<dyn FormatReader>, Error> {
    let media = MediaSourceStream::new(source, MediaSourceStreamOptions::default());
    let mut hint = Hint::new();

    if let Some(extension) = extension {
        hint.with_extension(extension);
    }

    symphonia::default::get_probe()
        .probe(&hint, media, FormatOptions::default(), MetadataOptions::default())
        .map_err(|failure| Error::Unsupported(failure.to_string()))
}

fn make_codec(parameters: &AudioCodecParameters) -> Result<Box<dyn AudioDecoder>, Error> {
    symphonia::default::get_codecs()
        .make_audio_decoder(parameters, &AudioDecoderOptions::default())
        .map_err(|failure| Error::NoDecoder(failure.to_string()))
}

#[expect(
    clippy::cast_possible_truncation,
    clippy::cast_sign_loss,
    reason = "the milliseconds are checked finite and non-negative, and `as` saturates them to u64"
)]
fn duration_milliseconds(track: &Track, frame_count: Option<u64>, sample_rate: u32) -> Option<u64> {
    if let Some(frames) = frame_count {
        let rate = u128::from(sample_rate);
        let scaled = u128::from(frames) * u128::from(MILLISECONDS_PER_SECOND);

        return u64::try_from((scaled + rate / 2) / rate).ok();
    }

    let time = track.time_base?.calc_duration(track.duration?)?;
    let milliseconds = (time.as_secs_f64() * f64::from(MILLISECONDS_PER_SECOND)).round();

    (milliseconds.is_finite() && milliseconds >= 0.0).then_some(milliseconds as u64)
}
