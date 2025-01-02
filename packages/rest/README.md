<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## DiscordLuau - REST

DiscordLuau - REST provides typed functions for interacting with the Discord REST API, allowing you to easily fetch and manipulate data from Discord.

### Installation

To use DiscordLuau REST, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/rest
```

### Getting Started

1. Require the library in your project:
```luau
local REST = require("./lune_packages/rest")
```

2. Use the provided library to fetch a channel object:
```luau
local request = REST.request.new({
	token = `discord-bot-token`,
	restApiVersion = 10,
})

local channelObject = REST.channel:getChannelAsync(request, channelId)
```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.