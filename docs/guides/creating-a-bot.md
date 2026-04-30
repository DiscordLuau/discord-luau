---
title: Creating a Bot
description: Learn how to create your first Discord bot with discord-luau.
sidebar:
  order: 1
---

This guide walks through the code inside `src/init.luau` that `create_app` generates for you, explaining what each part does and why.

## Imports

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")

local env = require("@self/../.env")
```

- **`discord`** - the top-level package, exposes `discord.bot`
- **`classes`** - Luau types for Discord objects such as `classes.Message`, `classes.Guild`
- **`builders`** - builder objects for constructing API payloads (intents, messages, embeds, etc.)
- **`.env`** - your local environment file containing `DISCORD_BOT_TOKEN`

:::caution[Never hardcode your token]
Always load the token from `.env` or another secrets store. The generated `.gitignore` excludes `.env.luau` from version control for this reason.
:::

## Building intents

Intents tell Discord which gateway events to send your bot. You must request only what you need.

```lua
local DISCORD_BOT_INTENTS = builders.intents
    .new({
        "Guilds",
        "GuildMessages",
        "MessageContent",
    })
    :build()
```

`builders.intents.new()` accepts a list of intent names and `:build()` converts them into the bitfield integer that the Discord gateway expects.

:::note[MessageContent requires a portal toggle]
The `MessageContent` intent is privileged. You must enable it in the [Discord Developer Portal](https://discord.com/developers/applications) under your application's **Bot** tab, otherwise the bot will connect but `message.content` will always be empty.
:::

## Creating the bot

```lua
local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = DISCORD_BOT_INTENTS,
    reconnect = true,
})
```

| Option | Type | Description |
|---|---|---|
| `token` | `string` | Your bot token |
| `intents` | `number` | The bitfield produced by `builders.intents` |
| `reconnect` | `boolean?` | Automatically reconnect on disconnect |
| `logLevel` | `string?` | Log verbosity - `"Debug"`, `"Info"`, `"Warn"`, `"Error"` |

## Listening to events

Events are exposed as emitters on the bot object. Call `:listen()` to register a persistent handler, or `:listenOnce()` for a one-shot handler.

```lua
bot.onMessage:listen(function(message: classes.Message)
    print(`Message from '{message.author.globalName}': '{message.content}'`)
end)

bot.onAllShardsReady:listenOnce(function()
    print(`Bot '{bot.user.username}' is online!`)
end)
```

`onAllShardsReady` fires once all shards have connected and the `bot.user` and `bot.application` properties are populated. Use this event as the signal that the bot is fully ready.

## Connecting

```lua
bot:connectAsync():await()
```

`connectAsync()` queries the Discord gateway, opens the WebSocket connection, and begins dispatching events. Calling `:await()` on it keeps the main thread alive for the lifetime of the bot.

:::danger[You must await or poll connectAsync]
`connectAsync()` returns a `FutureLike`. If you discard it without calling `:await()` or `:poll()`, the bot will never connect. See the [Futures](/vendor/futures) guide for details.
:::

<details>
<summary>Full script</summary>

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")

local env = require("@self/../.env")

local DISCORD_BOT_INTENTS = builders.intents
    .new({
        "Guilds",
        "GuildMessages",
        "MessageContent",
    })
    :build()

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = DISCORD_BOT_INTENTS,
    reconnect = true,
})

bot.onMessage:listen(function(message: classes.Message)
    print(`Message from '{message.author.globalName}': '{message.content}'`)
end)

bot.onAllShardsReady:listenOnce(function()
    print(`Bot '{bot.user.username}' is online!`)
end)

bot:connectAsync():await()
```

</details>

## References

- [Bot](/classes/discordluau/bot) - the `discord.bot` class, gateway connection and event emitters
- [Intents builder](/classes/builders/intents) - `builders.intents`, constructs the gateway intent bitfield
- [Message class](/classes/classes/message) - `classes.Message`, the object passed to `onMessage` handlers
- [Futures](/vendor/futures) - the `FutureLike` async primitive returned by `connectAsync` and other async calls
