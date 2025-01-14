<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Buffer](https://pesde.dev/packages/discord_luau/buffer)

DiscordLuau - Buffer, not to be confused with the luau buffer datatype, is a library that helps us temporary buffer binary data, this is required as discord may send up parts of a chunk - and not the entire chunk, so we need to buffer the data until we have the entire chunk.

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