---
title: Components, Modals & Autocomplete
description: Handle button clicks, modal submissions, and autocomplete suggestions from within a command definition.
sidebar:
  order: 6
---

Component interactions (buttons, select menus), modal submissions, and autocomplete suggestions can all be handled directly from a `CommandDefinition`, keeping related logic together in one file.

## Static component handlers

Add a `components` table to the definition. Keys are custom ID patterns; values are handler functions.

```lua
local classes = require("../../luau_packages/classes")

return {
    command = builders.interaction.interaction.new()
        :setName("poll")
        :setDescription("Start a poll")
        :addIntegrationType("GuildInstall")
        :addContext("Guild")
        :build(),

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({
            components = {
                -- action row with Yes / No buttons
            },
        }):await()
    end,

    components = {
        ["poll:vote:yes"] = function(interaction: classes.Component)
            interaction:acknowledgeAsync():await()
            interaction:editResponseAsync({ content = "You voted Yes!" }):await()
        end,

        ["poll:vote:no"] = function(interaction: classes.Component)
            interaction:acknowledgeAsync():await()
            interaction:editResponseAsync({ content = "You voted No!" }):await()
        end,
    },
}
```

## Custom ID pattern matching

Patterns support two wildcards:

| Pattern | Matches |
|---|---|
| `poll:vote:yes` | Exactly `poll:vote:yes` |
| `poll:vote:*` | `poll:vote:` followed by exactly one segment |
| `poll:vote:**` | `poll:vote:` followed by one or more segments |

Segments are separated by `:`. Use `*` when you embed a single dynamic value (e.g. a page number), and `**` when you embed multiple.

```lua
components = {
    -- matches poll:vote:yes:USER_ID, poll:vote:no:USER_ID, etc.
    ["poll:vote:**"] = function(interaction: classes.Component)
        local customId = (interaction :: any).data.customId
        -- parse segments from customId
    end,
},
```

## Modal handlers

The `modals` table works identically to `components`.

```lua
return {
    command = ...,

    execute = function(interaction: classes.TypesCommand)
        interaction:showModalAsync({
            customId = "feedback:submit",
            title = "Feedback",
            components = { ... },
        }):await()
    end,

    modals = {
        ["feedback:submit"] = function(interaction: classes.Modal)
            local value = (interaction :: any).data.components[1].components[1].value

            interaction:messageAsync({ content = `Thanks! Got: {value}` }):await()
        end,
    },
}
```

## Autocomplete handlers

Add an `autocomplete` function to the definition. It fires when Discord requests suggestions for a focused option.

```lua
return {
    command = builders.interaction.interaction.new()
        :setName("color")
        :setDescription("Pick a color")
        :addIntegrationType("GuildInstall")
        :addContext("Guild")
        :addOption(
            builders.interaction.option.new()
                :setType("String")
                :setName("name")
                :setDescription("Color name")
                :setAutocomplete(true)
                :build()
        )
        :build(),

    autocomplete = function(interaction: classes.Autocomplete)
        local colors = { "Red", "Green", "Blue", "Yellow", "Purple" }
        local focused = (interaction :: any).data.options[1].value or ""
        local choices = {}

        for _, color in colors do
            if string.find(string.lower(color), string.lower(focused), 1, true) then
                table.insert(choices, { name = color, value = color })
            end
        end

        interaction:respondAsync(choices):await()
    end,

    execute = function(interaction: classes.TypesCommand)
        local option = interaction:getOption("name")

        interaction:messageAsync({ content = `You picked {option and option.value}!` }):await()
    end,
}
```

## Interaction collectors

For multi-step flows, use `commands:waitForComponent()` or `commands:waitForModal()` to pause execution and wait for a specific interaction, rather than wiring up a static handler.

```lua
-- inside an execute handler
local future = self:waitForComponent({
    filter = function(componentInteraction: classes.Component): boolean
        return (componentInteraction :: any).data.customId == "confirm:yes"
            and (componentInteraction :: any).user.id == interaction.user.id
    end,
    timeout = 30,
})

local result = future:await()

-- result is the component interaction, or the future errors with "timeout"
```

:::note[Collectors vs static handlers]
Static handlers in `components`/`modals` are always active for any user. Collectors intercept the *next* matching interaction for the current execution only, making them suited to confirmation flows and wizards.
:::

Both methods accept the same options:

| Option | Type | Default | Description |
|---|---|---|---|
| `filter` | `function?` | always true | Return `true` to accept the interaction |
| `timeout` | `number?` | `30` | Seconds to wait before the Future errors |

## References

- [Getting Started](/guides/commands-framework/getting-started) - setting up the commands instance
- [Middleware & After Hooks](/guides/commands-framework/middleware-and-hooks) - pipeline that wraps component dispatch too
