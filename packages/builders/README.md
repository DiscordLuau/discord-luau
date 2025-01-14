<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Builders](https://pesde.dev/packages/discord_luau/builders)

DiscordLuau - Builders is a package that provides a collection of builders designed to create and modify objects compatible with the Discord API.

Builders are designed to handle both the creation and modification of Discord-compatible data structures, ensuring flexibility and ease of use.

### Installation

To use DiscordLuau Builders, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/builders
```

### Getting Started

1. Require the library in your project:
```luau
local Builders = require("./luau_packages/builders")
```

2. Use the provided library to create a discord-compatible object:
```luau
local channelObject = Builders.channel.new()
	:setName(`my-channel`)
	:setTopic(`my-topic`)
	:setType(`GuildText`)
	:build()
```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.