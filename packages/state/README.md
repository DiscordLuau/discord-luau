<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Shared state container for a discord-luau bot, holding the REST client, gateway connection, and in-memory cache for guilds, channels, users, and roles.

**Source:** [packages/state](https://github.com/DiscordLuau/discord-luau/tree/main/packages/state)

## Installation

```bash
pesde add discord_luau/state
```

## Example

```luau
local State = require("./luau_packages/state")

local state = State.state.new({
    token = "Bot YOUR_TOKEN_HERE",
    intents = 513,
    version = 10,
    reconnect = true,
})

local guild = state.cache.guilds:get("1234567890")

-- Evict on GUILD_DELETE
state.cache.guilds:remove("1234567890")
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
