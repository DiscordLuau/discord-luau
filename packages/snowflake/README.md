<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## DiscordLuau - Snowflake

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
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.