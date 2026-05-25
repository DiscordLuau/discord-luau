---
title: Cooldowns & Concurrency
description: Rate-limit command usage with cooldown rules and cap parallel executions with concurrency limits.
sidebar:
  order: 5
---

Cooldowns prevent a command from being run too frequently. Concurrency limits cap how many executions of a command can be running at the same time.

## Static cooldowns

Add a `cooldown` array to the command definition. Each rule has a duration in seconds and a `per` scope.

```lua
local classes = require("../../luau_packages/classes")

return {
    command = ...,

    cooldown = {
        { seconds = 5, per = "user" },
    },

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Done!" }):await()
    end,
}
```

When a user hits the cooldown, a default message is sent showing the remaining time. Override it with `onCooldown`:

```lua
return {
    command = ...,

    cooldown = { { seconds = 10, per = "user" } },

    onCooldown = function(interaction: classes.TypesCommand, remaining: number)
        interaction:messageAsync({
            content = `Wait {remaining}s before using this again.`,
            flags = 64,
        }):await()
    end,

    execute = function(interaction: classes.TypesCommand) ... end,
}
```

## Cooldown scopes

The `per` field controls what the cooldown is keyed on.

| Scope | Resets per |
|---|---|
| `"user"` | Each individual user, across all guilds |
| `"guild"` | Each guild |
| `"channel"` | Each channel |
| `"member"` | Each user per guild (guild + user combined) |
| `"global"` | Everyone shares one cooldown |

## Multiple rules

You can stack rules to enforce several limits at once. All rules are checked — the longest remaining cooldown wins.

```lua
cooldown = {
    { seconds = 3,  per = "user" },   -- 3s per user
    { seconds = 10, per = "channel" }, -- 10s per channel
},
```

## Dynamic cooldowns

If the cooldown duration or scope depends on the interaction (e.g. different durations for premium users), pass a function instead of an array. It receives the interaction and returns a rule array, or `nil` to skip the cooldown entirely.

```lua
cooldown = function(interaction: classes.TypesCommand)
    if isPremiumUser(interaction.user.id) then
        return { { seconds = 1, per = "user" } }
    end

    return { { seconds = 10, per = "user" } }
end,
```

## Concurrency limits

`maxConcurrency` caps how many instances of a command can run simultaneously. This is useful for commands that do slow async work and shouldn't be stacked.

```lua
return {
    command = ...,

    maxConcurrency = { limit = 1, per = "user" },

    execute = function(interaction: classes.TypesCommand)
        interaction:deferAsync():await()
        -- ... slow work ...
        interaction:editResponseAsync({ content = "Done!" }):await()
    end,
}
```

The `per` field accepts the same scopes as cooldowns. When the limit is hit, a default message is sent. Override it with `onConcurrencyLimited`:

```lua
onConcurrencyLimited = function(interaction: classes.TypesCommand)
    interaction:messageAsync({
        content = "This command is already running for you.",
        flags = 64,
    }):poll()
end,
```

## Global concurrency fallback

Set a global `onConcurrencyLimited` handler in `Commands.new` to apply to all commands that don't define their own:

```lua
local commandsManager = commands.new(bot, {
    onConcurrencyLimited = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Please wait.", flags = 64 }):poll()
    end,
})
```

## References

- [Guards & Permissions](/guides/commands-framework/guards-and-permissions) — blocking access before execution
- [Middleware & After Hooks](/guides/commands-framework/middleware-and-hooks) — wrapping the full dispatch pipeline
