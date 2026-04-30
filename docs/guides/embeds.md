---
title: Sending Embeds
description: Build and send rich embed messages with discord-luau.
sidebar:
  order: 3
---

Embeds are rich message attachments that can contain a title, description, fields, images, and more. This guide shows how to build one and send it as a reply to a message.

## Prerequisites

This guide uses the `onMessage` event, which requires the `MessageContent` intent. Make sure it is enabled in the [Discord Developer Portal](https://discord.com/developers/applications) under your application's **Bot** tab.

## Building an embed

Embeds are constructed with `builders.embed.embed`. The `:setType()` call is required - use `"Rich"` for standard bot embeds.

```lua
local embed = builders.embed.embed.new()
    :setType("Rich")
    :setTitle("Hello from discord-luau!")
    :setDescription("This is an embed sent by a Luau bot.")
    :setColor(0x5865F2)
    :addField(
        builders.embed.field.new()
            :setName("Field One")
            :setValue("Some value here")
            :build()
    )
    :addField(
        builders.embed.field.new()
            :setName("Inline Field")
            :setValue("This field is inline")
            :setIsInline(true)
            :build()
    )
    :setFooter(
        builders.embed.footer.new()
            :setText("Sent via discord-luau")
            :build()
    )
    :build()
```

### Embed limits

| Element | Limit |
|---|---|
| Title | 256 characters |
| Description | 4096 characters |
| Fields | Up to 25 per embed |
| Footer text | 2048 characters |
| Embeds per message | Up to 10 |

## Sending the embed as a reply

Attach the built embed to a `builders.message.message` using `:addEmbed()`, then reply to the incoming message.

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
    if message.content ~= "!embed" then
        return
    end

    local embed = builders.embed.embed.new()
        :setType("Rich")
        :setTitle("Hello!")
        :setDescription("Here is your embed.")
        :setColor(0x5865F2)
        :setFooter(
            builders.embed.footer.new()
                :setText("discord-luau")
                :build()
        )
        :build()

    message:replyAsync(
        builders.message.message.new()
            :addEmbed(embed)
            :build()
    ):await()
end)

bot.onAllShardsReady:listenOnce(function()
    print(`Bot '{bot.user.username}' is online!`)
end)

bot:connectAsync():await()
```

## Colors

Colors are plain integers. You can write hex literals directly in Luau:

```lua
:setColor(0xFF0000)  -- red
:setColor(0x00FF00)  -- green
:setColor(0x0000FF)  -- blue
:setColor(0x5865F2)  -- Discord blurple
```

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
    if message.content ~= "!embed" then
        return
    end

    local embed = builders.embed.embed.new()
        :setType("Rich")
        :setTitle("Hello!")
        :setDescription("Here is your embed.")
        :setColor(0x5865F2)
        :addField(
            builders.embed.field.new()
                :setName("Field One")
                :setValue("Some value here")
                :build()
        )
        :setFooter(
            builders.embed.footer.new()
                :setText("discord-luau")
                :build()
        )
        :build()

    message:replyAsync(
        builders.message.message.new()
            :addEmbed(embed)
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
- [Embed builder](/classes/builders/embed) - `builders.embed.embed`, constructs embed payloads
- [Embed Field builder](/classes/builders/embed/field) - `builders.embed.field`, adds fields to an embed
- [Embed Footer builder](/classes/builders/embed/footer) - `builders.embed.footer`, sets the embed footer
- [Message builder](/classes/builders/message) - `builders.message.message`, wraps embeds for sending
- [Message class](/classes/classes/message) - `classes.Message`, the object passed to `onMessage` handlers
- [Futures](/vendor/futures) - the `FutureLike` async primitive returned by async calls
