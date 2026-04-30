---
title: Slash Commands
description: Register and respond to Discord slash commands with discord-luau.
sidebar:
  order: 2
---

This guide covers registering a global slash command and responding to it when a user runs it.

## Building a command

Use `builders.interaction.interaction` to describe the command before registering it.

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")
local env      = require("@self/../.env")

local pingCommand = builders.interaction.interaction.new()
    :setName("ping")
    :setDescription("Replies with Pong!")
    :setType("ChatInput")
    :addIntegrationType("GuildInstall")
    :addContext("Guild")
    :build()
```

| Method | Required | Notes |
|---|---|---|
| `:setName(name)` | Yes | 1-32 characters, lowercase |
| `:setDescription(desc)` | Yes | 1-100 characters |
| `:setType(type)` | No | `"ChatInput"` for slash commands (default when omitted) |
| `:addIntegrationType(type)` | Yes | At least one - `"GuildInstall"` or `"UserInstall"` |
| `:addContext(context)` | Yes | At least one - `"Guild"`, `"BotDm"`, or `"PrivateChannel"` |

## Registering the command

Global commands are registered via `bot.application`, which is available after `onAllShardsReady`. Registration is asynchronous - global commands can take up to an hour to propagate to all Discord servers.

```lua
local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds" }):build(),
    reconnect = true,
})

bot.onAllShardsReady:listenOnce(function()
    local result = bot.application:createSlashCommandAsync(pingCommand):await()

    if result:isErr() then
        warn("Failed to register command:", result:unwrapErr())
        return
    end

    print("Registered command:", result:unwrapOk().name)
end)
```

:::note[Register once, not on every startup]
Calling `createSlashCommandAsync` on every startup is wasteful and will hit rate limits. Register commands once, then comment out or remove the registration call. For iteration, use guild-scoped commands (not yet covered here) which propagate instantly.
:::

## Handling the interaction

Listen to `bot.onCommandInteraction` to receive slash command interactions. The interaction object provides `:messageAsync()` to send a response.

```lua
bot.onCommandInteraction:listen(function(interaction: classes.TypesCommand)
    if interaction.data.name ~= "ping" then
        return
    end

    interaction:messageAsync(
        builders.message.message.new()
            :setContent("Pong!")
            :build()
    ):await()
end)

bot:connectAsync():await()
```

## Adding options

Use `builders.interaction.option` to add parameters to a command. Options must be built and passed to `:addOption()` before calling `:build()` on the command.

```lua
local greetCommand = builders.interaction.interaction.new()
    :setName("greet")
    :setDescription("Greet a user by name")
    :setType("ChatInput")
    :addIntegrationType("GuildInstall")
    :addContext("Guild")
    :addOption(
        builders.interaction.option.new()
            :setType("String")
            :setName("name")
            :setDescription("The name to greet")
            :build()
    )
    :build()
```

## Deferring a response

If your handler needs more than three seconds (e.g. to fetch data), defer the interaction first to show a loading state, then edit the response when ready.

```lua
bot.onCommandInteraction:listen(function(interaction: classes.TypesCommand)
    if interaction.data.name ~= "slow" then
        return
    end

    interaction:deferAsync():await()

    -- ... do slow work ...

    interaction:editResponseAsync(
        builders.message.message.new()
            :setContent("Done!")
            :build()
    ):await()
end)
```

<details>
<summary>Full script</summary>

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")
local env      = require("@self/../.env")

local pingCommand = builders.interaction.interaction.new()
    :setName("ping")
    :setDescription("Replies with Pong!")
    :setType("ChatInput")
    :addIntegrationType("GuildInstall")
    :addContext("Guild")
    :build()

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds" }):build(),
    reconnect = true,
})

bot.onAllShardsReady:listenOnce(function()
    local result = bot.application:createSlashCommandAsync(pingCommand):await()

    if result:isErr() then
        warn("Failed to register command:", result:unwrapErr())
        return
    end

    print("Registered command:", result:unwrapOk().name)
end)

bot.onCommandInteraction:listen(function(interaction: classes.TypesCommand)
    if interaction.data.name ~= "ping" then
        return
    end

    interaction:messageAsync(
        builders.message.message.new()
            :setContent("Pong!")
            :build()
    ):await()
end)

bot:connectAsync():await()
```

</details>

## References

- [Bot](/classes/discordluau/bot) - the `discord.bot` class, gateway connection and event emitters
- [Interaction builder](/classes/builders/interaction) - `builders.interaction.interaction`, constructs slash command definitions
- [Interaction Option builder](/classes/builders/interaction/option) - `builders.interaction.option`, adds typed parameters to commands
- [Message builder](/classes/builders/message) - `builders.message.message`, constructs response payloads
- [Intents builder](/classes/builders/intents) - `builders.intents`, constructs the gateway intent bitfield
- [Futures](/vendor/futures) - the `FutureLike` async primitive returned by async calls
