<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Secret](https://pesde.dev/packages/discord_luau/secret)

DiscordLuau - Secret provides a way to display secrets in the console, in the event you accidently print them. This is used when handling any discord bot tokens in order to make sure they are not leaked.

### Installation

To use DiscordLuau Secret, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/secret
```

### Getting Started

1. Require the library in your project:
```luau
local Secret = require("./lune_packages/secret")
```

2. Use the provided library to create a valid secret object:
```luau
local secret = Secret.new("something-secret")

print(secret == xyz)
print(#secret)
print(tostring(secret))
```

### Contributing

See the [Contributing Guide](CONTRIBUTING) for more information on how to contribute to this project.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.