<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Bit](https://pesde.dev/packages/discord_luau/bit)

DiscordLuau - Bit is a library that extends Luau with 64-bit operations. By default, Luau supports only 32-bit operations, but tasks such as calculating permissions and processing snowflakes require 64-bit capabilities.

### Installation

To use DiscordLuaus Bit, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/bit
```

### Getting Started

1. Require the library in your project:
```luau
local Bit = require("./luau_packages/bit")
```

2. Use the provided library to do something with bits:
```luau
local b = Bit.band(3, 42)
```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.