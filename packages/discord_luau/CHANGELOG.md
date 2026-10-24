# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.6

### Fixed

- `Bot:connectAsync` resolves Err when the gateway information request fails, instead of never resolving after an emergency log
- `Bot:connectAsync` resolves Err when the gateway manager cannot connect, instead of dropping the failure and waiting for a connection that never opens

### Changed

- The bot records its own user ID on READY for voice, and SIGINT destroys each guild's voice connection

## 0.0.5

### Added

- `bot.new` accepts `isUsingStub`, a `discord_stub` world for running a bot against a local Discord

## 0.0.4

### Fixed

- `guild_id` is now propagated from the `GUILD_CREATE` payload to channel and thread cache entries so `Message.guildId` is correctly populated when reading from cache

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Changed

- Updated dependency versions

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
