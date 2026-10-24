---
title: Playing and Receiving Voice
description: Join a voice channel, listen to speakers and play audio with discord-luau.
sidebar:
  order: 6
---

discord-luau can join a voice channel, give you each speaker's audio, and play audio of its own.

## Prerequisites

Voice needs the `GuildVoiceStates` intent and the **Connect** and **Speak** permissions in the channel. It runs on Zune, which loads the native audio libraries for you on the first run. Playing audio uses the audio package, and the receiving example below uses opus:

```bash
pesde add discord_luau/audio
pesde add discord_luau/opus
```

## Joining a channel

Call `channel:joinAsync()` on a voice channel. It resolves with the voice connection once it is ready.

```lua
local discord = require("@self/../luau_packages/discord")
local builders = require("@self/../luau_packages/builders")
local env = require("@self/../.env")

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds", "GuildVoiceStates" }):build(),
})

bot.onAllShardsReady:listenOnce(function()
    local channel = bot:getVoiceChannelAsync("VOICE_CHANNEL_ID"):await():unwrapOk()
    local connection = channel:joinAsync():await():unwrapOk()

    connection.onClosed:listen(function(reason)
        print(`voice closed: {reason}`)
    end)
end)

bot:connectAsync():await()
```

A server has one voice connection, so joining another channel in the same server leaves the first. Call `channel:leaveAsync()` to leave.

## Receiving audio

`channel.onAudioFrame` fires with each speaker's audio as 20 ms frames of 48 kHz stereo PCM.

```lua
local opus = require("@self/../luau_packages/opus")

channel.onAudioFrame:listen(function(data)
    local stats = opus.stats(data.frame, opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)

    print(`{data.userId}: {string.format("%.1f", stats.dBFS)} dBFS`)
end)
```

`channel.onSpeaking` fires when someone starts or stops talking. If you only need that, set `connection.decodeAudio = false` to skip decoding.

## Playing audio

Make a player for the connection and play a source on it. `playAsync` finishes when the audio ends.

```lua
local audio = require("@self/../luau_packages/audio")

local player = audio.player.new(connection)
local played = player:playAsync(audio.fromFile("song.mp3")):await()

if played:isErr() then
    print(`playback failed: {played:unwrapErr()}`)
end
```

Sources:

- `audio.fromFile(path)` plays an audio file: MP3, FLAC, Ogg, WAV, WebM, M4A and more.
- `audio.fromProcess(command, arguments)` plays what a program writes, such as yt-dlp.
- `audio.fromStream(read)` plays a file whose bytes a function returns piece by piece.
- `audio.fromPCM(pcm)` and `audio.fromOpus(packets)` play raw audio you made yourself.

Call `player:stop()` to end the current playback early. [Playing Music](/guides/playing-music) walks through files, downloads and streaming with yt-dlp.

:::note[One playback at a time]
A connection plays one source at a time. Wait for `playAsync` to finish before starting the next.
:::

## End-to-end encryption

Voice handles Discord's DAVE end-to-end encryption on its own. Until the bot has the channel's key, what it plays goes out as silence. Alone in a channel it never gets one, so it stays silent until someone joins.

## Troubleshooting

- `voice needs the GuildVoiceStates intent`: add `"GuildVoiceStates"` to your intents.
- `could not open audio: ...`: the file is missing or isn't audio.
- `could not start yt-dlp: FileNotFound`: the program isn't on your `PATH`.
- `onClosed` fires with `rejected` and code 4017: update `discord_luau/dave`.

## References

- [Bot](/classes/discordluau/bot) - `getVoiceChannelAsync` and the gateway events
- [Voice channel behaviour](/classes/classes/channels/voicebehaviour) - `joinAsync`, `leaveAsync` and the voice events
- [Voice connection](/classes/voice/connection) - `onClosed` and `decodeAudio`
- [Audio player](/classes/audio/player) - `audio.player.new`, `playAsync` and `stop`
- [Audio source](/classes/audio/source) - every audio source
- [Futures](/vendor/futures) - the `FutureLike` returned by async calls
