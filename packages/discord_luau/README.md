<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## DiscordLuau

the DiscordLuau package represents the core of the Discord Luau Library. It serves as the primary interface for developers to build their own Discord bots and applications.

### Installation

To use DiscordLuau, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/discord_luau
```

### Getting Started

1. Require the library in your project:
```luau
local DiscordLuau = require("./lune_packages/discord_luau")
```

2. Use the provided luau library:
```luau
local discordBot = discordLuau.Bot.new({
	intents = builders.intents.new({ "Guilds" }):build(),
	token = env.DISCORD_BOT_TOKEN,
})

discordBot.onAllShardsReady:listen(function()
	print("we're up and running!")
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)

```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.