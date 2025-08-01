<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Snowflake](https://pesde.dev/packages/discord_luau/snowflake)

DiscordLuau - Snowflake provides a way to parse Disord snowflakes into their respective components.

### Installation

To use DiscordLuau Snowflake, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/snowflake
```

### Getting Started

1. Require the library in your project:
```luau
local Snowflake = require("./lune_packages/snowflake")
```

2. Use the provided library to create a valid snowflake object:
```luau
local object = Snowflake.new("123456789012345678")

local timestamp = object:getTimestamp()
local workerId = object:getWorkerId()
local processId = object:getProcessId()
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.