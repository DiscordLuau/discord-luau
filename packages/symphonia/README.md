<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Audio file decoding for discord-luau, through FFI bindings for libsymphonia, a small Rust wrapper around [Symphonia](https://github.com/pdeljanov/Symphonia). The library decodes every format below to 48 kHz stereo 32-bit floats; Luau applies the volume, limits the audio and converts it to 16-bit little-endian PCM, ready for `audio.fromPCM`. Opus is passed through as raw packets, ready for `audio.fromOpus`.

**Source:** [packages/symphonia](https://github.com/DiscordLuau/discord-luau/tree/main/packages/symphonia)

Symphonia needs FFI, so it runs on Zune only. On a runtime without FFI, `symphonia.load()` and every decoder raise `Symphonia requires FFI which is not available on this runtime`. Requiring the package works anywhere.

## Installation

```bash
pesde add discord_luau/symphonia
```

## Example

```luau
local symphonia = require("./luau_packages/symphonia")

symphonia.load()

local decoder = symphonia.decoder.fromFile("music/song.flac")

print(decoder.codec, decoder.container, decoder.sampleRate, decoder.durationSeconds)

while true do
    local pcm = decoder:read()

    if not pcm then
        break
    end

    -- 100 ms of 48 kHz interleaved stereo s16le
end

decoder:destroy()

local whole: buffer = symphonia.decode(zune.fs.readFile("music/jingle.mp3"))
```

`symphonia.decoder.fromBuffer(bytes, options?)` opens a file held in memory, as a buffer or a string, and `fromFile(path, options?)` streams one from the disk. A decoder's `read()` returns up to 100 ms of PCM at a time and nil at the end. For Opus, `isOpus` is true and `readPacket()` returns the next packet instead. `symphonia.decode(bytes, options?)` decodes a whole non-Opus file to one buffer and raises past `options.maxSeconds`, 3600 s by default. It holds the decoded chunks and the joined buffer at once, so its memory peaks near twice the output, about 1.4 GB at the default cap; lower `maxSeconds` for untrusted files.

`options.extension` is passed to the library, but Symphonia 0.6.1 finds the format from the file's content alone, so it currently has no effect. A file with the wrong extension still decodes.

## Formats

| Kind | Supported |
|---|---|
| Codecs | AAC-LC, mono or stereo; MP1, MP2 and MP3; FLAC; Vorbis; PCM; ADPCM, mono or stereo; ALAC |
| Containers | WAV, AIFF, CAF, Ogg, MKV and WebM, MP4 and M4A, and the bare MP3, FLAC and ADTS streams |
| Passed through | Opus in Ogg, WebM, MKV and MP4 |

AAC with more than two channels fails to open (Symphonia reports `aac too complex`), so the 5.1 AAC track of a typical video rip cannot be played; convert it to stereo first. Explicitly signalled HE-AAC fails to open too, and HE-AAC whose SBR is only implicitly signalled, as in most ADTS files, plays only its band-limited AAC-LC core. ADPCM takes at most two channels.

Every non-Opus format is resampled to 48 kHz with an exact length. PCM, FLAC, Vorbis and ALAC in any channel layout are mixed to stereo. Each side is divided by the sum of its coefficients so the mix cannot clip, which makes surround audio quieter: one 5.1 front channel alone plays at about -7.7 dB. When the file states its length, the output is trimmed to it, so ADPCM block padding is dropped. AAC keeps its encoder priming: about 34 ms in an ADTS stream, and about 23 ms in MP4.

**Opus is passed through, never decoded.** Each packet goes to Discord as it is stored, which drops what an Opus decoder would apply: the pre-skip (about 6.5 ms of encoder priming), the end trimming (up to one packet) and the OpusHead output gain, so a file with a non-zero gain plays at the wrong loudness. Only single-stream Opus can pass through; a file with more than one stream (mapping family 1 with several streams, 2, 3 or 255) fails to open.

## Loading

The library loads on first use, not on require, so a bot that plays no files never downloads it. The first `symphonia.load()`, `fromBuffer` or `fromFile` always yields: the load runs in its own thread, downloads the 2 to 3 MB library for the platform when it is not cached, and checks its sha256, which blocks the VM for about 360 ms. Call `symphonia.load()` at startup to take that cost before playback starts. Callers that arrive while a load is in flight wait for it, a caller cancelled while it waits does not hold up the others, and a failed load is retried on the next call.

## Volume and the limiter

The library only decodes: `decoder:readFloat()` returns its 48 kHz stereo 32-bit floats untouched, which can pass full scale. `read` turns them into 16-bit PCM in Luau, through the decoder's own `Limiter`, and `symphonia.decode` reads through it too.

- **Volume:** `decoder:setVolume(volume)` takes a number from 0 to 4 (1 by default, held in `decoder.volume`) and raises `volume must be a number from 0 to 4` for anything else. A change ramps over 20 ms so it never clicks, and is heard 5 ms into the next read; a volume set before the first read applies at once.
- **No clipping:** the limiter links both channels and looks 5 ms ahead. Audio that would pass full scale, such as a float file that peaks above 0 dBFS or a boosted volume, is turned down smoothly instead of clipped, with no runs of full-scale samples, and the gain comes back over 50 ms.
- **Bit for bit below full scale:** audio that never passes full scale after the volume comes out exactly as a plain conversion gives it, so at volume 1 a file that never clipped decodes as it always did.
- **Lengths:** the limiter holds 5 ms back, so the first read decodes 240 frames more than it returns, and the read that reaches the end returns them. Every read but the last two returns 100 ms, and the frame count in all is the file's own.

`symphonia.limiter.new()` makes a standalone `Limiter` for floats from `readFloat`: `setVolume(volume)`, `process(floats, frames)` for interleaved stereo floats, which returns 16-bit PCM shorter by whatever the look-ahead still holds, and `flush()` at the end. `symphonia.limiter.checkVolume(volume)` raises the volume message for a number outside 0 to 4; `symphonia.decoder.checkVolume(volume)` also takes values of any type, such as user input.

Opus is passed through undecoded, so volume does not apply: the value is kept and the first call warns `volume has no effect on Opus passed through as stored`.

## Streams

`symphonia.decoder.fromStream(options?)` opens a decoder for a file that arrives in pieces, such as a download or a program's output, and decodes it on a worker thread as the bytes come in. The first call yields, like `fromBuffer`.

```lua
local decoder = symphonia.decoder.fromStream()

while moreBytes() do
	if not decoder:push(nextChunk()) then
		-- the input is full: read some output, wait, and push the same chunk again
	end
end

decoder:finish()
```

- **`decoder:push(chunk)`** takes a buffer or a string and never blocks. It returns false, with nothing queued, when the input holds 64 chunks. It raises `could not push audio: <reason>` when the session cannot take bytes any more: the session's failure text, `the stream has ended` or `the stream was finished`.
- **`decoder:finish()`** ends the input; a second call logs at debug.
- **`decoder:refresh()`** reads the session's `state` (0 probing, 1 open, 2 ended, 3 failed). The first time the audio has opened it fills `codec`, `container`, `sampleRate`, `channels`, `isOpus` and `durationSeconds` and sets `opened`; until then they are `""`, -1 or false. Once the session has failed it sets `failed`, `failure` and `failedBeforeOpen` (the bytes were not audio libsymphonia can read from a stream). Reads call it themselves until the audio opens.
- **Reads never block.** `read`, `readFloat` and `readPacket` return nil with `dry` set while nothing is ready, before the audio opens or after it: that is not the end. At the end they return nil with `ended` set; a successful read clears `dry`. `read` keeps its limiter running through dry reads and flushes it only at the true end.
- **Memory is bounded by chunk count:** the worker holds at most 64 pushed chunks, of whatever size you push, and 64 decoded blocks (about 6.4 s of audio), so a producer that outruns the reader is held back by `push` returning false. `discord_luau/audio` pushes at most 64 KiB at a time, so its input holds about 4 MiB.
- **MP4 files with the moov atom last, and CAF files,** cannot be decoded from a stream and fail before open (`failedBeforeOpen`); decode those with `fromBuffer` once complete.
- Call `destroy` when done, even after a failure: it closes the session and its worker thread.

## Blocking and release

Opening, `read` and `readPacket` are not `Async`: they block on native code and, for `fromFile`, on the disk, and a future would not unblock them. Decoding and limiting run about 160 times faster than real time on a 225 s MP3, but a slow disk stalls the whole VM while it reads.

A decoder holds a native session, and for `fromFile` an open file, until `destroy()`. One that is never destroyed keeps them until the process exits; there is no finaliser.

## Untrusted files

A panic inside the library becomes an error and fails that decoder, never the process. Sample rates outside 1000 to 384000 Hz, more than 32 channels and absurd packet sizes are refused when the file opens, and more than 10000 undecodable packets in a row is a read error. A malformed file can still use memory and CPU, so treat user uploads with limits: cap their size and their length.

A truncated Ogg, AIFF, CAF, MKV or MP4 file fails to open, inside Symphonia's format probe. Other truncated files play the audio they hold and then end cleanly. When decoding ends short of the length the file states, as with a cut-short WAV, FLAC or MP3 with a Xing header, the decoder sets `endedEarly` and warns once: `the audio ended early, short of the length the file states; it may be truncated or damaged`. Damaged packets that were skipped count as missing audio too, so a complete file that skipped some can be flagged. A file that states no length, such as a WAV streamed from a pipe with unknown sizes, a bare MP2 stream or an ADTS AAC stream, simply ends, without that flag, and so does Opus, which is passed through rather than decoded.

## Not supported yet

- **Seeking**, until a bot needs `/seek` or a start offset.
- **Metadata tags** such as title and artist, until a bot shows what is playing.
- **Chained Ogg and parameters that change mid-file**, until internet radio dumps need to play. Such a file stops after its first part or raises `could not decode audio: the stream changed its parameters mid-file, which is not supported`.
- **Decoding Opus**, until someone needs multistream Opus, Opus mixed into PCM or the OpusHead gain applied.
- **A finaliser for a forgotten decoder**, until Zune exposes one.
- **Streaming from a URL**, until a bot plays remote files; fetch them to a buffer first.

## Native library

The binaries in `binaries/` are built from the Rust crate `discord_luau_symphonia` in [`native/`](https://github.com/DiscordLuau/discord-luau/tree/main/packages/symphonia/native) by `.github/scripts/build-binaries.sh`. It links:

- [Symphonia](https://github.com/pdeljanov/Symphonia) 0.6.1, under the MPL-2.0 ([licence](https://github.com/DiscordLuau/discord-luau/blob/main/licences/symphonia), [source](https://github.com/pdeljanov/Symphonia/tree/v0.6.1));
- [rubato](https://github.com/HEnquist/rubato), under MIT OR Apache-2.0, for resampling;
- the crates they depend on, listed with their licences in [`native/THIRD_PARTY_NOTICES.md`](https://github.com/DiscordLuau/discord-luau/blob/main/packages/symphonia/native/THIRD_PARTY_NOTICES.md).

Rust is needed only to rebuild the binaries, not to use the package.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License. The native library it loads also contains Symphonia under the MPL-2.0 and the crates listed in its notice file.
