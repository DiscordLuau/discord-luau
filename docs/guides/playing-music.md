---
title: Playing Music
description: Play, download and stream music in a voice channel with the audio package and yt-dlp.
sidebar:
  order: 7
---

This guide plays music in a voice channel: from a file, from a download, and streamed straight from YouTube.

## Prerequisites

Your bot needs the `GuildVoiceStates` intent and the **Connect** and **Speak** permissions in the channel. Install the audio package:

```bash
pesde add discord_luau/audio
```

For downloading and streaming, install [yt-dlp](https://github.com/yt-dlp/yt-dlp), plus [ffmpeg](https://ffmpeg.org) if you want MP3s.

## Playing a file

Join the channel, make a player, and play the file:

```lua
local discord = require("@self/../luau_packages/discord")
local builders = require("@self/../luau_packages/builders")
local audio = require("@self/../luau_packages/audio")
local env = require("@self/../.env")

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds", "GuildVoiceStates" }):build(),
})

bot.onAllShardsReady:listenOnce(function()
    local channel = bot:getVoiceChannelAsync("VOICE_CHANNEL_ID"):await():unwrapOk()
    local connection = channel:joinAsync():await():unwrapOk()
    local player = audio.player.new(connection)

    player:playAsync(audio.fromFile("song.mp3")):await()
    channel:leaveAsync():await()
end)

bot:connectAsync():await()
```

MP3, FLAC, Ogg, WAV, WebM and most other formats work.

## Downloading a song

Save a video's audio with yt-dlp, then play it as above:

```bash
yt-dlp -x --audio-format mp3 --no-playlist -o "song.%(ext)s" "https://www.youtube.com/watch?v=VIDEO_ID"
```

For the best quality, keep YouTube's own Opus audio instead. It needs no ffmpeg and plays without being re-encoded:

```bash
yt-dlp -f 251 --no-playlist -o song.webm "https://www.youtube.com/watch?v=VIDEO_ID"
```

## Streaming without downloading

`audio.fromProcess` plays whatever a program writes. Tell yt-dlp to write the audio out with `-o -`:

```lua
local url = "https://www.youtube.com/watch?v=VIDEO_ID"
local source = audio.fromProcess("yt-dlp", { "-f", "251", "--no-playlist", "-o", "-", url })

player:playAsync(source):await()
```

The song starts after about a second of buffering.

## Volume

Pass a volume from 0 to 4 when you make the source, or change it while it plays:

```lua
local source = audio.fromFile("song.mp3", { volume = 0.5 })

source:setVolume(1.5)
```

:::note[Volume and Opus]
Volume only works on audio the bot decodes. YouTube's format 251 is sent as it is, so download an MP3 if you need volume control.
:::

## Queueing songs

`playAsync` finishes when the song ends, so a loop plays songs one after another. `player:stop()` ends the current song and the loop moves on.

```lua
for _, path in { "first.mp3", "second.mp3", "third.mp3" } do
    player:playAsync(audio.fromFile(path)):await()
end
```

## Troubleshooting

- `could not open audio: ...`: the file is missing or isn't audio. Paths are relative to where you run the bot.
- `could not start yt-dlp: FileNotFound`: yt-dlp isn't on your `PATH`. Pass its full path instead of `"yt-dlp"`.
- `yt-dlp exited with code 1: ...`: yt-dlp failed; the rest of the message is its error. Update it with `yt-dlp -U`.
- The music pauses now and then while streaming: pass `{ bufferSeconds = 3 }` to `audio.fromProcess` to buffer more.

Only play music you have the right to share.
