---
title: Playing Music
description: Play, download and stream music in a voice channel with the audio package and yt-dlp.
sidebar:
  order: 7
---

This guide gets your bot playing music in a voice channel. You'll play a file from disk, download a song with yt-dlp, and then stream one without saving it at all.

## What you need

- A bot with the `GuildVoiceStates` intent, and the **Connect** and **Speak** permissions in the voice channel.
- Zune. Audio uses native libraries that Zune loads for you on the first run.
- The audio package:

```bash
pesde add discord_luau/audio
```

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) for the download and stream steps, plus [ffmpeg](https://ffmpeg.org) if you want MP3s. Check yt-dlp runs:

```bash
yt-dlp --version
```

## Play a file

Put an audio file where you run your bot, called `song.mp3`. MP3, FLAC, Ogg, WAV, WebM and most other formats work. Then run:

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

    local played = player:playAsync(audio.fromFile("song.mp3")):await()

    if played:isErr() then
        bot.logger:warn(`playback failed: {played:unwrapErr()}`)
    end

    channel:leaveAsync():await()
end)

bot:connectAsync():await()
```

Swap `VOICE_CHANNEL_ID` for your channel's ID. Turn on Developer Mode in Discord, right-click the channel and pick **Copy Channel ID**.

That's the whole recipe:

- `channel:joinAsync()` joins the channel and gives you its voice connection.
- `audio.player.new(connection)` makes a player for that connection.
- `player:playAsync(source)` plays a source and finishes when the song ends.

## Download a song

yt-dlp saves a video's audio to a file. This command saves an MP3, which needs ffmpeg:

```bash
yt-dlp -x --audio-format mp3 --no-playlist -o "song.%(ext)s" "https://www.youtube.com/watch?v=VIDEO_ID"
```

Play `song.mp3` exactly as above.

To skip ffmpeg and get the best quality from YouTube, download its own audio instead:

```bash
yt-dlp -f 251 --no-playlist -o song.webm "https://www.youtube.com/watch?v=VIDEO_ID"
```

Format 251 is Opus, the codec Discord itself uses. The bot sends it as it is, without re-encoding it, so it sounds closest to the original. Play it with `audio.fromFile("song.webm")`.

Only play music you have the right to share.

## Stream without downloading

`audio.fromProcess` runs a program and plays whatever it writes. Ask yt-dlp to write the audio to its output with `-o -`:

```lua
local url = "https://www.youtube.com/watch?v=VIDEO_ID"
local source = audio.fromProcess("yt-dlp", { "-f", "251", "--no-playlist", "-o", "-", url })

local played = player:playAsync(source):await()
```

The song starts after about a second of buffering. If yt-dlp falls behind or the voice connection drops for a moment, the bot pauses cleanly and carries on where it left off.

`--no-playlist` plays just the one video when the link has a `&list=` in it.

## Volume

Pass a volume when you make the source. The original level is 1, and the range runs from 0 to 4:

```lua
local source = audio.fromFile("song.mp3", { volume = 0.5 })
```

Call `source:setVolume(1.5)` to change it while the song plays.

Volume only works on audio the bot decodes, such as MP3. YouTube's format 251 is sent untouched, so volume has no effect on it. Download an MP3 if you need volume control.

## Queues and skipping

`playAsync` finishes when a song ends, so a loop plays songs one after another:

```lua
for _, path in { "first.mp3", "second.mp3", "third.mp3" } do
    player:playAsync(audio.fromFile(path)):await()
end
```

`player:stop()` ends the current song early, so the loop moves on to the next one. Call it from a `/skip` command, for example.

A player plays one song at a time. Start the next song only after the last one has finished.

## When something goes wrong

- `voice needs the GuildVoiceStates intent`: add `"GuildVoiceStates"` to your bot's intents.
- `could not open audio: ...`: the file is missing or isn't audio. Paths are relative to the folder you run the bot from.
- `could not start yt-dlp: FileNotFound`: yt-dlp isn't on your `PATH`. Pass its full path to `audio.fromProcess` instead of `"yt-dlp"`.
- `yt-dlp exited with code 1: ...`: yt-dlp itself failed, and the rest of the message is its error. YouTube changes often, so update yt-dlp with `yt-dlp -U` and try again.
- The music pauses now and then while streaming: the stream can't keep up. Pass `{ bufferSeconds = 3 }` as the last argument to `audio.fromProcess` to buffer more before playing.

## Going further

- [Playing and Receiving Voice](/guides/voice) covers what happens when the connection drops, receiving audio, and end-to-end encryption.
- The [audio README](https://github.com/DiscordLuau/discord-luau/tree/main/packages/audio) lists every source, option and error message.
