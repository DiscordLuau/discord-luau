<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Stream](https://pesde.dev/packages/discord_luau/stream)

DiscordLuau - Stream, otherwise known as a string stream, is a way to navigate through a string - this is often useful for parsing data such as FormData.

### Installation

To use DiscordLuau Stream, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/stream
```

### Getting Started

1. Require the library in your project:
```luau
local Stream = require("./lune_packages/stream")
```

2. Use the provided library to create a valid string stream object:
```luau
local object = Stream.new("hello, world!")

print(object:advance(5))
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.