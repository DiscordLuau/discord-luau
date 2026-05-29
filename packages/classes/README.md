<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Objects that wrap around various Discord API structures such as messages, guilds, channels, and users.

**Source:** [packages/classes](https://github.com/DiscordLuau/discord-luau/tree/main/packages/classes)

## Installation

```bash
pesde add discord_luau/classes
```

## Example

```luau
local Classes = require("./luau_packages/classes")

local channel = Classes.channels.construct(state, rawChannelData)

local message = channel:sendMessageAsync({
	content = "Hello from discord-luau!",
}):await()

message:replyAsync({ content = "And here is the reply." }):await()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
