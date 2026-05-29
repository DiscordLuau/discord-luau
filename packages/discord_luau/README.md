<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

The entrypoint for the Discord Luau library, providing the `Bot` object used to connect to Discord and receive gateway events.

**Source:** [packages/discord_luau](https://github.com/DiscordLuau/discord-luau/tree/main/packages/discord_luau)

## Installation

```bash
pesde add discord_luau/discord_luau
```

## Example

```luau
local process = require("@lune/process")

local DiscordLuau = require("./lune_packages/discord_luau")

local intents = DiscordLuau.builders.intents.new()
    :addIntent("Guilds")
    :addIntent("GuildMessages")
    :build()

local bot = DiscordLuau.bot.new({
    token = process.env.DISCORD_BOT_TOKEN,
    intents = intents,
})

bot.onAllShardsReady:listen(function()
    print("Bot is ready")
end)

bot.onMessage:listen(function(message)
    if message.content == "!ping" then
        message:replyAsync({ content = "Pong!" }):await()
    end
end)

bot:connectAsync():await()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This project is licensed under the MIT License.
