---
title: Installation
description: How to install discord-luau and scaffold your first bot project.
sidebar:
  order: 1
---

discord-luau is distributed via [pesde](https://pesde.dev), the Luau package manager. The quickest way to get started is with the `create_app` scaffolder, which sets up a complete project for you.

## Prerequisites

Before running the scaffolder, make sure the following tools are installed:

| Tool | Install |
|---|---|
| [pesde](https://pesde.dev) | Luau package manager - used to run `create_app` and install dependencies |
| [rokit](https://github.com/rojo-rbx/rokit) | Toolchain manager - used during project setup to install your chosen runtime |
| [lune](https://lune-org.github.io/docs) | Luau runtime - used by pesde to execute the `create_app` script |
| [zune](https://github.com/Scythe-Technology/zune) | Luau runtime - invoked by `create_app` to run the interactive wizard |

## Scaffold a new project

Run the following command to launch the interactive project wizard:

```sh
pesde x discord_luau/create_app create
```

To scaffold into a specific directory, pass it as an argument:

```sh
pesde x discord_luau/create_app create ./my-bot
```

The wizard will check that your prerequisites are installed, then walk you through the following steps:

| Prompt | Options | Default |
|---|---|---|
| **Project Name** | `scope/project_name` (lowercase, underscores) | - |
| **IDE** | `vscode`, `nvim`, `zed` | `vscode` |
| **Runtime** | `zune`, `lune` | `zune` |
| **Use Git** | `Yes`, `No` | `Yes` |
| **License** | Any SPDX identifier | `MIT` |
| **Discord Token** | Your bot token | - |

Once confirmed, the wizard will automatically run:

1. `rokit install` - installs your chosen runtime via rokit
2. `{runtime} setup` - sets up the runtime environment
3. `git init` - initialises a git repository (if selected)
4. `pesde install` - installs discord-luau and its dependencies

## Project structure

After scaffolding, your project will look like this:

```
my_project/
├── src/
│   └── init.luau       # Your bot's entry point
├── patches/            # Dependency patches applied by pesde
├── .env.luau           # Your bot token - do not commit this
├── .gitignore          # Excludes .env.luau and luau_packages/
├── .luaurc             # Luau type aliases
├── pesde.toml          # Package manifest
├── rokit.toml          # Toolchain manifest
└── selene.toml         # Linter config
```

:::caution[Keep your token secret]
`.env.luau` contains your bot token and is excluded from git by the generated `.gitignore`. Never commit it.
:::

## The generated entry point

`src/init.luau` contains a working bot that logs messages and prints when it comes online:

```lua
local discord = require("@self/../luau_packages/discord")
local classes = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")

local env = require("@self/../.env")

local DISCORD_BOT_INTENTS = builders.intents
    .new({
        "Guilds",
        "GuildMessages",
        "MessageContent",
    })
    :build()

local bot = discord.bot.new({
    token = env.DISCORD_BOT_TOKEN,
    intents = DISCORD_BOT_INTENTS,
    reconnect = true,
})

bot.onMessage:listen(function(message: classes.Message)
    print(`Message sent by '{message.author.globalName}' said: '{message.content}'`)
end)

bot.onAllShardsReady:listenOnce(function()
    print(`Bot '{bot.user.username}' is online!`)
end)

bot:connectAsync():await()
```

## Running your bot

Once setup is complete, run your bot with your chosen runtime. For example, with zune:

```sh
zune run src/init.luau
```

Or with lune:

```sh
lune run src/init.luau
```
