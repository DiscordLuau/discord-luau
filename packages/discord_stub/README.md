<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

A local Discord gateway, REST and voice server for testing bots without connecting to Discord.

**Source:** [packages/discord_stub](https://github.com/DiscordLuau/discord-luau/tree/main/packages/discord_stub)

## Installation

```bash
pesde add discord_luau/discord_stub --dev
```

## Example

```luau
local discordLuau = require("./luau_packages/discord_luau")
local discordStub = require("./luau_packages/discord_stub")
local stdPolyfills = require("./luau_packages/std_polyfills")

local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
local gateway = stub:createWebsocketServer()

stub:createHttpServer()

local bot = discordLuau.bot.new({ token = "stub-token", intents = 0, isUsingStub = stub })

bot:connectAsync():await()
gateway:dispatch("MESSAGE_CREATE", messageData)

stub:stop()
```

`clock = "virtual"` runs the stub's time 100 times faster, so timeouts and heartbeats take moments in tests.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
