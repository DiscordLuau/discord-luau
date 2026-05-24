---
title: Getting Started
description: Set up the commands framework, load commands from disk, and register them with Discord.
sidebar:
  order: 1
---

The commands framework is a separate package that sits on top of the core discord-luau bot, handling routing, guards, cooldowns, and more. This page gets you from setup to a working slash command.

## Installation

Add the commands package to your project alongside the core library.

```lua
local commands = require("../luau_packages/commands")
```

## Creating a Commands instance

Pass your bot to `Commands.new`. It wires up all interaction listeners automatically.

```lua
local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds" }):build(),
    reconnect = true,
})

local commandsManager = commands.new(bot)

bot:connectAsync():await()
```

| Option | Type | Default | Description |
|---|---|---|---|
| `help` | `boolean?` | `true` | Register the built-in `/help` command |
| `watch` | `boolean?` | `true` | Auto-watch loaded directories for changes |
| `context` | `any?` | `nil` | Shared value passed to every command factory |
| `onError` | `ErrorHandler?` | - | Global fallback when a command throws |
| `onGuardFailed` | `GuardFailedHandler?` | - | Global fallback when a guard rejects |

## Writing a command

Each command is a table matching `CommandDefinition`. Create a file under your commands directory, e.g. `src/commands/ping.luau`.

```lua
local builders = require("../../luau_packages/builders")
local classes = require("../../luau_packages/classes")

return {
    command = builders.interaction.interaction.new()
        :setName("ping")
        :setDescription("Replies with Pong!")
        :addIntegrationType("GuildInstall")
        :addContext("Guild")
        :build(),

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Pong!" }):await()
    end,
}
```

## Loading commands from disk

`commands:load()` recursively finds every `.luau` file under the given directory and registers it. If `watch` is enabled (the default), it also starts watching for file changes so commands hot-reload on save.

```lua
bot.onAllShardsReady:listenOnce(function()
    commandsManager:load("src/commands")
    commandsManager:registerAsync():await()
end)
```

:::note[Register once, not on every startup]
`registerAsync` pushes your command list to Discord's API. Calling it on every startup is wasteful and hits rate limits. Once your command signatures are stable, remove the call and only re-run it when the schema changes.
:::

## Registering to a guild

Guild commands propagate instantly, making them ideal during development.

```lua
commandsManager:registerGuildAsync("YOUR_GUILD_ID"):await()
```

## Unregistering commands

To clear all global commands from Discord:

```lua
commandsManager:unregisterAsync():await()
```

To clear a specific guild's commands:

```lua
commandsManager:unregisterGuildAsync("YOUR_GUILD_ID"):await()
```

## The built-in /help command

`Commands.new` registers a `/help` command automatically. It paginates all registered commands by category using Discord's Components V2, with Previous / Next navigation. Disable it by passing `help = false`.

```lua
local commandsManager = commands.new(bot, { help = false })
```

<details>
<summary>Full script</summary>

```lua
local discord = require("../luau_packages/discord")
local builders = require("../luau_packages/builders")
local commands = require("../luau_packages/commands")
local env = require("../.env")

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds" }):build(),
    reconnect = true,
})

local commandsManager = commands.new(bot)

bot.onAllShardsReady:listenOnce(function()
    commandsManager:load("src/commands")
    commandsManager:registerAsync():await()
end)

bot:connectAsync():await()
```

</details>

## References

- [Command Options & Transforms](/guides/commands-framework/options-and-transforms) - typed options and value pre-processing
- [Guards & Permissions](/guides/commands-framework/guards-and-permissions) - restricting who can run a command
- [Hot Reload & Plugins](/guides/commands-framework/hot-reload-and-plugins) - file watching and the plugin system
