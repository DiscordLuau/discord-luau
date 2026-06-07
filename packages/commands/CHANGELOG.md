# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Added

- All `pcall` calls in the dispatch pipeline, loader, and guards upgraded to `xpcall` with `debug.traceback` so error logs now include full stack traces

### Fixed

- Windows path separators in the loader's require prefix are now normalised so hot-reload works correctly on Windows
- `FutureLike` return casts in `waitForComponent` and `waitForModal` now go through `any` to satisfy strict type analysis

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
