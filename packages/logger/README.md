<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Logging implementation for Discord-Luau, supporting eight log levels with ANSI-colored console output.

**Source:** [packages/logger](https://github.com/DiscordLuau/discord-luau/tree/main/packages/logger)

## Installation

```bash
pesde add discord_luau/logger
```

## Example

```luau
local Logger = require("./luau_packages/logger")

local logger = Logger.new("MyBot", "Debug")

logger:debug("Starting up...")
logger:info("Connected to Discord")
logger:warn("Rate limit approaching")
logger:error("Failed to send message")
```

Available log levels in ascending order of severity: `Debug`, `Info`, `Notice`, `Warn`, `Error`, `Critical`, `Alert`, `Emergency`.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
