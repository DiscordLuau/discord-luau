<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Luau type definitions for the Discord API.

**Source:** [packages/api_types](https://github.com/DiscordLuau/discord-luau/tree/main/packages/api_types)

## Installation

```bash
pesde add discord_luau/api_types
```

## Example

```luau
local ApiTypes = require("./luau_packages/api_types")

local message: ApiTypes.Message = {
	id = "1234567890",
	content = "Hello, world!",
	author = { id = "9876543210", username = "Luau" },
}
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
