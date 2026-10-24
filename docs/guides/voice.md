---
title: Playing and Receiving Voice
description: Join a voice channel, listen to speakers and play audio with discord-luau.
sidebar:
  order: 6
---

discord-luau can join a voice channel, hand you each speaker's audio, and play audio of its own. Joining and receiving come with the bot; playing uses the `discord_luau/audio` package.

## Prerequisites

- The `GuildVoiceStates` intent. Without it Discord never tells the bot about its own voice state, so `channel:joinAsync()` fails at once.
- Zune. Voice encodes, decodes and encrypts audio with native libraries (libopus, libsodium and libdave) loaded through FFI, which Zune provides; the first run downloads them for your platform. Audio files decode with libsymphonia, which loads the same way on first use.
- The **Connect** and **Speak** permissions in the voice channel.
- The audio and Opus packages, for playback and for measuring received audio:

```bash
pesde add discord_luau/audio
pesde add discord_luau/opus
```

## Joining a channel

`channel:joinAsync()` joins the channel and resolves with the guild's voice `Connection` once it is ready. A guild has one connection: joining another channel of the same guild leaves the first one.

```lua
local discord  = require("@self/../luau_packages/discord")
local builders = require("@self/../luau_packages/builders")
local env      = require("@self/../.env")

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds", "GuildVoiceStates" }):build(),
})

bot.onAllShardsReady:listenOnce(function()
    local channel = bot:getVoiceChannelAsync("VOICE_CHANNEL_ID"):await():unwrapOk()
    local joined = channel:joinAsync():await()

    if joined:isErr() then
        bot.logger:warn(`could not join: {joined:unwrapErr()}`)

        return
    end

    local connection = joined:unwrapOk()

    connection.onClosed:listen(function(reason, code)
        bot.logger:info(`voice closed ({reason}, code {code}): {connection.closeDetail}`)
    end)
end)

bot:connectAsync():await()
```

`channel.onReady` fires each time a new voice session is ready: after the first join, a rejoin, a move or a voice server change. `connection.onClosed` fires once, when the connection ends for good, with one of these reasons:

- `left`: you called `channel:leaveAsync()`, `connection:leaveAsync()`, `connection:disconnectAsync()` or `connection:destroy()`, or joined another channel of the same guild.
- `removed`: the bot was taken out of the channel.
- `joinTimedOut`: the first join did not finish in time or failed.
- `gaveUp`: the resume and rejoin attempts ran out (five, counted until the connection stays up for a minute), or the voice supervisor errored.
- `rejected`: Discord closed the voice connection with a code that says not to try again; the code is the second argument.
- `shardDown`: the gateway shard carrying the guild closed for good; the connection notices when voice next waits for the shard.

`connection.closeDetail` holds a sentence saying why.

## Receiving audio

`channel.onAudioFrame` fires with `{ userId, ssrc, frame }` for each speaker, where `frame` is one jitter slot (20 ms for 20 ms senders) of decoded stereo 16-bit little-endian PCM at 48 kHz. The jitter buffer behind it plays packets in order at a steady pace and fills a lost packet with loss concealment; it stops about 100 ms after the speaker stops. `channel.onRawAudioFrame` fires alongside it with the Opus payload of each packet, and `channel.onSpeaking` fires with `{ userId, ssrc, speaking }` when a user's speaking flags change.

`opus.stats` measures a decoded frame:

```lua
local opus = require("@self/../luau_packages/opus")

channel.onAudioFrame:listen(function(data)
    local stats = opus.stats(data.frame, opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)

    print(`{data.userId or data.ssrc}: {string.format("%.1f", stats.dBFS)} dBFS`)
end)
```

If you only need raw frames or who is speaking, set `connection.decodeAudio = false`: Opus decoding stops, `onAudioFrame` stops firing, and `onRawAudioFrame` and `onSpeaking` carry on.

## Playing audio

Audio plays from a source through a player:

- `audio.fromPCM(pcm)` takes 48 kHz stereo 16-bit little-endian PCM of any length: one buffer, an array of buffers, or a function that returns the next buffer and nil at the end. It is cut into 20 ms frames and encoded to Opus as it plays.
- `audio.fromOpus(packets)` takes an array of Opus packets, or a function that returns the next packet and nil at the end.
- `audio.fromFile(path)` streams an audio file from the disk, and `audio.fromEncoded(bytes)` plays one held in memory, as a buffer or a string of its bytes. MP3, AAC-LC (mono or stereo), FLAC, Vorbis, WAV, ALAC and the other formats Symphonia supports are decoded and encoded to Opus as they play; PCM, FLAC, Vorbis and ALAC in any channel layout are mixed to stereo, while AAC and ADPCM with more than two channels fail to open. Opus files (`.opus`, WebM, Matroska, MP4) are passed through as stored, without their pre-skip, end trimming or output gain.
- `audio.fromMP3`, `fromOgg`, `fromWAV`, `fromFLAC`, `fromAAC`, `fromM4A`, `fromWebM`, `fromMKV`, `fromAIFF` and `fromCAF` are aliases of `fromEncoded`. The format is found from the file's content, so any supported file plays through any of them.

- `audio.fromProcess(command, arguments)` plays what a program writes to its stdout, and `audio.fromStream(read)` plays a file whose bytes a Luau function returns, chunk by chunk; see [Streaming audio](#streaming-audio).

A `fromPCM` or `fromOpus` function input must return the next item quickly: one that takes longer than a frame leaves a gap in the audio, and one that never returns holds the playback, which `stop` cannot end.

A file source holds a native decoder session, and for `fromFile` an open file, from the moment it is built. A playback that starts frees them on every exit; destroy a source you never play with `source:destroy()`. The first file source loads libsymphonia, which always yields, may download the library, and blocks for about 360 ms while it checks it, so call `audio.loadFileDecoder()` at startup. See the [audio README](https://github.com/DiscordLuau/discord-luau/tree/main/packages/audio#audio-files) for the full rules.

A source plays once. `audio.player.new(connection)` builds a player for the connection, and `player:playAsync(source)` plays a source on it:

```lua
local audio = require("@self/../luau_packages/audio")

local SAMPLE_RATE = 48000

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

local player = audio.player.new(connection)
local played = player:playAsync(audio.fromPCM(tone(440, 2))):await()

if played:isErr() then
    bot.logger:warn(`playback failed: {played:unwrapErr()}`)
end
```

`playAsync` resolves Ok with `"finished"` when the source runs out, or with `"stopped"` after `player:stop()`. It fails when the connection closes (`voice connection closed: <closeDetail>`), when a send fails, or when the source raises or returns a packet that is not Opus. One playback runs on a connection at a time: a second `playAsync` while one plays fails at once and leaves the first alone, so await the first before starting the next.

The player does three things Discord expects from a sender. It sends Speaking before the first packet, which Discord requires before audio. It sends each packet when its audio is due, 20 ms of audio every 20 ms, on an absolute schedule, so a slow send is caught up instead of stretching the clip (up to 100 ms behind; past that the schedule resets and the clip carries on from now); packets sent in a burst would overflow the listeners' jitter buffers. And it ends with five silence frames and Speaking 0, so listeners do not smear the last packet into the gap. `connection:sendOpusAsync(frame)` sends one frame with none of that.

`player:stop()` ends the playback at its next step, with the silence frames and Speaking 0 when audio was going out. A `fromPCM` or `fromOpus` read that never returns holds the playback, and `stop` cannot end it.

### Streaming audio

A stream source plays a file that arrives in pieces, without waiting for all of it. The easiest route is a program's output, such as `yt-dlp` writing YouTube's audio to stdout:

```lua
local source = audio.fromProcess("yt-dlp", { "-f", "251", "-o", "-", url })
local played = player:playAsync(source):await()
```

Format 251 is YouTube's original Opus in WebM, which is passed through as stored, with no decoding and no second lossy encode; keep it when you can.

To stay in Luau, give `audio.fromStream` a function that returns the next chunk of the file's bytes, and nil at the end. It may yield as long as it needs.

For a step-by-step walkthrough of playing, downloading and streaming music, see [Playing Music](/guides/playing-music).

Neither call reads, opens or starts anything; the playback does. It sends nothing, not even Speaking, until `bufferSeconds` of audio is buffered (1 second by default). When the stream stalls, it sends the silence frames and Speaking 0, waits, and speaks again once it has audio, so listeners hear a clean pause; `player:stop()` ends that wait within about one 20 ms poll. `volume` and `bitrate` work as for files, and `source:setVolume` is heard at the next packet; Opus passed through is unaffected by volume.

An MP4 or M4A with its index at the end, and a CAF, cannot be read from the front, so they play only once the whole file has arrived, with memory up to about 4 times the file and a 128 MiB cap. A program that exits with a non-zero code fails the playback with its last stderr line, after the audio it wrote has played; one that keeps running after closing its output is killed 5 seconds later. See the [audio README](https://github.com/DiscordLuau/discord-luau/tree/main/packages/audio#streams) for every rule and message.

## Staying connected

When the voice connection drops, voice resumes the session once (`channel.onResumed` fires) or rejoins with a backoff (`channel.onReady` fires for the new session). A playback waits through either, sends Speaking again and plays on; the player reads nothing from the source while it waits, so the clip pauses and resumes where it was. Only a packet whose send failed as the connection dropped is lost: it is logged at debug and not sent again. `channel:leaveAsync()` leaves the channel. If the connection closes, a running playback fails with `voice connection closed: <closeDetail>`, and a new join makes a new `Connection`, which needs a new player.

## DAVE end-to-end encryption

Voice negotiates DAVE end-to-end encryption on its own when the channel uses it. The connection is ready before the bot holds the group's key; `channel.onMediaReady` fires once audio can flow, and until then voice sends Opus silence in place of every packet, so no audio leaves unencrypted.

On each new session the player waits up to five seconds for media readiness before it sends Speaking (`mediaWaitSeconds` in `audio.player.new`'s options). If the key has not arrived by then, it logs at info

```text
DAVE media was not ready after 5s (timed out waiting for DAVE media readiness); playing anyway, as silence until it is
```

and plays on: the audio goes out as silence until the key arrives. A `stop` during that wait takes effect when the wait ends.

## Troubleshooting

- `channel:joinAsync()` fails at once with `voice needs the GuildVoiceStates intent`: add `"GuildVoiceStates"` to the bot's intents.
- `onClosed` fires with `rejected` and code 4017: the channel requires a newer DAVE protocol version than the bundled libdave offers (voice sends the maximum libdave supports), so update `discord_luau/dave`.
- The media-wait line above is logged and the start of the clip is silent: alone in a DAVE channel the bot never becomes media-ready, so what it plays goes out as silence until someone joins and the key arrives.
- A file source raises `could not open audio: <message>`: the file is missing, empty, or not something Symphonia decodes, such as AAC or ADPCM with more than two channels (the 5.1 AAC track of a video rip, for one) or HE-AAC that states its SBR. HE-AAC that signals SBR only inside the stream opens, but plays only its band-limited LC core. A string passed to `fromEncoded` or a named source is the file's bytes, never its path; pass a path to `audio.fromFile`.
- `audio.fromOpus` raises `... for an .opus file use audio.fromOgg or audio.fromFile`: it takes raw Opus packets, and an `.opus` file is an Ogg container.
- The first file playback stalls briefly, or a file source raises because it cannot yield: libsymphonia loads on first use, and the load always yields. Call `audio.loadFileDecoder()` at startup.
- An Opus file plays louder or quieter than in other players: passthrough does not apply the file's OpusHead output gain. Decode it elsewhere, or re-encode it without a gain.
- Native sessions or open files pile up: every file source not handed to a playback that starts needs `source:destroy()`.
- A stream fails with `audio source failed: could not start yt-dlp: FileNotFound`: the program is not on the bot's `PATH`; pass its full path to `audio.fromProcess`.
- A stream fails with `audio source failed: yt-dlp exited with code 1: ...`: the program failed; the text after the colon is its last stderr line.
- A stream pauses with Speaking 0 now and then: its input could not keep up. Raise `bufferSeconds` (up to 4) for a slow or bursty source.

<details>
<summary>Full script</summary>

```lua
local discord  = require("@self/../luau_packages/discord")
local builders = require("@self/../luau_packages/builders")
local audio    = require("@self/../luau_packages/audio")
local opus     = require("@self/../luau_packages/opus")
local env      = require("@self/../.env")

local SAMPLE_RATE = 48000

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
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
    local channel = bot:getVoiceChannelAsync("VOICE_CHANNEL_ID"):await():unwrapOk()

    channel.onAudioFrame:listen(function(data)
        local stats = opus.stats(data.frame, opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)

        print(`{data.userId or data.ssrc}: {string.format("%.1f", stats.dBFS)} dBFS`)
    end)

    local joined = channel:joinAsync():await()

    if joined:isErr() then
        bot.logger:warn(`could not join: {joined:unwrapErr()}`)

        return
    end

    local connection = joined:unwrapOk()

    connection.onClosed:listen(function(reason, code)
        bot.logger:info(`voice closed ({reason}, code {code}): {connection.closeDetail}`)
    end)

    local player = audio.player.new(connection)
    local played = player:playAsync(audio.fromPCM(tone(440, 2))):await()

    if played:isErr() then
        bot.logger:warn(`playback failed: {played:unwrapErr()}`)
    end
end)

bot:connectAsync():await()
```

</details>

## References

- [Bot](/classes/discordluau/bot) - the `discord.bot` class, `getVoiceChannelAsync` and the gateway events
- [Voice channel behaviour](/classes/classes/channels/voicebehaviour) - `channel:joinAsync()`, `leaveAsync()` and the voice events
- [Voice connection](/classes/voice/connection) - `Voice.Connection`, `onClosed`, `closeDetail` and `decodeAudio`
- [Audio player](/classes/audio/player) - `audio.player.new`, `playAsync` and `stop`
- [Audio source](/classes/audio/source) - `audio.fromPCM`, `audio.fromOpus`, `audio.fromFile`, `audio.fromEncoded`, the named file sources, `audio.fromStream` and `audio.fromProcess`
- [Opus stats](/classes/opus/stats) - `opus.stats`, the level of a decoded frame
- [Futures](/vendor/futures) - the `FutureLike` async primitive returned by async calls
