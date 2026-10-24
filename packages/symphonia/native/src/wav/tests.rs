//! Finding a WAV file's `fact` chunk.

use super::*;

use crate::tests::{adpcm_wav, wav, with_fact};

#[test]
fn the_fact_chunk_is_found() {
    assert_eq!(fact_frames(&adpcm_wav(22_050, 11_025, 6)), Some(11_025));
    assert_eq!(fact_frames(&with_fact(wav(8_000, 1, 10), 7)), Some(7));
    assert_eq!(fact_frames(&wav(8_000, 1, 10)), None, "no fact chunk");
    assert_eq!(fact_frames(b"OggS not a wav file"), None);
    assert_eq!(fact_frames(&adpcm_wav(22_050, 11_025, 6)[..50]), None, "truncated");

    // An odd-sized chunk is padded to an even length before the next one.
    let mut padded = Vec::from(&b"RIFF\0\0\0\0WAVEodd \x03\0\0\0abc\0"[..]);

    padded.extend_from_slice(b"fact\x04\0\0\0\x2a\0\0\0");

    assert_eq!(fact_frames(&padded), Some(42));
}
