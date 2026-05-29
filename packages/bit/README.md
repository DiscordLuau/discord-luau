<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Bit library for Luau supporting integers up to 52 bits, intended for working with Discord permission flags.

**Source:** [packages/bit](https://github.com/DiscordLuau/discord-luau/tree/main/packages/bit)

## Installation

```bash
pesde add discord_luau/bit
```

## Example

```luau
local Bit = require("./luau_packages/bit")

local SEND_MESSAGES = Bit.lshift(1, 11)

local MANAGE_CHANNELS = Bit.lshift(1, 4)

local permissions = Bit.bor(SEND_MESSAGES, MANAGE_CHANNELS)

print(Bit.band(permissions, SEND_MESSAGES) ~= 0)

-- Works with permission values beyond 32 bits
local HIGH_PERMISSION = Bit.lshift(1, 46)

local combined = Bit.bor(permissions, HIGH_PERMISSION)

print(Bit.band(combined, HIGH_PERMISSION) ~= 0)
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
