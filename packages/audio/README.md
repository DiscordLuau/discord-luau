<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

A paced audio player and audio sources for discord-luau voice connections.

**Source:** [packages/audio](https://github.com/DiscordLuau/discord-luau/tree/main/packages/audio)

Audio runs on Zune only: it plays through `discord_luau/voice`, encodes with `discord_luau/opus` and decodes audio files with `discord_luau/symphonia`, which load native libraries through FFI.

## Installation

```bash
pesde add discord_luau/audio
pesde add discord_luau/discord_luau
pesde add discord_luau/builders
```

## Example

Join a voice channel with classes, build two seconds of a 440 Hz tone and play it:

```luau
local audio = require("./luau_packages/audio")
local builders = require("./luau_packages/builders")
local discord = require("./luau_packages/discord_luau")

local SAMPLE_RATE = 48000

local bot = discord.bot.new({
    token = zune.process.env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds", "GuildVoiceStates" }):build(),
})

local function tone(hertz: number, seconds: number): buffer
    local sampleCount = SAMPLE_RATE * seconds
    local pcm = buffer.create(sampleCount * 4)

    for sampleIndex = 0, sampleCount - 1 do
        local sample = math.floor(math.sin(2 * math.pi * hertz * sampleIndex / SAMPLE_RATE) * 8000)

        buffer.writei16(pcm, sampleIndex * 4, sample)
        buffer.writei16(pcm, sampleIndex * 4 + 2, sample)
    end

    return pcm
end

bot.onAllShardsReady:listenOnce(function()
    local channel = bot:getVoiceChannelAsync("0987654321"):await():unwrapOk()
    local connection = channel:joinAsync():await():unwrapOk()
    local player = audio.player.new(connection)
    local played = player:playAsync(audio.fromPCM(tone(440, 2))):await()

    if played:isOk() then
        print(`playback {played:unwrapOk()}`)
    else
        print(`playback failed: {played:unwrapErr()}`)
    end

    channel:leaveAsync():await()
end)

bot:connectAsync():await()
```

## Sources

A source is single-use: the playback that takes it frees it on every exit, whether it finished, was stopped or failed.

- `audio.fromPCM(pcm)` takes 48 kHz stereo 16-bit little-endian PCM of any length, as one buffer, an array of buffers, or a function that returns the next buffer and nil at the end. It is cut into 20 ms frames as it is read, the last frame is padded with silence, and each frame is encoded to Opus. A total that is not a whole number of samples (4 bytes each) raises: at once for one buffer, and when the input ends for an array or a function.
- `audio.fromOpus(packets)` takes an array of Opus packets, or a function that returns the next packet and nil at the end, and sends each packet as it is. An `.opus` file is not raw packets: a buffer or string raises, pointing at `audio.fromOgg` and `audio.fromFile`.
- `audio.fromFile(path, options?)` and `audio.fromEncoded(bytes, options?)` play an audio file; see below.
- `audio.fromStream(read, options?)` and `audio.fromProcess(command, arguments, options?)` play a file that arrives in pieces, from a Luau function or from a program's output; see [Streams](#streams).

A function input to `fromPCM` or `fromOpus` must return the next item quickly: one that takes longer than a frame leaves a gap in the audio, and one that never returns holds the playback, which `stop` cannot end. A stream's `read` may take as long as it needs.

### Encoder settings

`audio.fromPCM(pcm, options?)`, `audio.fromFile`, `audio.fromEncoded` and the named sources take `options.bitrate`, the Opus bitrate in bits per second: a whole number from 500 to 510000, 128000 by default. The named sources take `logLevel` and `bitrate` but no `extension`, which each fixes by its name. The bitrate is checked at the call with `opus.checkBitrate`, because the encoder is created on the first read, and a bad value raises `bitrate must be a whole number from 500 to 510000 bits per second`. Every encoder a source creates is set to that bitrate and to the `"music"` signal hint. The source holds the value as `source.bitrate`. Opus passed through is never re-encoded, so the bitrate does not apply to it.

### Volume

`audio.fromFile`, `audio.fromEncoded` and the named sources take `options.volume`, a number from 0 to 4 (1 by default), checked at the call; a bad value raises `volume must be a number from 0 to 4`. `source:setVolume(volume)` changes it while the source plays and `source.volume` holds it. The change is heard at the next 100 ms read of the file, ramped so it never clicks, and audio that would pass full scale is limited rather than clipped. Opus passed through is not decoded, so volume has no effect on it. `fromPCM` and `fromOpus` sources have no volume: `setVolume` raises on them.

### Audio files

`audio.fromFile(path, options?)` streams a file from the disk as it plays. `audio.fromEncoded(bytes, options?)` plays one held in memory, as a buffer or a string of its bytes, such as what `fs.readFile` returns; a string is always the bytes, never a path.

```luau
local played = player:playAsync(audio.fromFile("music/song.flac")):await()
```

Files decode through `discord_luau/symphonia`, which finds the format from the content alone:

| Kind | Supported |
|---|---|
| Decoded, then encoded to Opus as it plays | MP1, MP2 and MP3; AAC-LC, mono or stereo; FLAC; Vorbis; PCM; ADPCM, mono or stereo; ALAC |
| Passed through as stored | single-stream Opus |
| Containers | WAV, AIFF, CAF, Ogg, Matroska, WebM, MP4 and M4A, and bare MP3, FLAC and ADTS AAC streams |

PCM, FLAC, Vorbis and ALAC in any channel layout are mixed to stereo. AAC and ADPCM with more than two channels fail to open, so the 5.1 AAC track of a video rip does not play.

The named sources take a file's bytes, like `fromEncoded`: `fromMP3`, `fromOgg`, `fromWAV`, `fromFLAC`, `fromAAC`, `fromM4A`, `fromWebM`, `fromMKV`, `fromAIFF` and `fromCAF`. They are aliases of `fromEncoded`, named for discoverability. Each passes an extension hint that Symphonia 0.6.1 never reads, so any supported file plays through any of them, and `options.extension` has no effect either.

- **AAC-LC, mono or stereo.** HE-AAC that states its SBR in the file's header fails to open. HE-AAC that signals SBR only inside the stream, as most ADTS files do, plays only its band-limited LC core.
- **Opus is passed through, never decoded.** Opus in Ogg, WebM, Matroska or MP4 goes out packet by packet as stored, which drops what an Opus decoder applies: the pre-skip (about 6.5 ms of encoder priming), the end trimming (up to one packet of padding) and the OpusHead output gain, so a file with a non-zero gain plays at the wrong loudness. A file with more than one Opus stream fails to open.
- **Release or play.** A file source holds a native decoder session, and for `fromFile` an open file, from the moment it is built. A `playAsync` that starts frees them on every exit. A source never handed to `playAsync`, or handed to one that fails its start checks or is never awaited, keeps them until `source:destroy()`. A second `destroy` does nothing, so calling it after any playback is safe.
- **Loading.** The first file source loads libsymphonia, which always yields, so it needs a thread that can yield. It downloads the 2 to 3 MB library when it is not cached, and checks its sha256, which blocks the VM for about 360 ms. Call `audio.loadFileDecoder()` at startup to take that cost, and the yield, before the first playback.
- **Blocking.** Opening a file and each read block on native code and, for `fromFile`, on the disk. Decoding runs far faster than real time, but a slow disk stalls the whole VM.
- **Errors.** A file that cannot be opened raises at the `from...` call with `could not open audio: <message>`. One that fails to decode partway fails its playback with `audio source failed: could not decode audio: <message>`. A malformed file can still use memory and CPU, so cap the size and length of user uploads.
- **Zune only**, like the rest of the package.

## Streams

A stream source plays a file that arrives in pieces, without waiting for the whole file: internet radio, a media URL, or what a program such as `yt-dlp` or `ffmpeg` writes. There are two routes.

**A program's output.** `audio.fromProcess(command, arguments, options?)` runs the program directly, without a shell, and plays what it writes to stdout:

```luau
local source = audio.fromProcess("yt-dlp", { "-f", "251", "-o", "-", url })
local played = player:playAsync(source):await()
```

On YouTube, keep the original Opus: format 251 is Opus in WebM, which is passed through as stored, with no decoding and no second lossy encode. Other formats are decoded and encoded again, and YouTube's M4A formats, such as 140, are fragmented MP4, which libsymphonia does not decode yet.

**A Luau function.** `audio.fromStream(read, options?)` calls `read` for the next chunk of the file's bytes, a buffer or a string of any length, and nil at the end; `read` may yield for as long as the next bytes take.

The [Playing Music](https://github.com/DiscordLuau/discord-luau/blob/main/docs/guides/playing-music.md) guide walks through playing, downloading and streaming with yt-dlp.

Both routes share the rest:

- **Nothing starts at the call.** The call only checks the options. The playback's first step opens a libsymphonia stream session, starts the program, and starts a pump thread that reads the bytes and pushes them into the session. A source that is never played holds nothing.
- **Buffering.** Decoded audio is read ahead up to 6 seconds. Nothing is sent, not even Speaking, until `bufferSeconds` of audio is buffered (1 by default, from 0.1 to 4). When the stream stalls, the playback sends its five silence frames and Speaking 0, waits, and speaks again on a fresh schedule once `bufferSeconds` is buffered again, so listeners hear a clean pause rather than a stutter. `player:stop()` ends that wait within about one 20 ms poll, and `source:destroy()` ends it without speaking again.
- **Volume and bitrate.** `volume` (1, from 0 to 4) and `bitrate` (128000) work as for files. The read-ahead holds audio before any volume, so `source:setVolume` is heard at the next packet. Opus passed through, as from YouTube's format 251, is neither re-encoded nor affected by volume.
- **Formats.** The same as files. An MP4 or M4A with its index (the `moov` atom) at the end, and a CAF, cannot be read from the front: the stream fails to open, then the rest of the file is read and the whole file plays once it has arrived. That needs memory up to about 4 times the file, and a file over 128 MiB fails with `could not open audio: this file must be complete before it plays and is larger than 128 MiB`. For a live source, prefer a format that streams: Opus in WebM or Ogg, MP3, FLAC or WAV.
- **Failures.** The playback fails with `audio source failed: <reason>`. A failure before the stream opened sends no Speaking: `could not start <command>: FileNotFound` for a missing program, `could not open audio: <message>` for bytes that are not audio, and `could not open audio: the stream ended before any audio` for none at all. A failure that comes while the session is still probing the bytes it has waits up to 500 ms for the session to decide; if the bytes open, they play first. A failure after it opened plays the audio that came first, then fails: `audio stream read failed: <error>` for a `read` that raises, `could not decode audio: <message>`, and `invalid Opus packet from the audio source: <error>`.
- **Exit codes.** Once a program's stdout ends, the stream waits up to 5 seconds for its exit code. A non-zero code wins over every other outcome: `<command> exited with code <n>: <last stderr line>`, or `no error output`. A program that keeps running after closing its output is killed after 5 seconds, with a warning, and the stream ends normally. A program is also killed when the stream stops reading it, such as after bytes that are not audio, and when the source is destroyed; a code that follows such a kill is ignored. A kill never waits for the program, so `stop` and `destroy` return at once: it closes the program's stdout and stderr, which ends one blocked on writing them, and sends SIGTERM (TerminateProcess on Windows). A program that ignores SIGTERM and writes nothing runs on until it exits by itself, so run the tool directly rather than through a shell that might.
- **Zune only.** `fromProcess` needs `std_polyfills`' `process.spawn`, which only Zune has.

## The player

`audio.player.new(connection, options?)` builds a player for one voice connection; `connection` is what `channel:joinAsync()` resolves with, or `channel.connection`. One player plays on a connection at a time. A connection that closes is gone for good: a new join makes a new `Connection`, which needs a new player.

`player:playAsync(source)` sends Speaking, then each packet paced by its own duration, then five silence frames and Speaking 0. It resolves:

- Ok `"finished"` when the source ran out;
- Ok `"stopped"` after `player:stop()`;
- Err when the connection closes (`voice connection closed: <closeDetail>`), a send fails, the source raises or returns a packet that is not Opus.

A second `playAsync` while one plays fails at once, on the same player (`audio player is already playing; await the previous playAsync future first`) or on another player of the same connection, and leaves the running playback alone.

While the connection resumes or rejoins, the playback waits and then sends Speaking again. In a DAVE channel it waits up to `mediaWaitSeconds` (5 by default) for media readiness on each new session; until media is ready, voice sends silence in place of every packet. While a stream source is starved, before it has buffered enough and whenever it stalls, the playback pauses with its silence tail and Speaking 0 and polls the source every 20 ms. `stop` ends a playback at once from the readiness wait, within about one 20 ms poll from a stream's buffering wait, and within one packet while playing (DAVE or not), but from the media wait only once that wait ends, so up to `mediaWaitSeconds` in a DAVE channel. A `fromPCM` or `fromOpus` function that never returns holds the playback, and `stop` cannot end it.

The options are `speakingFlags` (1, Microphone, by default), `silenceFrames` (5), `mediaWaitSeconds` (5), `clock` (`{ nowMillis, wait }`, for tests) and `logLevel` (`"Info"`).

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
