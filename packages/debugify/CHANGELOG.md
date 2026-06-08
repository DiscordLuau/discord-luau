# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.3

### Added

- Added password/token/webhook detection in the `capture` command to avoid users printing sensitive information in their capture logs.

## 0.0.2

### Fixes

- `bin.luau` is now configured to use Zune as the `capture` command requires zune primitives that aren't available in other runtimes. 

## 0.0.1

### Added

- `info` command: displays runtime engine, version, OS, architecture, and capability flags with optional ANSI color output
- `capture` command: spawns a bot script via a specified runtime, pipes stdout and stderr live, and saves the last 200 lines to a timestamped `.log` file on exit
- `NO_COLOR=1` and `DISCORD_LUAU_LOG_LEVEL=Debug` are injected into the child process environment so captured output is plain text and fully verbose
- Esc key stops the captured process cleanly
- Log file includes a diagnostics header (runtime, OS, arch, capabilities) followed by session output
