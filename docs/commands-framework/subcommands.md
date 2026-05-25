---
title: Subcommands & Groups
description: Route slash command interactions to per-subcommand handlers using SubCommand and SubCommandGroup.
sidebar:
  order: 3
---

Discord supports grouping related actions under a single top-level command using subcommands and subcommand groups. The framework resolves which handler to call automatically based on the interaction data.

## Subcommands

Add `SubCommand` options to the interaction builder, then provide a matching `subcommands` table on the definition. Each key is a subcommand name and each value is a `SubcommandDefinition`.

```lua
local builders = require("../../luau_packages/builders")
local classes = require("../../luau_packages/classes")

return {
    command = builders.interaction.interaction.new()
        :setName("reminder")
        :setDescription("Manage reminders")
        :addIntegrationType("GuildInstall")
        :addContext("Guild")
        :addOption(
            builders.interaction.option.new()
                :setType("SubCommand")
                :setName("set")
                :setDescription("Set a new reminder")
                :build()
        )
        :addOption(
            builders.interaction.option.new()
                :setType("SubCommand")
                :setName("clear")
                :setDescription("Clear all reminders")
                :build()
        )
        :build(),

    execute = function(interaction: classes.TypesCommand)
        -- fallback if no subcommand matched
        interaction:messageAsync({ content = "Unknown subcommand.", flags = 64 }):await()
    end,

    subcommands = {
        set = {
            execute = function(interaction: classes.TypesCommand)
                interaction:messageAsync({ content = "Reminder set!" }):await()
            end,
        },
        clear = {
            execute = function(interaction: classes.TypesCommand)
                interaction:messageAsync({ content = "Reminders cleared." }):await()
            end,
        },
    },
}
```

:::note[Top-level execute is the fallback]
The top-level `execute` only runs when no subcommand handler matches. In practice this shouldn't happen if your builder and `subcommands` table are in sync, but it is required by the type.
:::

## Subcommand groups

For a second level of nesting, use `SubCommandGroup` options. The `subcommands` table then has a group name at the top level, and subcommand names nested inside.

```lua
return {
    command = builders.interaction.interaction.new()
        :setName("config")
        :setDescription("Bot configuration")
        :addIntegrationType("GuildInstall")
        :addContext("Guild")
        :addOption(
            builders.interaction.option.new()
                :setType("SubCommandGroup")
                :setName("logging")
                :setDescription("Logging settings")
                :addOption(
                    builders.interaction.option.new()
                        :setType("SubCommand")
                        :setName("enable")
                        :setDescription("Enable logging")
                        :build()
                )
                :addOption(
                    builders.interaction.option.new()
                        :setType("SubCommand")
                        :setName("disable")
                        :setDescription("Disable logging")
                        :build()
                )
                :build()
        )
        :build(),

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Unknown subcommand.", flags = 64 }):await()
    end,

    subcommands = {
        logging = {
            enable = {
                execute = function(interaction: classes.TypesCommand)
                    interaction:messageAsync({ content = "Logging enabled." }):await()
                end,
            },
            disable = {
                execute = function(interaction: classes.TypesCommand)
                    interaction:messageAsync({ content = "Logging disabled." }):await()
                end,
            },
        },
    },
}
```

## Per-subcommand guards and transforms

`SubcommandDefinition` supports its own `guards` and `transforms` tables, which run in addition to any top-level ones on the parent command.

```lua
subcommands = {
    set = {
        guards = {
            function(interaction: classes.TypesCommand): boolean
                return interaction.guildId ~= nil
            end,
        },

        transforms = {
            duration = function(value: any, interaction: classes.TypesCommand)
                return tonumber(value) or 60
            end,
        },

        execute = function(interaction: classes.TypesCommand)
            local duration = interaction:getTransformed("duration")

            interaction:messageAsync({ content = `Reminder in {duration}s` }):await()
        end,
    },
},
```

## References

- [Options & Transforms](/guides/commands-framework/options-and-transforms) - defining options and transforms
- [Guards & Permissions](/guides/commands-framework/guards-and-permissions) - restricting access per-subcommand
