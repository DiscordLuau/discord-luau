# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Opus.checkBitrate(bitsPerSecond)` raises unless the bitrate is a whole number from 500 to 510000
- `Encoder:setBitrate`, `getBitrate`, `setSignal` and `getSignal` set and read the target bitrate and the `"auto"`, `"voice"` or `"music"` signal hint

### Changed

- The Windows libopus is 1.6.1 built from source, and every libopus binary is reproducible
- The README explains the frame length `encode` takes, `decodeFec`, `decodePLC`, `stats` and that opus needs FFI

### Fixed

- macOS on Intel (macos-x64) now has a libopus, and macos-arm64 is built with NEON
- A system libopus no longer replaces ours: the package always loads its own checksummed libopus
- `Decoder` and `Encoder` no longer leak native memory: every `decode`, `decodePLC`, `decodeFec` and `encode` used to allocate input and output buffers that were never freed (about 24 KB per decoded frame, roughly 4 GB per hour per speaking user); each object now allocates them once and frees them in `destroy`
- `Decoder:decodeFec` recovers exactly one 20 ms frame; it asked libopus for 120 ms, so every recovered packet added 100 ms of extra audio
- Using a `Decoder` or `Encoder` after `destroy()` raises an error instead of crashing the process

## 0.0.4

### Fixed

- `DISCORD_FRAME_SIZE`, `DISCORD_SAMPLE_RATE`, `DISCORD_CHANNELS`, `MAX_PACKET_SIZE`, `MAX_FRAME_SIZE`, `application`, `sampleRate` and `channels` are now plain values on runtimes without FFI, so `Opus.stats` works there; before, they were placeholder tables that errored when used
- Windows (x64 and x86) loads the current `libopus.dll`; `binary.load` pointed at the `opus-0.0.1` tag, which holds the old DLL, so the download failed its checksum. It now downloads from `opus-0.0.4`
- Linux (x64 and arm64) `libopus.so` is rebuilt against glibc 2.17, so it loads on Ubuntu, Debian and most servers; the previous build needed glibc 2.43 and failed to load anywhere older
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
