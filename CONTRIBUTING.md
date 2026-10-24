# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.

Please note we have a [code of conduct](CODE_OF_CONDUCT.md), please follow it in all your interactions with the project.

## Development environment setup
1. Git clone the projects repository *(`git clone https://github.com/DiscordLuau/discord-luau.git`)*
2. Install [pesde](https://pesde.dev) and [Rokit](https://github.com/rojo-rbx/rokit), then the pinned tools *(`rokit install`; Rokit asks once before installing a tool it has not seen)*
3. Write the Zune type definitions *(`zune setup`)*
4. Bundle the API types *(`zune run .zune/bundle.luau`)*
5. Install all dependencies *(`pesde install`)*
6. Seed the binary cache from the checkout *(`zune run .github/scripts/seedBinaryCache.luau`)*; `opus` always loads its own checksummed libopus, and until a version's release tag exists its download fails
7. Run the checks CI runs *(`zune run .zune/fmt.luau`, `zune run .zune/lint.luau`, `zune run .zune/analyze.luau`, `zune run .zune/test.luau`)*

## AI-assisted contributions

You are welcome to use AI tools. You are responsible for every line you submit, you test it, and you say in the pull request description that AI was used. The full rules are in [docs/ai](docs/ai/overview.md); AI tools read the same rules from `AGENTS.md`.

## Code Style Guide
- **Classes:** Use PascalCase for classes.
	- A class represents a structure that self regulates some sort of internal state. For instance - a DiscordGuilds state would be information surrounding the guild in question.
- **Variables:** Use camelCase for variables.
- **Constants:** Use LOUD_SNAKE_CASE for constants.
- **Types:** Use PascalCase for types.
- **Files:** Name files using camelCase.
- **Naming:** Follow semi-terse naming; identifiers should be unique and readable without being overly repetitive.
	- instead of naming files `PostgresClient.luau` and `PostgresServer.luau`, group them under a module directory called `postgres` with an `init.luau` that exports both `client.luau` and `server.luau`.
- **Modules:** Prefer grouping modules as a tree. For instance, rather than having separate files like `RobloxInputMouseHandler.luau` and `RobloxInputKeyboardHandler.luau`, structure them as `inputHandlers/roblox/mouse.luau` and `inputHandlers/roblox/keyboard.luau`.
	- another example; use `builders/X.luau` instead of `builders/XBuilder.luau`.
- **Formatting:** Run stylua with the repository's `stylua.toml` (tabs, 120-character lines).
- **Variable Naming:** One-word variable names are discouraged, even in closures.
- **Comments:** This project uses Moonwave documentation - ensure your format meets the requirements for Moonwave.

## Issues and feature requests

You've found a bug in the source code, a mistake in the documentation or maybe you'd like a new feature? You can help us by [submitting an issue on GitHub](https://github.com/DiscordLuau/discord-luau/issues).

**Even better: Submit a pull request with a fix or new feature!**

### How to submit a Pull Request

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write your code changes
4. Commit your changes (`git commit -m 'feature: add amazing_feature'`)
5. Push to the branch (`git push origin feat/amazing_feature`)
6. [Open a Pull Request](https://github.com/DiscordLuau/discord-luau/compare?expand=1)
