# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- The scaffolded `src/init.luau` prints a failed `connectAsync` and exits non-zero instead of dropping the Result
- `create` logs at warn instead of error so the command returns, the git init failure keeps its cause, and an error in the wizard input loop is shown as a build error instead of leaving the screen running

## 0.0.6

### Fixed

- Scaffolded `rokit.toml` pins Lute to an exact version, so `rokit install` accepts it
- Scaffolded `.luaurc` points Lute at `~/.lute/typedefs/1.0.1/` and Lune at `~/.lune/.typedefs/0.11.0/`

### Changed

- Scaffolded `rokit.toml` now pins Lune 0.11.0, Zune 0.5.9 and Lute 1.0.1-nightly.20261021
- Scaffolded projects depend on discord_luau 0.0.5, which carries the gateway reconnect fix

## 0.0.5

### Fixed

- SillyKitr fix - https://github.com/DiscordLuau/discord-luau/pull/45

### Added

- Lute added as a valid runtime option in the project creation wizard
- Scaffolded `rokit.toml` now includes `luau-lang/lute@^1.0.0` for Lute projects
- Generated `.luaurc` now includes `@lute` and `@std` typedef path aliases for Lute LSP support

## 0.0.4

### Fixed

- sha256 patch template now includes the required git diff header and omits timestamps, fixing patch application failures via git2
- `process.env` clone in `bin.luau` is now explicitly cast to `{ [string]: string }` to resolve a strict type analysis error

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.3

### Added

- `kimpure+sha256` patch file template added to all scaffolded project types (vscode, nvim, zed)
- Generated `pesde.toml` now includes the `kimpure/sha256` patch entry alongside the existing `luau_futures` entry

## 0.0.2

### Added

- `--no-trust-check` is now passed to `rokit install`

### Fixed

- TUI hanging indefinitely when the target project directory already exists; `setupProject` now raises a catchable error instead of calling `Logger:error`
- On Windows, the TUI (`create`) now opens in a dedicated console window with proper input and terminal size; all other commands run inline in the current terminal
- On Windows, the project is now scaffolded in the directory where `pesde x` was invoked rather than the temporary `.cas` extraction folder
- Trailing path separators are stripped from the resolved base directory before constructing the project path, preventing double-separator paths on Windows
- `git init` failure now surfaces a clear error message; if git is not installed or not in PATH the error is caught and reported rather than crashing with an unhandled `FileNotFound`

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
