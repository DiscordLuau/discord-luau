<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Collects sequential string chunks and exposes them atomically.

**Source:** [packages/accumulator](https://github.com/DiscordLuau/discord-luau/tree/main/packages/accumulator)

## Installation

```bash
pesde add discord_luau/accumulator
```

## Example

```luau
local Accumulator = require("./luau_packages/accumulator")

local accumulator = Accumulator.new()

accumulator:write("Hello, ")
accumulator:write("world!")

print(accumulator:size())
print(accumulator:peek())

local result = accumulator:flush()

print(result)
print(accumulator:size())
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
