use std::fmt::{self, Display, Formatter};

use crate::opus::{FAMILY_HEADER_LENGTH, MAPPING_HEADER_LENGTH};
use crate::limits::{
    MAX_CHANNELS, MAX_CONSECUTIVE_SKIPS, MAX_FRAMES_PER_PACKET, MAX_SAMPLE_RATE, MIN_CHANNELS, MIN_SAMPLE_RATE,
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Error {
    EmptyAudio,
    NullAudio,
    NullPath,
    PathNotUtf8,
    NullOutput,
    ZeroCapacity,
    NullSession,
    Panicked(Option<String>),
    File { path: String, detail: String },
    Unsupported(String),
    NoAudioTrack,
    NoCodecParameters,
    UnknownSampleRate,
    SampleRateOutOfRange(u32),
    ChannelCountOutOfRange(usize),
    FramesPerPacketOutOfRange(u64),
    FramesPerBlockOutOfRange(u64),
    NoDecoder(String),
    UnreadableContainer(String),
    UndecodablePacket(String),
    TooManySkips,
    SampleRateChanged { track_rate: u32, decoded_rate: u32 },
    StreamChanged,
    OpusNeedsReadPacket,
    NotOpus,
    PacketTooLarge { length: usize, capacity: usize },
    MultistreamOpus,
    UnknownOpusChannels,
    ShortOpusHead(usize),
    ShortMappingTable { mapping_family: u8, length: usize },
    ResamplerUnavailable { source_rate: u32, detail: String },
    ResampleFailed(String),
    WorkerUnavailable(String),
    StreamClosed,
}

impl Display for Error {
    #[expect(clippy::too_many_lines, reason = "one arm per error: every message the crate shows, kept in one place")]
    fn fmt(&self, formatter: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Self::EmptyAudio => formatter.write_str("the audio is empty"),
            Self::NullAudio => formatter.write_str("the audio pointer is null"),
            Self::NullPath => formatter.write_str("the path is null"),
            Self::PathNotUtf8 => formatter.write_str("the path is not valid UTF-8"),
            Self::NullOutput => formatter.write_str("the output buffer is null"),
            Self::ZeroCapacity => formatter.write_str("the output buffer has room for no frames"),
            Self::NullSession => formatter.write_str("the session pointer is null"),
            Self::Panicked(Some(message)) => write!(formatter, "symphonia wrapper panicked: {message}"),
            Self::Panicked(None) => formatter.write_str("symphonia wrapper panicked: a panic without a message"),
            Self::File { path, detail } => write!(formatter, "{path}: {detail}"),
            Self::Unsupported(detail) => write!(formatter, "not a supported audio file: {detail}"),
            Self::NoAudioTrack => formatter.write_str("the file has no audio track"),
            Self::NoCodecParameters => formatter.write_str("the audio track has no codec parameters"),
            Self::UnknownSampleRate => formatter.write_str("the audio does not state its sample rate"),
            Self::SampleRateOutOfRange(sample_rate) => write!(
                formatter,
                "the sample rate of {sample_rate} Hz is outside {MIN_SAMPLE_RATE} to {MAX_SAMPLE_RATE} Hz"
            ),
            Self::ChannelCountOutOfRange(channel_count) => {
                write!(formatter, "the channel count of {channel_count} is outside {MIN_CHANNELS} to {MAX_CHANNELS}")
            }
            Self::FramesPerPacketOutOfRange(frames) => write!(
                formatter,
                "the audio declares packets of {frames} frames; at most {MAX_FRAMES_PER_PACKET} are supported"
            ),
            Self::FramesPerBlockOutOfRange(frames) => write!(
                formatter,
                "the audio declares blocks of {frames} frames; at most {MAX_FRAMES_PER_PACKET} are supported"
            ),
            Self::NoDecoder(detail) => write!(formatter, "no decoder for this codec: {detail}"),
            Self::UnreadableContainer(detail) => write!(formatter, "could not read the container: {detail}"),
            Self::UndecodablePacket(detail) => write!(formatter, "could not decode a packet: {detail}"),
            Self::TooManySkips => {
                write!(formatter, "the audio has more than {MAX_CONSECUTIVE_SKIPS} undecodable packets in a row")
            }
            Self::SampleRateChanged { track_rate, decoded_rate } => write!(
                formatter,
                "the stream changed its sample rate from {track_rate} Hz to {decoded_rate} Hz mid-file, which is not supported"
            ),
            Self::StreamChanged => {
                formatter.write_str("the stream changed its parameters mid-file, which is not supported")
            }
            Self::OpusNeedsReadPacket => formatter.write_str("this audio is Opus; read it with readPacket"),
            Self::NotOpus => formatter.write_str("this audio is not Opus; read it with read"),
            Self::PacketTooLarge { length, capacity } => {
                write!(formatter, "the next Opus packet is {length} bytes, more than the {capacity}-byte buffer")
            }
            Self::MultistreamOpus => {
                formatter.write_str("this Opus stream has more than one stream and cannot be passed through")
            }
            Self::UnknownOpusChannels => formatter.write_str(
                "this Opus stream has no OpusHead and does not state its channel count, so it cannot be passed through",
            ),
            Self::ShortOpusHead(length) => {
                write!(formatter, "the OpusHead is {length} bytes, shorter than the {FAMILY_HEADER_LENGTH} it needs")
            }
            Self::ShortMappingTable { mapping_family, length } => write!(
                formatter,
                "the OpusHead for mapping family {mapping_family} is {length} bytes, shorter than the {MAPPING_HEADER_LENGTH} it needs"
            ),
            Self::ResamplerUnavailable { source_rate, detail } => {
                write!(formatter, "could not make a resampler from {source_rate} Hz: {detail}")
            }
            Self::ResampleFailed(detail) => write!(formatter, "could not resample: {detail}"),
            Self::WorkerUnavailable(detail) => {
                write!(formatter, "could not start the stream's worker thread: {detail}")
            }
            Self::StreamClosed => formatter.write_str("the stream was closed"),
        }
    }
}

impl std::error::Error for Error {}
