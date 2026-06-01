---
title: Options & Transforms
description: Define typed command options and pre-process their values before execute runs.
sidebar:
  order: 2
---

Options are the parameters users pass to a slash command. Transforms let you pre-process raw option values into whatever shape your execute handler needs, before it runs.

## Defining options

Add options to the interaction builder before calling `:build()`.

```lua
local builders = require("@self/../../luau_packages/builders")
local classes = require("@self/../../luau_packages/classes")

return {
    command = builders.interaction.interaction.new()
        :setName("greet")
        :setDescription("Greet a user")
        :addIntegrationType("GuildInstall")
        :addContext("Guild")
        :addOption(
            builders.interaction.option.new()
                :setType("User")
                :setName("target")
                :setDescription("The user to greet")
                :setRequired(true)
                :build()
        )
        :build(),

    execute = function(interaction: classes.TypesCommand)
        local option = interaction:getOption("target")
        local userId = option and option.value or "unknown"

        interaction:messageAsync({ content = `Hello <@{userId}>!` }):await()
    end,
}
```

Common option types:

| Type | Value kind |
|---|---|
| `"String"` | Plain text |
| `"Integer"` | Whole number |
| `"Number"` | Decimal number |
| `"Boolean"` | `true` / `false` |
| `"User"` | User ID string |
| `"Channel"` | Channel ID string |
| `"Role"` | Role ID string |
| `"Mentionable"` | User or role ID string |

## Reading option values

Use `interaction:getOption(name)` to retrieve an option. It returns the raw option object (with a `.value` field), or `nil` if the option was not provided.

```lua
execute = function(interaction: classes.TypesCommand)
    local option = interaction:getOption("amount")
    local amount = option and option.value or 1

    interaction:messageAsync({ content = `Rolling {amount} dice...` }):await()
end,
```

## Transforms

Transforms run before `execute` and convert raw option values into processed results. This keeps your execute handler clean - it just reads the final value rather than doing parsing inline.

Define a `transforms` table on the command, keyed by option name:

```lua
local classes = require("@self/../../luau_packages/classes")

return {
    command = builders.interaction.interaction.new()
        :setName("info")
        :setDescription("Look up a user")
        :addIntegrationType("GuildInstall")
        :addContext("Guild")
        :addOption(
            builders.interaction.option.new()
                :setType("User")
                :setName("target")
                :setDescription("The user to look up")
                :setRequired(true)
                :build()
        )
        :build(),

    transforms = {
        target = function(value: any, interaction: classes.TypesCommand)
            local resolved = interaction.data.resolved

            if not resolved then
                return nil
            end

            return (resolved.users :: any)[value]
        end,
    },

    execute = function(interaction: classes.TypesCommand)
        local user: classes.User? = interaction:getTransformed("target")

        if not user then
            interaction:messageAsync({ content = "Could not resolve user.", flags = 64 }):await()
            return
        end

        interaction:messageAsync({ content = `Tag: {user.username}#{user.discriminator}` }):await()
    end,
}
```

`interaction:getTransformed(name)` returns the value your transform function returned. If a transform throws, the framework sends a generic error reply and skips `execute`.

## Transform function signature

```lua
type TransformFunction = (value: any, interaction: classes.TypesCommand) -> any
```

The first argument is the raw option value (equivalent to `interaction:getOption(name).value`). The second is the full interaction, giving you access to `data.resolved`, guild info, etc.

## References

- [Subcommands](/guides/commands-framework/subcommands) - per-subcommand transforms
- [Getting Started](/guides/commands-framework/getting-started) - basic command setup
