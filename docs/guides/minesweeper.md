---
title: Minesweeper
description: Build a playable Minesweeper game in Discord using spoiler tags.
sidebar:
  order: 5
---

This guide builds a `/minesweeper` command that generates a Minesweeper board directly in Discord. Every cell is hidden behind a spoiler tag (`||..||`) - clicking one reveals the emoji beneath. Bombs are `:bomb:`, safe cells show the count of adjacent bombs as a number emoji.

## How it works

The board is a plain text message. Each cell is formatted as `||:emoji:||`, which Discord renders as a clickable spoiler. Clicking a cell reveals it - just like uncovering a square in Minesweeper.

```
||:one:||||:bomb:||||:one:||
||:one:||||:two:||||:one:||
||:zero:||||:one:||||:zero:||
```

Because Discord handles each spoiler independently, there is no cascading reveal - every cell must be clicked individually. The board is entirely self-contained in a single message.

## Generating the board

```lua
local ROWS  <const> = 9
local COLUMNS  <const> = 9
local MINES <const> = 10

local NUMBER_EMOJIS <const> = table.freeze({
    [0] = ":zero:",
    [1] = ":one:",
    [2] = ":two:",
    [3] = ":three:",
    [4] = ":four:",
    [5] = ":five:",
    [6] = ":six:",
    [7] = ":seven:",
    [8] = ":eight:",
})

local function generateBoard(totalRows: number, totalColumns: number, totalMines: number): string
    -- Initialise the mine grid with all cells safe
    local mineGrid: { { boolean } } = {}
    for row = 1, totalRows do
        mineGrid[row] = {}
        for column = 1, totalColumns do
            mineGrid[row][column] = false
        end
    end

    -- Place mines at random positions using rejection sampling
    local placedMines = 0
    while placedMines < totalMines do
        local targetRow = math.random(1, totalRows)
        local targetColumn = math.random(1, totalColumns)
        if not mineGrid[targetRow][targetColumn] then
            mineGrid[targetRow][targetColumn] = true
            placedMines += 1
        end
    end

    -- Count how many of the 8 neighbouring cells contain a mine
    local function countAdjacentMines(row: number, column: number): number
        local adjacentMines = 0
        for rowOffset = -1, 1 do
            for columnOffset = -1, 1 do
                if rowOffset ~= 0 or columnOffset ~= 0 then
                    local neighborRow = row + rowOffset
                    local neighborColumn = column + columnOffset
                    local withinBounds = neighborRow >= 1 and neighborRow <= totalRows
                        and neighborColumn >= 1 and neighborColumn <= totalColumns
                    if withinBounds and mineGrid[neighborRow][neighborColumn] then
                        adjacentMines += 1
                    end
                end
            end
        end
        return adjacentMines
    end

    -- Render each cell as a spoiler-wrapped emoji
    local boardLines: { string } = {}
    for row = 1, totalRows do
        local rowCells: { string } = {}
        for column = 1, totalColumns do
            if mineGrid[row][column] then
                rowCells[column] = "||:bomb:||"
            else
                local adjacentCount = countAdjacentMines(row, column)
                rowCells[column] = `||{NUMBER_EMOJIS[adjacentCount]}||`
            end
        end
        boardLines[row] = table.concat(rowCells)
    end

    return table.concat(boardLines, "\n")
end
```

The function returns a single string - one row per line, cells joined without spaces so the grid looks compact in Discord.

## Registering the command and handling it

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")
local env      = require("@self/../.env")

local minesweeperCommand = builders.interaction.interaction.new()
    :setName("minesweeper")
    :setDescription("Generates a Minesweeper board. Click the spoilers to reveal cells!")
    :setType("ChatInput")
    :addIntegrationType("GuildInstall")
    :addContext("Guild")
    :build()

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds" }):build(),
    reconnect = true,
})

bot.onAllShardsReady:listenOnce(function()
    local result = bot.application:createSlashCommandAsync(minesweeperCommand):await()

    if result:isErr() then
        warn("Failed to register /minesweeper:", result:unwrapErr())
        return
    end

    print(`Bot '{bot.user.username}' is online!`)
end)

bot.onCommandInteraction:listen(function(interaction: classes.TypesCommand)
    if interaction.data.name ~= "minesweeper" then
        return
    end

    local boardContent = generateBoard(ROWS, COLUMNS, MINES)

    interaction:messageAsync(
        builders.message.message.new()
            :setContent(boardContent)
            :build()
    ):await()
end)

bot:connectAsync():await()
```

:::note[Register once, not on every startup]
Comment out or remove the `createSlashCommandAsync` call after the first run. Calling it on every startup wastes API calls and will eventually hit rate limits.
:::

## Board size and message length

Discord messages have a 2000-character limit. The worst-case cell length is `||:eight:||` (11 characters), so a 9×9 board uses at most `11 × 81 + 8 = 899` characters - well within the limit.

| Size | Mines | Max characters |
|---|---|---|
| 9×9 | 10 | ~899 |
| 10×10 | 15 | ~1,109 |
| 12×12 | 25 | ~1,595 |

Avoid going above roughly 13×13 or you risk hitting the limit.

<details>
<summary>Full script</summary>

```lua
local discord  = require("@self/../luau_packages/discord")
local classes  = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")
local env      = require("@self/../.env")

local ROWS  <const> = 9
local COLUMNS  <const> = 9
local MINES <const> = 10

local NUMBER_EMOJIS <const> = table.freeze({
    [0] = ":zero:",
    [1] = ":one:",
    [2] = ":two:",
    [3] = ":three:",
    [4] = ":four:",
    [5] = ":five:",
    [6] = ":six:",
    [7] = ":seven:",
    [8] = ":eight:",
})

local function generateBoard(totalRows: number, totalColumns: number, totalMines: number): string
    local mineGrid: { { boolean } } = {}
    for row = 1, totalRows do
        mineGrid[row] = {}
        for column = 1, totalColumns do
            mineGrid[row][column] = false
        end
    end

    local placedMines = 0
    while placedMines < totalMines do
        local targetRow = math.random(1, totalRows)
        local targetColumn = math.random(1, totalColumns)
        if not mineGrid[targetRow][targetColumn] then
            mineGrid[targetRow][targetColumn] = true
            placedMines += 1
        end
    end

    local function countAdjacentMines(row: number, column: number): number
        local adjacentMines = 0
        for rowOffset = -1, 1 do
            for columnOffset = -1, 1 do
                if rowOffset ~= 0 or columnOffset ~= 0 then
                    local neighborRow = row + rowOffset
                    local neighborColumn = column + columnOffset
                    local withinBounds = neighborRow >= 1 and neighborRow <= totalRows
                        and neighborColumn >= 1 and neighborColumn <= totalColumns
                    if withinBounds and mineGrid[neighborRow][neighborColumn] then
                        adjacentMines += 1
                    end
                end
            end
        end
        return adjacentMines
    end

    local boardLines: { string } = {}
    for row = 1, totalRows do
        local rowCells: { string } = {}
        for column = 1, totalColumns do
            if mineGrid[row][column] then
                rowCells[column] = "||:bomb:||"
            else
                local adjacentCount = countAdjacentMines(row, column)
                rowCells[column] = `||{NUMBER_EMOJIS[adjacentCount]}||`
            end
        end
        boardLines[row] = table.concat(rowCells)
    end

    return table.concat(boardLines, "\n")
end

local minesweeperCommand = builders.interaction.interaction.new()
    :setName("minesweeper")
    :setDescription("Generates a Minesweeper board. Click the spoilers to reveal cells!")
    :setType("ChatInput")
    :addIntegrationType("GuildInstall")
    :addContext("Guild")
    :build()

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = builders.intents.new({ "Guilds" }):build(),
    reconnect = true,
})

bot.onAllShardsReady:listenOnce(function()
    local result = bot.application:createSlashCommandAsync(minesweeperCommand):await()

    if result:isErr() then
        warn("Failed to register /minesweeper:", result:unwrapErr())
        return
    end

    print(`Bot '{bot.user.username}' is online!`)
end)

bot.onCommandInteraction:listen(function(interaction: classes.TypesCommand)
    if interaction.data.name ~= "minesweeper" then
        return
    end

    local boardContent = generateBoard(ROWS, COLUMNS, MINES)

    interaction:messageAsync(
        builders.message.message.new()
            :setContent(boardContent)
            :build()
    ):await()
end)

bot:connectAsync():await()
```

</details>

## References

- [Bot](/classes/discordluau/bot) - the `discord.bot` class, gateway connection and event emitters
- [Interaction builder](/classes/builders/interaction) - `builders.interaction.interaction`, constructs slash command definitions
- [Message builder](/classes/builders/message) - `builders.message.message`, constructs response payloads
- [Intents builder](/classes/builders/intents) - `builders.intents`, constructs the gateway intent bitfield
- [Futures](/vendor/futures) - the `FutureLike` async primitive returned by async calls
