# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `DISCORD_FRAME_SIZE`, `DISCORD_SAMPLE_RATE`, `DISCORD_CHANNELS`, `MAX_PACKET_SIZE`, `MAX_FRAME_SIZE`, `application`, `sampleRate` and `channels` are now plain values on runtimes without FFI, so `Opus.stats` works there; before, they were placeholder tables that errored when used
- Windows (x64 and x86) loads the current `libopus.dll`; `binary.load` pointed at the `opus-0.0.1` tag, which holds the old DLL, so the download failed its checksum. It now uses `opus-0.0.2`
- Native libraries load on platforms without a system copy, through the `binary` checksum fix

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Added

- Windows x86 binary (`windows-x86/libopus.dll`)

### Fixed

- Windows x64 `libopus.dll` replaced with a build that does not link against libraries unavailable on Windows

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
