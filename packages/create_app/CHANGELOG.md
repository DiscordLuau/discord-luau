# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
