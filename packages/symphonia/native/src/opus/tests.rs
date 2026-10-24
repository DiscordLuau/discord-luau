//! Which `OpusHead`s pass through as plain Opus, and which are refused.

use super::*;

/// `streams` is `(stream count, coupled count)`, for families other than 0.
fn head(channel_count: u8, mapping_family: u8, streams: Option<(u8, u8)>) -> Vec<u8> {
    let mut bytes = Vec::from(&MAGIC[..]);

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
    let parsed = OpusHead::parse(&head(2, 1, Some((1, 1)))).unwrap();

    assert_eq!(parsed, Some(OpusHead { mapping_family: 1, stream_count: 1 }));
    assert_eq!(OpusHead::parse(b"OggS"), Ok(None));
}
