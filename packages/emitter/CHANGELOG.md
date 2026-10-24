# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- An event invoked from a thread that a listener itself resumed is no longer dropped silently; it is handled in a new thread like any event that arrives while the listener is busy
- A listener that yields (for example one that awaits a future) no longer has the next event's arguments resumed into it; an event that arrives while the listener is still running is handled in a new thread with its own arguments. This broke slash commands that awaited, voice connection handshakes and any bot code that waited inside a listener
- Errors from resuming listener and waiting threads are always logged with the invoke site

### Changed

- Helper methods drop their leading underscore (`_name` is now `name`); they stay marked `@private` and out of the docs
- Listeners run in the order they were connected
- A listener disconnected during an `invoke` no longer receives that event

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Changed

- Updated dependency versions

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
