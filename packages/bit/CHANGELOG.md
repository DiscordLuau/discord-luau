# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.2

### Changed

- Replaced the custom 52-bit integer implementation with the `int64` library, giving true 64-bit integer support
- All bit operations (`bnot`, `bor`, `band`, `lshift`, `rshift`, `shift`) now accept and return decimal strings instead of numbers
- Removed `is32Bit` helper - no longer meaningful with a string-based API

### Removed

- `bit52.luau` - superseded by `int64`

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
