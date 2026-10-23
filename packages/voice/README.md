<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Implementation of the Discord voice protocol, including WebSocket signalling, UDP audio transport, RTP encryption, and DAVE E2EE support.

**Source:** [packages/voice](https://github.com/DiscordLuau/discord-luau/tree/main/packages/voice)

Voice runs on Zune only: it depends on `opus`, `sodium` and `dave`, which load native libraries through FFI.

## Installation

```bash
pesde add discord_luau/voice
```

To play audio, add the player as well:

```bash
pesde add discord_luau/audio
```

## Example

```luau
local audio = require("./luau_packages/audio")
local voice = require("./luau_packages/voice")

local connection = voice.connection.new({
    shard = shard,
    guildId = "1234567890",
    channelId = "0987654321",
    userId = botUserId,
    logLevel = "Info",
})

connection.onAudioFrame:listen(function(data)
    print(`audio from {data.userId}, ssrc={data.ssrc}`)
end)

connection:joinAsync():await()

local played = audio.player.new(connection):playAsync(audio.fromOpus(packets)):await()

print(if played:isOk() then played:unwrapOk() else played:unwrapErr())

connection:leaveAsync():await()
```

`shard` is the gateway shard that serves the guild and `botUserId` is the bot's user id; with `discord_luau`, `channel:joinAsync()` on a channel from `bot:getVoiceChannelAsync(channelId)` builds the connection from both for you. `packets` is an array of Opus packets. The [`discord_luau/audio`](https://github.com/DiscordLuau/discord-luau/tree/main/packages/audio) player sends Speaking before the first packet, paces each packet by its duration, ends with five silence frames and Speaking 0, and plays 48 kHz stereo PCM through `audio.fromPCM` too. `connection:sendOpusAsync(frame)` sends one frame as it is, with no pacing and no Speaking.

Listen to `connection.onClosed(reason, code)` to learn when a connection ends for good; the gateway needs the `GuildVoiceStates` intent.

In a channel with DAVE end-to-end encryption, `onReady` comes before the bot holds the group's key. `connection:awaitMediaReadyAsync(timeoutSeconds)` waits for it, `connection.onMediaReady` fires when it arrives, and `connection.dave.mediaReady` says whether audio can flow now; the audio player waits for media readiness itself. Until then `sendOpusAsync` sends Opus silence in place of each frame, so no audio leaves without end-to-end encryption.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
