<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## DiscordLuau - WebSocket

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
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.