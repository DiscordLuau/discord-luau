# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.4

### Changed

- `Message.flags` type in both `new()` input and the internal `Message` type changed from `number?` to `string?`, matching the bit library's string-based representation

### Fixed

- `Message.build()` now converts stored string flags to a `number` via `tonumber` before including them in the JSON payload

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Changed

- `Permission.bitflag` is now a `string` instead of `number`, matching Discord's wire format for permission bitfields
- `setPermissionBitflag` now accepts `string | number` and stores the value as a string
- `setFlags` on the message builder now accepts a `string` flag value
- Allow and deny bits in `Overwrite.build` are now passed directly as strings rather than converted with `tostring`
- Intent builder now accumulates flags with `bit.bor` and converts to `number` only at the final `build` step

### Fixed

- Role builder `permissions` field was silently dropping all but the first two permission flags when more than two were set (`table.unpack` passed to a two-argument `bor`)

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
