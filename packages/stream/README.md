<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Stream implementation used to navigate through strings safely.

**Source:** [packages/stream](https://github.com/DiscordLuau/discord-luau/tree/main/packages/stream)

## Installation

```bash
pesde add discord_luau/stream
```

## Example

```luau
local Stream = require("./luau_packages/stream")

local stream = Stream.new("Content-Type: text/plain\r\n")

local key = stream:advanceUntil(function(character)
    return character == ":"
end)

stream:advance(2)
stream:trim()

local value = stream:readUntilEnd()

print(key) -- "Content-Type"
print(value) -- "text/plain"
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
