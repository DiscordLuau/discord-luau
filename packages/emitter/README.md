<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

A signal/event emitter for Luau.

**Source:** [packages/emitter](https://github.com/DiscordLuau/discord-luau/tree/main/packages/emitter)

## Installation

```bash
pesde add discord_luau/emitter
```

## Example

```luau
local Emitter = require("./luau_packages/emitter")

local onMessage = Emitter.new()

local connection = onMessage:listen(function(message)
	print("Received:", message)
end)

onMessage:fire("Hello, world!")

connection:disconnect()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
