# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.4

### Added

- `NO_COLOR` environment variable support: ANSI color formatting is disabled when this variable is set
- `DISCORD_LUAU_LOG_LEVEL` environment variable support: sets a minimum log level floor that `setLogLevel` and `new()` cannot go below

### Changed

- `_sink` renamed to `sink` in the `Logger` type and all internal usages
- Error-level and above logs only kill the running coroutine when using the default `print` sink; custom sinks suppress this behavior

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Changed

- Updated dependency versions

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
