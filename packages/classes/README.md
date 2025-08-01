<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Classes](https://pesde.dev/packages/discord_luau/classes)

DiscordLuau - Classes provide a collection of classes designed to interact with the Discord API. For example, if you want to interact with a Discord message, the Discord Message Class offers all the methods and properties needed to seamlessly work with a Discord message.

### Installation

To use DiscordLuau Classes, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/classes
```

### Getting Started

1. Require the library in your project:
```luau
local Classes = require("./lune_packages/classes")
```

2. Use the provided library to create a valid discord class:
```luau
local discordMessageJson = getDiscordMessage(messageId)
local discordMessageClass = Classes.message.message.new(state, discordChannelJson)

discordMessageClass:replyAsync({
	content = "Hello World!",
})
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.