//! The numbers of a session's states and of the `symphonia_info` and `symphonia_describe` fields. `sys.luau` repeats
//! every one, so changing one is an ABI change.

use crate::ffi::saturate_to_i32;
use crate::session::Info;

pub const UNKNOWN: i32 = -1;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum State {
    /// A stream's worker has not opened the audio yet; file and memory sessions never report it.
    Probing = 0,
    Open = 1,
    Ended = 2,
    Failed = 3,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InfoField {
    SampleRate = 0,
    /// `0` when the source does not state it.
    Channels = 1,
    IsOpus = 2,
    /// `UNKNOWN` when the source does not state it.
    DurationMilliseconds = 3,
    /// Undecodable or empty packets of the chosen track; packets of other tracks are not counted.
    SkippedPackets = 4,
    IsFailed = 5,
    /// `1` when decoding ended short of the length the track (or a WAV `fact` chunk) states; never for Opus.
    EndedEarly = 6,
    State = 7,
}

impl InfoField {
    /// In number order, so a field's number is its index.
    pub const ALL: [Self; 8] = [
        Self::SampleRate,
        Self::Channels,
        Self::IsOpus,
        Self::DurationMilliseconds,
        Self::SkippedPackets,
        Self::IsFailed,
        Self::EndedEarly,
        Self::State,
    ];

    pub fn from_number(number: i32) -> Option<Self> {
        usize::try_from(number).ok().and_then(|index| Self::ALL.get(index).copied())
    }

    pub(crate) fn value(self, state: State, info: Option<&Info>) -> i32 {
        match (self, info) {
            (Self::IsFailed, _) => i32::from(state == State::Failed),
            (Self::State, _) => state as i32,
            (Self::SkippedPackets | Self::EndedEarly, None) => 0,
            (_, None) => UNKNOWN,
            (Self::SampleRate, Some(info)) => saturate_to_i32(info.sample_rate),
            (Self::Channels, Some(info)) => info.channels.map_or(0, saturate_to_i32),
            (Self::IsOpus, Some(info)) => i32::from(info.is_opus),
            (Self::DurationMilliseconds, Some(info)) => info.duration_milliseconds.map_or(UNKNOWN, saturate_to_i32),
            (Self::SkippedPackets, Some(info)) => saturate_to_i32(info.skipped_packets),
            (Self::EndedEarly, Some(info)) => i32::from(info.ended_early),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DescribeField {
    Codec = 0,
    Container = 1,
    /// Empty unless the state is `Failed`.
    Failure = 2,
}

impl DescribeField {
    /// In number order, so a field's number is its index.
    pub const ALL: [Self; 3] = [Self::Codec, Self::Container, Self::Failure];

    pub fn from_number(number: i32) -> Option<Self> {
        usize::try_from(number).ok().and_then(|index| Self::ALL.get(index).copied())
    }
}
