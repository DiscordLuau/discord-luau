<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

A variety of utility functions for Discord-Luau.

**Source:** [packages/utilities](https://github.com/DiscordLuau/discord-luau/tree/main/packages/utilities)

## Installation

```bash
pesde add discord_luau/util
```

## Example

```luau
local Utilities = require("./luau_packages/util")

print(Utilities.validateKebabCase("general-chat"))

print(Utilities.validateKebabCase("General Chat"))

print(Utilities.validateCommandName("ping"))

print(Utilities.validateCommandName("My Command"))

local id = Utilities.createGuid()

print(id) -- e.g. "3f2504e0-4f89-41d3-9a0c-0305e82c3301"

local flags = Utilities.tableReflect({ READ = 1, WRITE = 2 })

print(flags.READ)

print(flags[1])
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
