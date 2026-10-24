//! The limits on the sample rate, the channel count and the declared packet size.

use super::*;

use crate::session::Session;
use crate::tests::caf_lpcm;

#[test]
fn the_sample_rate_limits_hold() {
    assert_eq!(check_sample_rate_and_channels(Some(1_000), Some(1)), Ok(1_000));
    assert_eq!(check_sample_rate_and_channels(Some(384_000), Some(32)), Ok(384_000));
    assert_eq!(check_sample_rate_and_channels(Some(48_000), None), Ok(48_000));

    for rate in [0, 1, 999, 384_001, 2_147_483_647, u32::MAX] {
        let failure = check_sample_rate_and_channels(Some(rate), Some(2)).unwrap_err().to_string();

        assert!(failure.contains(&format!("{rate} Hz")), "{failure}");
        assert!(failure.contains("1000 to 384000 Hz"), "{failure}");
    }

    assert_eq!(check_sample_rate_and_channels(None, Some(2)), Err(Error::UnknownSampleRate));
}

#[test]
fn the_channel_limits_hold() {
    for count in [0, 33, 255] {
        let failure = check_sample_rate_and_channels(Some(48_000), Some(count)).unwrap_err().to_string();

        assert!(failure.contains(&format!("{count}")) && failure.contains("1 to 32"), "{failure}");
    }
}

#[test]
fn the_packet_size_limit_holds() {
    assert_eq!(check_packet_size(None, None), Ok(()));
    assert_eq!(check_packet_size(Some(262_144), Some(262_144)), Ok(()));
    assert_eq!(
        check_packet_size(Some(262_145), None).unwrap_err().to_string(),
        "the audio declares packets of 262145 frames; at most 262144 are supported"
    );
    assert_eq!(
        check_packet_size(None, Some(262_145)).unwrap_err().to_string(),
        "the audio declares blocks of 262145 frames; at most 262144 are supported"
    );
    assert!(Session::open_memory(caf_lpcm(262_144), None).is_ok());
}
