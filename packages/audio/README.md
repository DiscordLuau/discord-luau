<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Plays audio files, streams and raw PCM or Opus in discord-luau voice channels.

**Source:** [packages/audio](https://github.com/DiscordLuau/discord-luau/tree/main/packages/audio)

## Installation

```bash
pesde add discord_luau/audio
```

## Example

```luau
local audio = require("./luau_packages/audio")

local channel = bot:getVoiceChannelAsync(channelId):await():unwrapOk()
local connection = channel:joinAsync():await():unwrapOk()
local player = audio.player.new(connection)

player:playAsync(audio.fromFile("song.mp3")):await()
channel:leaveAsync():await()
```

Runs on Zune. The [Playing Music guide](https://discordluau-docs.devcomp.workers.dev/guides/playing-music) covers streaming with yt-dlp.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
