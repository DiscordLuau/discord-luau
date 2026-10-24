//! The numbers of a session's states and of the `symphonia_info` and `symphonia_describe` fields. `sys.luau` repeats
//! every one, so changing one is an ABI change.

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
