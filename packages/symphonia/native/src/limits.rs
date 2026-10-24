use crate::error::Error;

pub const MIN_SAMPLE_RATE: u32 = 1_000;
pub const MAX_SAMPLE_RATE: u32 = 384_000;
pub const MIN_CHANNELS: usize = 1;
pub const MAX_CHANNELS: usize = 32;

pub const MAX_FRAMES_PER_PACKET: u64 = 262_144;

pub const MAX_CONSECUTIVE_SKIPS: u64 = 10_000;

pub fn check_sample_rate_and_channels(sample_rate: Option<u32>, channel_count: Option<usize>) -> Result<u32, Error> {
    let sample_rate = sample_rate.ok_or(Error::UnknownSampleRate)?;

    if !(MIN_SAMPLE_RATE..=MAX_SAMPLE_RATE).contains(&sample_rate) {
        return Err(Error::SampleRateOutOfRange(sample_rate));
    }

    if let Some(count) = channel_count
        && !(MIN_CHANNELS..=MAX_CHANNELS).contains(&count)
    {
        return Err(Error::ChannelCountOutOfRange(count));
    }

    Ok(sample_rate)
}

pub fn check_packet_size(max_frames_per_packet: Option<u64>, frames_per_block: Option<u64>) -> Result<(), Error> {
    match (max_frames_per_packet, frames_per_block) {
        (Some(frames), _) if frames > MAX_FRAMES_PER_PACKET => Err(Error::FramesPerPacketOutOfRange(frames)),
        (_, Some(frames)) if frames > MAX_FRAMES_PER_PACKET => Err(Error::FramesPerBlockOutOfRange(frames)),
        _ => Ok(()),
    }
}
