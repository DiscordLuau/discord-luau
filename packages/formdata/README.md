<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - FormData](https://pesde.dev/packages/discord_luau/formdata)

DiscordLuau - FormData provides tools for developers to parse and create FormData objects for sending data to Discord.

Notably, this library is designed with general-purpose use in mind and can be utilized beyond the scope of Discord Luau projects.

### Installation

To use DiscordLuau FormData, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/formdata
```

### Getting Started

1. Require the library in your project:
```luau
local FormData = require("./lune_packages/formdata")
```

2. Use the provided library to create a valid formdata object:
```luau
local formdata = FormData.new()

formdataObject:append(`key`, `value`, `filename.txt`)

...

local body = formdataObject:getBody()
local header =  formdataObject:getHeader()
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.