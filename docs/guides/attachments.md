---
title: Sending Attachments
description: Upload and send file attachments with discord-luau.
sidebar:
  order: 4
---

Attachments let you upload files directly to Discord. discord-luau supports sending them by providing the raw file content as a string.

## Prerequisites

This guide uses the `onMessage` event, which requires the `MessageContent` intent. Make sure it is enabled in the [Discord Developer Portal](https://discord.com/developers/applications) under your application's **Bot** tab.

## Adding an attachment to a message

Call `:addAttachment(content, name)` on a `builders.message.message` object, where `content` is the raw file data as a string and `name` is the filename that will appear in Discord.

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")
local env      = require("@self/../.env")

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds", "GuildMessages", "MessageContent" }):build(),
    reconnect = true,
})

bot.onMessage:listen(function(message: classes.Message)
    if message.content ~= "!file" then
        return
    end

    message:replyAsync(
        builders.message.message.new()
            :addAttachment("Hello from discord-luau!", "hello.txt")
            :build()
    ):await()
end)

bot.onAllShardsReady:listenOnce(function()
    print(`Bot '{bot.user.username}' is online!`)
end)

bot:connectAsync():await()
```

## Multiple attachments

Call `:addAttachment()` multiple times to include more than one file in a single message. Each call adds one file.

```lua
message:replyAsync(
    builders.message.message.new()
        :addAttachment("First file contents", "first.txt")
        :addAttachment("Second file contents", "second.txt")
        :build()
):await()
```

## Combining attachments with text or embeds

Attachments, message content, and embeds can all be combined on the same message builder.

```lua
message:replyAsync(
    builders.message.message.new()
        :setContent("Here is your file:")
        :addAttachment("some,csv,data\n1,2,3", "data.csv")
        :build()
):await()
```

:::note[File content is a string]
The `content` argument to `:addAttachment()` is always a plain Luau string. For binary formats, you would need to encode the data as a string first.
:::

<details>
<summary>Full script</summary>

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")
local env      = require("@self/../.env")

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds", "GuildMessages", "MessageContent" }):build(),
    reconnect = true,
})

bot.onMessage:listen(function(message: classes.Message)
    if message.content ~= "!file" then
        return
    end

    message:replyAsync(
        builders.message.message.new()
            :addAttachment("Hello from discord-luau!", "hello.txt")
            :build()
    ):await()
end)

bot.onAllShardsReady:listenOnce(function()
    print(`Bot '{bot.user.username}' is online!`)
end)

bot:connectAsync():await()
```

</details>

## References

- [Bot](/classes/discordluau/bot) - the `discord.bot` class, gateway connection and event emitters
- [Message builder](/classes/builders/message) - `builders.message.message`, constructs message payloads including attachments
- [Message class](/classes/classes/message) - `classes.Message`, the object passed to `onMessage` handlers
- [Intents builder](/classes/builders/intents) - `builders.intents`, constructs the gateway intent bitfield
- [Futures](/vendor/futures) - the `FutureLike` async primitive returned by async calls
