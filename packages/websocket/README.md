<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Implementation of the Discord WebSocket gateway connection, providing multi-shard management, heartbeating, session resumption, and event dispatch.

**Source:** [packages/websocket](https://github.com/DiscordLuau/discord-luau/tree/main/packages/websocket)

## Installation

```bash
pesde add discord_luau/websocket
```

## Example

```luau
local WebSocket = require("./luau_packages/websocket")

local manager = WebSocket.manager.new({
	token = botToken,
	intents = 513,
	webSocketVersion = 10,
	largeThreshold = 250,
	reconnect = true,
})

manager.onAllShardsReady:listen(function()
	print("All shards ready")
end)

manager.onDispatch:listen(function(payload)
	print("Event:", payload.event)
end)

manager:connectAsync(gatewayInfo):await()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
