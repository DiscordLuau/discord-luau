<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

A commands framework for discord-luau, handling slash commands, components, modals, and autocomplete with support for guards, cooldowns, and subcommands.

**Source:** [packages/commands](https://github.com/DiscordLuau/discord-luau/tree/main/packages/commands)

## Installation

```bash
pesde add discord_luau/commands
```

## Example

```luau
local DiscordLuau = require("./luau_packages/discord_luau")

local Commands = require("./luau_packages/commands")

local bot = DiscordLuau.bot.new({ token = process.env.DISCORD_TOKEN })

local commands = Commands.new(bot)

commands:add({
    command = DiscordLuau.builders.interaction.interaction.new()
        :setName("ping")
        :setDescription("Replies with pong")
        :setType("ChatInput")
        :build(),

    execute = function(interaction)
        interaction:messageAsync({ content = "Pong!" }):await()
    end,
})

bot.onAllShardsReady:listen(function()
    commands:registerAsync():await()
end)

bot:connectAsync():await()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
