<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Logger](https://pesde.dev/packages/discord_luau/logger)

DiscordLuau - Logger provides a simple class for logging messages to the console. It takes advantage of ASCII colors to make the output more readable.

### Installation

To use DiscordLuau Logger, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/logger
```

### Getting Started

1. Require the library in your project:
```luau
local Logger = require("./lune_packages/logger")
```

2. Use the provided library to create a valid log object:
```luau
local log = Logger.new()

log:Info(`This is an info message!`)
log:Warn(`This is a warning message!`)
```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.