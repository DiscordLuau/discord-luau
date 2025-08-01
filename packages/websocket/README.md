<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - WebSocket](https://pesde.dev/packages/discord_luau/websocket
)

DiscordLuau - WebSocket provides bindings for the Discord WebSocket API. This package is responsible for providing the core functionality for the DiscordLuau client.

### Installation

To use DiscordLuau WebSocket, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/websocket
```

### Getting Started

1. Require the library in your project:
```luau
local WebSocket = require("./lune_packages/websocket")
```

2. Use the provided library to create a valid string stream object:
```luau
local manager = websocket.manager.new({
	token = secretToken,
	intents = intents,
	webSocketVersion = version,
	largeThreshold = 250,
})

manager:connectAsync()
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License

See the [LICENSE](LICENSE) file for more information.