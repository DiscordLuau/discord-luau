//! The decoder's trim to the playable length, driven directly over a probed WAV.

use super::*;

use std::io::Cursor;

use symphonia::core::codecs::CodecParameters;
use symphonia::core::codecs::audio::AudioDecoderOptions;
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatOptions, TrackType};
use symphonia::core::io::{MediaSourceStream, MediaSourceStreamOptions};
use symphonia::core::meta::MetadataOptions;

use crate::tests::wav;

const READ_MAX_FRAMES: usize = 480_000;

/// Made as `Session::open` makes them, but with `frame_limit` as the playable length.
fn open(bytes: Vec<u8>, frame_limit: Option<u64>) -> (Decoder, Demuxer, u32) {
    let media = MediaSourceStream::new(Box::new(Cursor::new(bytes)), MediaSourceStreamOptions::default());
    let reader = symphonia::default::get_probe()
        .probe(&Hint::new(), media, FormatOptions::default(), MetadataOptions::default())
        .unwrap();
    let track = reader.default_track(TrackType::Audio).unwrap();
    let Some(CodecParameters::Audio(parameters)) = &track.codec_params else {
        panic!("the track has no audio parameters");
    };
    let codec =
        symphonia::default::get_codecs().make_audio_decoder(parameters, &AudioDecoderOptions::default()).unwrap();
    let sample_rate = parameters.sample_rate.unwrap();
    let decoder = Decoder::new(codec, sample_rate, frame_limit).unwrap();
    let track_id = track.id;

    (decoder, Demuxer::new(reader, track_id), sample_rate)
}

/// Panics after `READ_MAX_FRAMES`, so a decoder that never ends fails the test instead of reading forever.
fn read_frames(decoder: &mut Decoder, demuxer: &mut Demuxer, sample_rate: u32) -> usize {
    let mut frames = 0;

    loop {
        let bytes = decoder.read(demuxer, sample_rate, 4_800).unwrap();

        if bytes.is_empty() {
            return frames;
        }

        frames += bytes.len() / BYTES_PER_FRAME;

        assert!(frames <= READ_MAX_FRAMES, "read more than {READ_MAX_FRAMES} frames without reaching the end");
    }
}

#[test]
fn frames_beyond_the_stated_count_are_dropped() {
    let (mut decoder, mut demuxer, sample_rate) = open(wav(48_000, 2, 1_000), Some(600));

    assert_eq!(read_frames(&mut decoder, &mut demuxer, sample_rate), 600);
    assert!(!decoder.ended_early, "stopping at the stated length is not early");
}
