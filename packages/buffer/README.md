<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Buffer](https://pesde.dev/packages/discord_luau/buffer)

DiscordLuau - Buffer, not to be confused with the Luau buffer datatype, this library temporarily buffers binary data. Since Discord may send data in chunks rather than all at once, buffering ensures we collect the full chunk before processing.

### Installation

To use DiscordLuaus Bit, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/buffer
```

### Getting Started

1. Require the library in your project:
```luau
local Buffer = require("./luau_packages/buffer")
```

2. Use the provided library to store/flush binary data:
```luau
local zlibBuffer = Buffer.new()

zlibBuffer:write(xyz)

...

local completeMessage = zlibBuffer:flush()
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.