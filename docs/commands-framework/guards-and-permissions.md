---
title: Guards & Permissions
description: Restrict who can run a command using built-in guards, custom guards, and Discord permission checks.
sidebar:
  order: 4
---

Guards are functions that run before `execute`. If any guard returns `false`, the command is blocked and the user gets a denial message. The framework ships with built-in guards for common cases, and you can write your own.

## Built-in guards

Access built-in guards via `commands.Guards`.

```lua
local commands = require("@self/../luau_packages/commands")
local classes = require("@self/../luau_packages/classes")

return {
    command = ...,

    guards = {
        commands.Guards.guildOnly,
    },

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "You're in a guild!" }):await()
    end,
}
```

| Guard | Passes when |
|---|---|
| `commands.Guards.guildOnly` | Interaction is inside a guild |
| `commands.Guards.dmOnly` | Interaction is in a DM |
| `commands.Guards.ownerOnly(ids)` | Invoking user's ID is in the provided list |

`ownerOnly` is a factory — call it with a list of owner IDs:

```lua
guards = {
    commands.Guards.ownerOnly({ "123456789", "987654321" }),
},
```

## Custom guards

A guard is any function that takes the interaction and returns a boolean.

```lua
local function premiumOnly(interaction: classes.TypesCommand): boolean
    -- check your database, cache, etc.
    return isPremiumUser(interaction.user.id)
end

return {
    command = ...,

    guards = { premiumOnly },

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Premium feature!" }):await()
    end,
}
```

## AND logic

By default, guards in the list are AND — every guard must pass.

```lua
guards = {
    commands.Guards.guildOnly,  -- must be in a guild
    premiumOnly,                 -- AND must be premium
},
```

## OR logic

Wrap guards in a nested table to express OR — at least one must pass.

```lua
guards = {
    { commands.Guards.ownerOnly({ "123" }), isAdminRole },
},
```

You can mix AND and OR in the same list:

```lua
guards = {
    commands.Guards.guildOnly,              -- must be in a guild
    { isAdmin, isModerator },               -- AND (is admin OR is moderator)
},
```

## Discord permission checks

Use `userPermissions` to require the invoking member to hold specific Discord permissions. Use `clientPermissions` to require the bot itself to have them. These only apply inside guilds.

```lua
return {
    command = ...,

    userPermissions = { "ManageMessages" },
    clientPermissions = { "ManageMessages" },

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Message deleted." }):await()
    end,
}
```

If permissions are missing, a default denial message is sent. Override it with `onUserPermissionDenied` or `onClientPermissionDenied`:

```lua
return {
    command = ...,

    userPermissions = { "Administrator" },

    onUserPermissionDenied = function(interaction: classes.TypesCommand, missing: { string })
        interaction:messageAsync({
            content = `You're missing: {table.concat(missing, ", ")}`,
            flags = 64,
        }):await()
    end,

    execute = function(interaction: classes.TypesCommand) ... end,
}
```

## Custom denial messages

Override the default "You don't have permission" message globally via `onGuardFailed` in `Commands.new`, or per-command via `onGuardFailed` on the definition.

```lua
-- global
local commandsManager = commands.new(bot, {
    onGuardFailed = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Nope.", flags = 64 }):poll()
    end,
})

-- per-command
return {
    command = ...,
    guards = { ... },
    onGuardFailed = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Not for you.", flags = 64 }):poll()
    end,
    execute = function(interaction: classes.TypesCommand) ... end,
}
```

## References

- [Getting Started](/guides/commands-framework/getting-started) — basic setup
- [Cooldowns & Concurrency](/guides/commands-framework/cooldowns-and-concurrency) — rate-limiting command usage
- [Subcommands](/guides/commands-framework/subcommands) — per-subcommand guards
