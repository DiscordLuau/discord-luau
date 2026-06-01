---
title: Hot Reload & Plugins
description: Reload commands on save without restarting, and extend the framework with plugins.
sidebar:
  order: 8
---

The commands framework can watch your command files for changes and reload them automatically. Plugins let you package reusable middleware, hooks, and commands into a single installable unit.

## File watching

When `watch` is enabled (the default), calling `commands:load()` also starts watching the loaded directory. Saving a command file triggers an automatic reload - no restart required.

```lua
local commandsManager = commands.new(bot) -- watch: true by default

bot.onAllShardsReady:listenOnce(function()
    commandsManager:load("src/commands") -- loads and watches
end)
```

Disable watching if you don't need it (e.g. in production):

```lua
local commandsManager = commands.new(bot, { watch = false })
```

## Manual watching

Call `commands:watch()` separately to watch a directory without loading from it, or to watch additional directories after the initial load.

```lua
local stopWatching = commandsManager:watch("src/extra-commands")

stopWatching()
```

## Stopping all watchers

`commands:destroy()` stops every active watcher registered through `commands:watch()` or auto-started by `commands:load()`.

```lua
commandsManager:destroy()
```

## How hot reload works

When a file changes, the loader writes the new file content to a temporary file with a randomised name, `require()`s that file to bypass the module cache, then deletes the temporary file. The new `CommandDefinition` replaces the old one in the registry. In-flight interactions using the previous definition complete normally.

:::note[Temporary files are filtered from watch events]
The loader ignores `.luau` files whose names match the temporary-file pattern, so hot-reloading a command never triggers a second reload of itself.
:::

## Plugins

A plugin is a table with a `name` and a `setup` function. `setup` receives the `Commands` instance so it can register middleware, after hooks, commands, or anything else. It can optionally return a teardown function.

```lua
local commands = require("../../luau_packages/commands")

local loggingPlugin = {
    name = "logging",

    setup = function(commandsManager: commands.Commands)
        commandsManager:use(function(interaction: any, next: () -> ())
            local anyInteraction = interaction :: any
            local name = anyInteraction.data and anyInteraction.data.name or "interaction"

            print(`[log] {name}`)
            next()
        end)

        -- return a teardown function (optional)
        return function()
            print("[log] plugin unloaded")
        end
    end,
}
```

Install a plugin with `commands:usePlugin()`:

```lua
commandsManager:usePlugin(loggingPlugin)
```

Installing the same plugin twice is a no-op - the framework warns and skips.

## Unloading a plugin

```lua
commandsManager:unloadPlugin("logging")
```

This calls the teardown function returned by `setup`, if one was provided.

## Context

The `context` option lets you pass a shared value (config, database handle, etc.) into every command factory function and into plugins.

Command files can receive it by exporting a factory function instead of a plain table:

```lua
-- src/commands/example.luau
local classes = require("../../luau_packages/classes")

return function(context)
    return {
        command = ...,

        execute = function(interaction: classes.TypesCommand)
            -- context.db, context.config, etc.
        end,
    }
end
```

Pass the context when creating the Commands instance:

```lua
local commandsManager = commands.new(bot, {
    context = {
        db = myDatabase,
        config = myConfig,
    },
})
```

## References

- [Getting Started](/guides/commands-framework/getting-started) - `commands.new` options including `watch` and `context`
- [Middleware & After Hooks](/guides/commands-framework/middleware-and-hooks) - what plugins commonly register
