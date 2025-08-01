<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - State](https://pesde.dev/packages/discord_luau/state)

DiscordLuau - State provides a single source of truth for your discord bots state, generally shared between the REST and Gateway libraries.

This is what stores, as well as handles the following:

- Discord Websockets
- Discord API Token
- Application ID
- Discord API Version
- Discord Intents
- Discord Cache

### Installation

To use DiscordLuau State, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/state
```

### Getting Started

1. Require the library in your project:
```luau
local State = require("./lune_packages/state")
```

2. Use the provided library to create a valid snowflake object:
```luau
local object = State.new(
	"", -- token
	0, -- intents
	10 -- api version
)
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.