<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Handles sensitive strings such as bot tokens, preventing them from being accidentally leaked into console output.

**Source:** [packages/secret](https://github.com/DiscordLuau/discord-luau/tree/main/packages/secret)

## Installation

```bash
pesde add discord_luau/secret
```

## Example

```luau
local Secret = require("./luau_packages/secret")

local token = Secret.new("Bot mY.sUp3r.S3cr3tT0k3n")

-- Safe to print - only a portion is revealed
print(token) -- Secret(Bot mY.sUp3r.S------------------)

print(token == Secret.new("Bot mY.sUp3r.S3cr3tT0k3n")) -- true
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
