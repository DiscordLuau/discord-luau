---
title: Futures (FutureLike)
description: Understanding the FutureLike async primitive used throughout discord-luau.
sidebar:
  order: 1
---

discord-luau uses **[luau-futures](https://yetanotherclown.github.io/luau-futures/)** as its async primitive. Any method that performs a network or I/O operation returns a `FutureLike` instead of blocking.

## What is a FutureLike?

A `FutureLike<E, T>` represents a value that will be available in the future - similar to a Promise in JavaScript or a Future in other languages. It carries two type parameters:

- **`E`** - the error type (usually `string` for a Discord API error message)
- **`T`** - the success value type (e.g. `Message`, `Member`, `nil`)

## Important: Futures are lazy

:::caution[Futures do not execute on their own]
A `FutureLike` returned from any discord-luau method will not send its underlying request until you call `:poll()` or `:await()` on it.
:::

:::danger[Discarding a future silently drops the call]
If you ignore the return value, the API call is never made - there is no error, it simply does nothing.

```lua
-- The message is never actually sent
channel:sendMessageAsync(builder)

-- The message is sent
channel:sendMessageAsync(builder):await()
```
:::

## Awaiting a Future

Call `:await()` to yield the current thread until the future resolves. It returns a `Result<E, T>` - use `:isOk()`, `:unwrapOk()`, and `:unwrapErr()` to handle the outcome:

```lua
local result = someChannel:sendMessageAsync(builder):await()

if result:isErr() then
    warn("Failed to send message:", result:unwrapErr())
    return
end

local message = result:unwrapOk()
print("Sent message with ID:", message.id)
```

## Polling

Call `:poll()` to check readiness without yielding the current thread. It returns a `Poll<E, T>` - either pending or ready:

```lua
local poll = someChannel:sendMessageAsync(builder):poll()

if poll:isReady() then
    local result = poll:unwrap()
    -- handle result
end
```

## Chaining with andThen

`:andThen()` chains a second operation that only runs on success. The callback receives the Ok value(s) and **must return a new `FutureLike`**. You still need to poll or await the final chain for anything to execute:

```lua
message:startThreadAsync("My Thread", 60)
    :andThen(function(thread)
        return thread:sendMessageAsync(builder)
    end)
    :await()
```

## Full Documentation

For the complete API reference - including `after`, `mapOk`, `mapErr`, `orElse`, `join`, and more - see the official library docs:

**[yetanotherclown.github.io/luau-futures](https://yetanotherclown.github.io/luau-futures/)**
