---
title: Environment Setup
description: How to install the tools needed to build a discord-luau application.
sidebar:
  order: 0
---

This guide walks through installing the tools required to develop a discord-luau application. Complete this before moving on to the [Installation](/getting-started/installation) page.

## Required tools

### Rokit

[Rokit](https://github.com/rojo-rbx/rokit) is a toolchain manager used to install and manage Luau runtimes. Install it by following the instructions in the [Rokit repository](https://github.com/rojo-rbx/rokit).

Once installed, verify it is available:

```sh
rokit --version
```

### pesde

[pesde](https://pesde.dev) is the Luau package manager used to install discord-luau and to run the project scaffolder. Follow the installation instructions at [pesde.dev](https://pesde.dev).

Verify the installation:

```sh
pesde --version
```

### Lune

[Lune](https://lune-org.github.io/docs) is a Luau runtime required by pesde to execute CLI scripts such as `pesde x`. Install it via Rokit:

```sh
rokit add lune-org/lune@0.10.4
```

Verify it is available:

```sh
lune --version
```

### Zune

[Zune](https://github.com/Scythe-Technology/zune) is a Luau runtime used to run the `create_app` wizard and, by default, your bot itself. Install it via Rokit:

```sh
rokit add Scythe-Technology/zune@0.5.5
```

Verify it is available:

```sh
zune --version
```

:::note
If you intend to use Lune as your project runtime instead of Zune, Zune is still required by the `create_app` scaffolder itself.
:::

## IDE setup

discord-luau projects are configured to work with [Luau LSP](https://github.com/JohnnyMorganz/luau-lsp), which provides autocomplete, type checking, and inlay hints. The `create_app` scaffolder automatically generates IDE settings for your chosen editor.

### Visual Studio Code

Install the [Luau LSP extension](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp) from the VSCode Marketplace or the [OpenVSX Registry](https://open-vsx.org/extension/JohnnyMorganz/luau-lsp).

When you scaffold a project with VSCode selected, `create_app` generates the following `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "luau-lsp.inlayHints.variableTypes": true,
  "luau-lsp.inlayHints.functionReturnTypes": true,
  "luau-lsp.inlayHints.parameterNames": "all",
  "luau-lsp.inlayHints.parameterTypes": true,
  "luau-lsp.inlayHints.typeHintMaxLength": 50,
  "luau-lsp.fflags.override": {
    "LuauTarjanChildLimit": "0",
    "LuauTypeInferIterationLimit": "0"
  }
}
```

:::note
The `LuauTarjanChildLimit` and `LuauTypeInferIterationLimit` flags are set to `0` (unlimited) to prevent Luau LSP from giving up on discord-luau's complex types and reporting them as too complicated to analyse.
:::

### Zed

Install the [Luau LSP extension](https://zed.dev/extensions?query=luau) from the Zed extension marketplace.

When you scaffold a project with Zed selected, `create_app` generates a `.zed/settings.json` that configures Luau LSP with the same inlay hints and flag overrides as the VSCode config above.

### Neovim

Install [Luau LSP](https://github.com/JohnnyMorganz/luau-lsp) and configure it via your Neovim LSP setup. The `create_app` scaffolder does not generate Neovim-specific config files, so LSP configuration is left to your existing Neovim setup.

## Optional tools

### Selene

[Selene](https://kampfkarren.github.io/selene/) is a Luau linter. `create_app` generates a `selene.toml` for every project with the following config:

```toml
std = "luau"

[lints]
high_cyclomatic_complexity = "allow"
if_same_then_else = "allow"
shadowing = "allow"
```

To use it, install Selene via Rokit:

```sh
rokit add Kampfkarren/selene
```

### Git

[Git](https://git-scm.com) is recommended for version control. `create_app` can initialise a repository for you during scaffolding, and generates `.gitignore` and `.gitattributes` files.

The `.gitignore` excludes `.env.luau` (your bot token) and `luau_packages/` (installed dependencies).

Install Git by following the [official guide](https://git-scm.com/downloads).
