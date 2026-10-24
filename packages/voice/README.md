<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Discord voice connections: joining, sending and receiving audio, with DAVE end-to-end encryption.

**Source:** [packages/voice](https://github.com/DiscordLuau/discord-luau/tree/main/packages/voice)

## Installation

```bash
pesde add discord_luau/voice
```

## Example

```luau
local voice = require("./luau_packages/voice")

local connection = voice.connection.new({
	shard = shard,
	guildId = guildId,
	channelId = channelId,
	userId = botUserId,
	logLevel = "Info",
})

connection.onAudioFrame:listen(function(data)
	print(`audio from {data.userId}`)
end)

connection:joinAsync():await()
connection:sendOpusAsync(opusFrame):await()
connection:leaveAsync():await()
```

With `discord_luau`, `channel:joinAsync()` builds the connection for you, and `discord_luau/audio` plays files and streams on it.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
