use discord_luau_symphonia::Error;

const DETAIL: &str = "detail";

fn call_errors() -> Vec<(Error, &'static str)> {
    vec![
        (Error::EmptyAudio, "the audio is empty"),
        (Error::NullAudio, "the audio pointer is null"),
        (Error::NullPath, "the path is null"),
        (Error::PathNotUtf8, "the path is not valid UTF-8"),
        (Error::NullOutput, "the output buffer is null"),
        (Error::ZeroCapacity, "the output buffer has room for no frames"),
        (Error::NullSession, "the session pointer is null"),
        (Error::Panicked(Some(String::from("broken"))), "symphonia wrapper panicked: broken"),
        (Error::Panicked(None), "symphonia wrapper panicked: a panic without a message"),
        (Error::File { path: String::from("/missing.mp3"), detail: DETAIL.to_string() }, "/missing.mp3: detail"),
        (Error::OpusNeedsReadPacket, "this audio is Opus; read it with readPacket"),
        (Error::NotOpus, "this audio is not Opus; read it with read"),
        (Error::WorkerUnavailable(DETAIL.to_string()), "could not start the stream's worker thread: detail"),
        (Error::StreamClosed, "the stream was closed"),
    ]
}

fn audio_errors() -> Vec<(Error, &'static str)> {
    let detail = String::from(DETAIL);

    vec![
        (Error::Unsupported(detail.clone()), "not a supported audio file: detail"),
        (Error::NoAudioTrack, "the file has no audio track"),
        (Error::NoCodecParameters, "the audio track has no codec parameters"),
        (Error::UnknownSampleRate, "the audio does not state its sample rate"),
        (Error::SampleRateOutOfRange(999), "the sample rate of 999 Hz is outside 1000 to 384000 Hz"),
        (Error::ChannelCountOutOfRange(33), "the channel count of 33 is outside 1 to 32"),
        (
            Error::FramesPerPacketOutOfRange(262_145),
            "the audio declares packets of 262145 frames; at most 262144 are supported",
        ),
        (
            Error::FramesPerBlockOutOfRange(262_145),
            "the audio declares blocks of 262145 frames; at most 262144 are supported",
        ),
        (Error::NoDecoder(detail.clone()), "no decoder for this codec: detail"),
        (Error::UnreadableContainer(detail.clone()), "could not read the container: detail"),
        (Error::UndecodablePacket(detail.clone()), "could not decode a packet: detail"),
        (Error::TooManySkips, "the audio has more than 10000 undecodable packets in a row"),
        (
            Error::SampleRateChanged { track_rate: 44_100, decoded_rate: 48_000 },
            "the stream changed its sample rate from 44100 Hz to 48000 Hz mid-file, which is not supported",
        ),
        (Error::StreamChanged, "the stream changed its parameters mid-file, which is not supported"),
        (
            Error::PacketTooLarge { length: 100, capacity: 50 },
            "the next Opus packet is 100 bytes, more than the 50-byte buffer",
        ),
        (Error::MultistreamOpus, "this Opus stream has more than one stream and cannot be passed through"),
        (
            Error::UnknownOpusChannels,
            "this Opus stream has no OpusHead and does not state its channel count, so it cannot be passed through",
        ),
        (Error::ShortOpusHead(12), "the OpusHead is 12 bytes, shorter than the 19 it needs"),
        (
            Error::ShortMappingTable { mapping_family: 1, length: 19 },
            "the OpusHead for mapping family 1 is 19 bytes, shorter than the 21 it needs",
        ),
        (
            Error::ResamplerUnavailable { source_rate: 7, detail: detail.clone() },
            "could not make a resampler from 7 Hz: detail",
        ),
        (Error::ResampleFailed(detail), "could not resample: detail"),
    ]
}

#[test]
fn every_message_is_the_text_luau_expects() {
    let errors: Vec<(Error, &str)> = call_errors().into_iter().chain(audio_errors()).collect();

    assert_eq!(errors.len(), 35, "every variant, and both kinds of panic");

    for (error, text) in errors {
        assert_eq!(error.to_string(), text, "{error:?}");
    }
}
