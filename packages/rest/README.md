<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Typed interface for the Discord HTTP REST API.

**Source:** [packages/rest](https://github.com/DiscordLuau/discord-luau/tree/main/packages/rest)

## Installation

```bash
pesde add discord_luau/rest
```

## Example

```luau
local REST = require("./luau_packages/rest")

local request = REST.request.new({
    token = "Bot YOUR_TOKEN_HERE",
    restApiVersion = 10,
})

local channel = REST.channel:getChannelAsync(request, channelId):await()

print(channel.body.name)

REST.message:createMessageAsync(request, channelId, {
    content = "Hello from discord-luau!",
}):await()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
