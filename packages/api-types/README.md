<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## DiscordLuau - Types

DiscordLuau - Types is a comprehensive library providing Luau types for all Discord v10 APIs. It is designed to help developers effectively type HTTP and WebSocket requests they receive from the Discord API, enabling better code clarity, safety, and development efficiency.

### Installation

To use DiscordLuau - Types, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/api_types
```

### Getting Started

1. Require the library in your project:
```luau
local DiscordTypes = require("./luau_packages/api_types")
```

2. Use the provided types to structure your Discord API requests and responses:
```luau
local channel = getChannel(channelId) :: DiscordTypes.GetChannelResponse
```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.