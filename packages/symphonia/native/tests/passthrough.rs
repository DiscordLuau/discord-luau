//! Opus passed through as packets: Ogg Opus files, a scripted reader's edge cases, and which `OpusHead`s pass.

use std::collections::VecDeque;
use std::io::Cursor;

use discord_luau_symphonia::opus::{FAMILY_HEADER_LENGTH, check_passthrough};
use discord_luau_symphonia::testing::parse_opus_head;
use discord_luau_symphonia::{DescribeField, Error, Session};
use symphonia::core::audio::layouts;
use symphonia::core::codecs::CodecParameters;
use symphonia::core::codecs::audio::AudioCodecParameters;
use symphonia::core::codecs::audio::well_known::CODEC_ID_OPUS;
use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::formats::{FormatReader, Track};
use symphonia::core::io::{MediaSourceStream, MediaSourceStreamOptions};
use symphonia::core::packet::Packet;

use crate::files::{ogg_opus, opus_packet};
use crate::util::read_packets;

#[test]
fn a_hand_made_ogg_opus_stream_passes_through() {
    let packets = vec![opus_packet(10), opus_packet(20), opus_packet(30)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(session.describe(DescribeField::Codec), "opus");
    assert_eq!(session.describe(DescribeField::Container), "ogg");

    let read: Vec<Vec<u8>> = read_packets(&mut session).into_iter().map(Vec::from).collect();

    assert_eq!(read, packets);
}

#[test]
fn empty_opus_packets_are_skipped_and_counted() {
    let packets = vec![opus_packet(10), Vec::new(), opus_packet(20)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&packets[0][..]));
    assert_eq!(
        session.read_packet(8000).unwrap().as_deref(),
        Some(&packets[2][..]),
        "the empty packet is not returned, so it cannot look like the end"
    );
    assert_eq!(session.read_packet(8000).unwrap(), None);
    assert_eq!(session.info().skipped_packets, 1);
}

#[test]
fn a_chained_ogg_stream_is_the_stream_changed_error() {
    let mut bytes = ogg_opus(7, 2, &[opus_packet(10), opus_packet(20)]);

    bytes.extend(ogg_opus(8, 1, &[opus_packet(30)]));

    let mut session = Session::open_memory(bytes, None).unwrap();

    assert!(session.read_packet(8000).unwrap().is_some());
    assert!(session.read_packet(8000).unwrap().is_some());
    assert_eq!(session.read_packet(8000).err().unwrap(), Error::StreamChanged);
}

#[test]
fn more_than_ten_thousand_empty_opus_packets_in_a_row_are_an_error() {
    let mut packets = vec![Vec::new(); 10_000];

    packets.push(opus_packet(10));

    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(read_packets(&mut session).len(), 1, "10000 in a row are allowed");
    assert_eq!(session.info().skipped_packets, 10_000);

    let packets = vec![Vec::new(); 10_001];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();

    assert_eq!(
        session.read_packet(8000).err().unwrap().to_string(),
        "the audio has more than 10000 undecodable packets in a row"
    );
}

#[test]
fn a_packet_too_large_for_the_buffer_stays_pending() {
    let packets = vec![opus_packet(99), opus_packet(9)];
    let mut session = Session::open_memory(ogg_opus(7, 2, &packets), None).unwrap();
    let too_large = Error::PacketTooLarge { length: 100, capacity: 50 };

    assert_eq!(session.read_packet(50).err().unwrap(), too_large);
    assert_eq!(session.read_packet(50).err().unwrap(), too_large, "a second small read still sees the same packet");
    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&packets[0][..]));
    assert_eq!(session.read_packet(50).unwrap().as_deref(), Some(&packets[1][..]));
    assert_eq!(session.read_packet(8000).unwrap(), None);
}

enum Step {
    /// A packet of the track with this id, holding these bytes.
    Packet(u32, Vec<u8>),
    /// The `UnexpectedEof` I/O error a reader returns when the bytes run out partway through a packet.
    UnexpectedEnd,
}

/// A format reader with one stereo Opus track, track 1, that plays back a list of steps, then ends.
struct ScriptedReader {
    steps: VecDeque<Step>,
    tracks: [Track; 1],
    media_info: symphonia::core::formats::MediaInfo,
    metadata: symphonia::core::meta::MetadataLog,
}

static SCRIPTED_FORMAT_INFO: symphonia::core::formats::FormatInfo = symphonia::core::formats::FormatInfo {
    format: symphonia::core::formats::FormatId::new(symphonia::core::common::FourCc::new(*b"test")),
    short_name: "scripted",
    long_name: "Scripted test reader",
};

impl FormatReader for ScriptedReader {
    fn format_info(&self) -> &symphonia::core::formats::FormatInfo {
        &SCRIPTED_FORMAT_INFO
    }

    fn media_info(&self) -> &symphonia::core::formats::MediaInfo {
        &self.media_info
    }

    fn metadata(&mut self) -> symphonia::core::meta::Metadata<'_> {
        self.metadata.metadata()
    }

    fn seek(
        &mut self,
        _mode: symphonia::core::formats::SeekMode,
        _to: symphonia::core::formats::SeekTo,
    ) -> symphonia::core::errors::Result<symphonia::core::formats::SeekedTo> {
        Err(SymphoniaError::Unsupported("the scripted reader cannot seek"))
    }

    fn tracks(&self) -> &[Track] {
        &self.tracks
    }

    fn next_packet(&mut self) -> symphonia::core::errors::Result<Option<Packet>> {
        match self.steps.pop_front() {
            Some(Step::Packet(track_id, data)) => Ok(Some(Packet::new(
                track_id,
                symphonia::core::units::Timestamp::new(0),
                symphonia::core::units::Duration::new(960),
                data,
            ))),
            Some(Step::UnexpectedEnd) => Err(SymphoniaError::IoError(std::io::Error::new(
                std::io::ErrorKind::UnexpectedEof,
                "unexpected end of file",
            ))),
            None => Ok(None),
        }
    }

    fn into_inner<'source>(self: Box<Self>) -> MediaSourceStream<'source>
    where
        Self: 'source,
    {
        MediaSourceStream::new(Box::new(Cursor::new(Vec::new())), MediaSourceStreamOptions::default())
    }
}

/// An Opus session over a `ScriptedReader` whose chosen track is track 1.
fn scripted_opus_session(steps: impl IntoIterator<Item = Step>) -> Session {
    let mut parameters = AudioCodecParameters::new();
    let mut track = Track::new(1);

    parameters.for_codec(CODEC_ID_OPUS).with_sample_rate(48_000).with_channels(layouts::CHANNEL_LAYOUT_STEREO);
    track.with_codec_params(CodecParameters::Audio(parameters));

    let reader = ScriptedReader {
        steps: steps.into_iter().collect(),
        tracks: [track],
        media_info: symphonia::core::formats::MediaInfo::default(),
        metadata: symphonia::core::meta::MetadataLog::default(),
    };

    Session::from_reader(Box::new(reader), None).unwrap()
}

#[test]
fn read_packet_ends_cleanly_at_an_unexpected_end_of_file() {
    let mut session = scripted_opus_session([
        Step::Packet(1, opus_packet(10)),
        Step::UnexpectedEnd,
        Step::Packet(1, opus_packet(20)),
    ]);

    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&opus_packet(10)[..]));
    assert_eq!(session.read_packet(8000).unwrap(), None);
    assert!(!session.info().ended_early, "Opus is passed through, not decoded, so it is never flagged");
    assert_eq!(session.read_packet(8000).unwrap(), None, "the end stays the end");
}

#[test]
fn packets_of_other_tracks_count_toward_the_run_of_skips() {
    let other = || Step::Packet(2, opus_packet(5));
    let mut allowed: Vec<Step> = (0..10_000).map(|_| other()).collect();

    allowed.push(Step::Packet(1, opus_packet(10)));

    let mut session = scripted_opus_session(allowed);

    assert_eq!(session.read_packet(8000).unwrap().as_deref(), Some(&opus_packet(10)[..]));
    assert_eq!(session.info().skipped_packets, 0, "other tracks are passed over, not counted as skipped");

    let mut session = scripted_opus_session((0..10_001).map(|_| other()));

    assert_eq!(
        session.read_packet(8000).err().unwrap().to_string(),
        "the audio has more than 10000 undecodable packets in a row"
    );
}

#[test]
fn other_track_and_empty_packets_share_one_run() {
    let steps =
        (0..5_000).map(|_| Step::Packet(2, opus_packet(5))).chain((0..5_001).map(|_| Step::Packet(1, Vec::new())));
    let mut session = scripted_opus_session(steps);

    assert_eq!(
        session.read_packet(8000).err().unwrap().to_string(),
        "the audio has more than 10000 undecodable packets in a row"
    );
}

/// `streams` is `(stream count, coupled count)`, for families other than 0.
fn head(channel_count: u8, mapping_family: u8, streams: Option<(u8, u8)>) -> Vec<u8> {
    let mut bytes = Vec::from(&b"OpusHead"[..]);

    bytes.push(1);
    bytes.push(channel_count);
    bytes.extend_from_slice(&312_u16.to_le_bytes());
    bytes.extend_from_slice(&48_000_u32.to_le_bytes());
    bytes.extend_from_slice(&0_i16.to_le_bytes());
    bytes.push(mapping_family);

    if let Some((stream_count, coupled_count)) = streams {
        bytes.push(stream_count);
        bytes.push(coupled_count);
        bytes.extend(0..channel_count);
    }

    bytes
}

#[test]
fn family_zero_is_accepted() {
    assert_eq!(check_passthrough(Some(&head(1, 0, None)), Some(1)), Ok(()));
    assert_eq!(check_passthrough(Some(&head(2, 0, None)), Some(2)), Ok(()));
}

#[test]
fn family_one_with_one_stream_is_accepted() {
    assert_eq!(check_passthrough(Some(&head(2, 1, Some((1, 1)))), Some(2)), Ok(()));
    assert_eq!(check_passthrough(Some(&head(1, 1, Some((1, 0)))), Some(1)), Ok(()));
}

#[test]
fn family_one_with_two_uncoupled_streams_is_rejected() {
    let result = check_passthrough(Some(&head(2, 1, Some((2, 0)))), Some(2));

    assert_eq!(result, Err(Error::MultistreamOpus));
}

#[test]
fn family_one_surround_is_rejected() {
    let result = check_passthrough(Some(&head(6, 1, Some((4, 2)))), Some(6));

    assert_eq!(result, Err(Error::MultistreamOpus));
}

#[test]
fn other_families_are_rejected() {
    for family in [2, 3, 255] {
        let result = check_passthrough(Some(&head(4, family, Some((1, 0)))), Some(4));

        assert_eq!(result, Err(Error::MultistreamOpus), "family {family}");
    }
}

#[test]
fn the_head_wins_over_the_channel_count() {
    // A mono track would pass on its channel count alone, but its head says two streams.
    let result = check_passthrough(Some(&head(1, 1, Some((2, 0)))), Some(1));

    assert_eq!(result, Err(Error::MultistreamOpus));

    // A track with no channel count would fail alone, but its head says one stream.
    assert_eq!(check_passthrough(Some(&head(2, 1, Some((1, 1)))), None), Ok(()));
}

#[test]
fn a_truncated_head_is_an_error() {
    let mut short = head(2, 0, None);
    short.truncate(12);

    assert!(check_passthrough(Some(&short), Some(2)).unwrap_err().to_string().contains("shorter"));

    let mut no_stream_count = head(2, 1, Some((1, 1)));
    no_stream_count.truncate(FAMILY_HEADER_LENGTH);

    assert!(check_passthrough(Some(&no_stream_count), Some(2)).unwrap_err().to_string().contains("shorter"));
}

#[test]
fn without_a_head_the_channel_count_decides() {
    assert_eq!(check_passthrough(None, Some(1)), Ok(()));
    assert_eq!(check_passthrough(None, Some(2)), Ok(()));
    assert_eq!(check_passthrough(None, Some(3)), Err(Error::MultistreamOpus));
    assert_eq!(check_passthrough(None, None), Err(Error::UnknownOpusChannels));
}

#[test]
fn extra_data_that_is_not_a_head_counts_as_no_head() {
    assert_eq!(check_passthrough(Some(b"not a head"), Some(2)), Ok(()));
    assert!(check_passthrough(Some(b"not a head"), Some(6)).is_err());
}

#[test]
fn parse_reads_the_fields() {
    let parsed = parse_opus_head(&head(2, 1, Some((1, 1)))).unwrap();

    assert_eq!(parsed, Some((1, 1)), "mapping family 1, one stream");
    assert_eq!(parse_opus_head(b"OggS"), Ok(None));
}
