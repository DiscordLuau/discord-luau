---
title: Middleware & After Hooks
description: Wrap the dispatch pipeline with middleware and run logic after every command execution.
sidebar:
  order: 7
---

Middleware wraps the entire dispatch pipeline, letting you run logic before (or around) every interaction. After hooks run once per command execution, regardless of success or error.

## Middleware

Register middleware with `commands:use()`. Each middleware receives the interaction and a `next` function. Call `next()` to continue the pipeline; omit it to short-circuit.

```lua
commandsManager:use(function(interaction: any, next: () -> ())
    print(`Interaction received: {(interaction :: any).data.name or "component"}`)
    next()
end)
```

Middleware runs in registration order, before guards, cooldowns, and `execute`.

## Short-circuiting

Omitting `next()` stops the pipeline entirely — guards, cooldowns, and `execute` all skip.

```lua
commandsManager:use(function(interaction: any, next: () -> ())
    local anyInteraction = interaction :: any

    if isBanned(anyInteraction.user.id) then
        anyInteraction:messageAsync({ content = "You are banned.", flags = 64 }):poll()
        return -- don't call next()
    end

    next()
end)
```

## Async middleware

Middleware runs in a coroutine, so you can yield inside it. Call `next()` after your async work completes.

```lua
commandsManager:use(function(interaction: any, next: () -> ())
    local anyInteraction = interaction :: any

    -- fetch something before the command runs
    local data = fetchUserData(anyInteraction.user.id):await()
    (anyInteraction :: any).userData = data

    next()
end)
```

## Middleware applies to all interaction types

The same middleware list runs for slash commands, component interactions, modal submissions, and autocomplete. Gate on the interaction type if needed:

```lua
commandsManager:use(function(interaction: any, next: () -> ())
    local anyInteraction = interaction :: any

    if anyInteraction.data and anyInteraction.data.name then
        -- only for slash commands
        logCommand(anyInteraction.data.name)
    end

    next()
end)
```

## After hooks

Register a global after hook with `commands:after()`. It fires after `execute` completes (or errors), making it suitable for logging, metrics, or cleanup.

```lua
local classes = require("../../luau_packages/classes")

commandsManager:after(function(interaction: classes.TypesCommand)
    local anyInteraction = interaction :: any
    local name = anyInteraction.data and anyInteraction.data.name or "unknown"

    print(`Command '{name}' finished`)
end)
```

Multiple after hooks run in registration order. Errors in individual hooks are logged as warnings and do not affect other hooks.

## Per-command after hooks

Set `afterExecute` on a command definition to run logic specific to that command, before the global after hooks.

```lua
local classes = require("../../luau_packages/classes")

return {
    command = ...,

    afterExecute = function(interaction: classes.TypesCommand)
        recordUsage(interaction.user.id)
    end,

    execute = function(interaction: classes.TypesCommand)
        interaction:messageAsync({ content = "Done!" }):await()
    end,
}
```

## Execution order

For a slash command, the full pipeline runs in this order:

1. Middleware chain (in registration order, calling `next()`)
2. Permission checks (`userPermissions`, `clientPermissions`)
3. Guards
4. Cooldown check
5. Concurrency acquire
6. Transforms
7. `execute` (or subcommand execute)
8. Concurrency release
9. `afterExecute` (per-command)
10. After hooks (global, in registration order)

## References

- [Guards & Permissions](/guides/commands-framework/guards-and-permissions) — step 3 in the pipeline
- [Cooldowns & Concurrency](/guides/commands-framework/cooldowns-and-concurrency) — steps 4–5 in the pipeline
- [Hot Reload & Plugins](/guides/commands-framework/hot-reload-and-plugins) — plugins can register middleware
