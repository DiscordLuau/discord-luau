<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Emitter](https://pesde.dev/packages/discord_luau/emitter)

DicordLuau - Emitter provides a simple event emitter for DiscordLuau, it's a simple way to listen and emit events.

### Installation

To use DiscordLuau Emitter, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/emitter
```

### Getting Started

1. Require the library in your project:
```luau
local Emitter = require("./lune_packages/emitter")
```

2. Use the provided library to create a valid discord class:
```luau
local event = Emitter.new()

event:listenOnce(function()
	doSomething()
end)

...

event:invoke()
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.