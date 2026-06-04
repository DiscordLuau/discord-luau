# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### api_types

#### Changed

- Permission flags and `MessageFlags` now use string-based bit operations, aligning with Discord's own representation for values that exceed 32-bit range

### binary

#### Added

- `kimpure+sha256` patch restored to fix raw byte hashing and integer overflow in the sha256 dependency
- Windows x86 build of `libsodium` and `libopus` added to the binaries directory
- x86 architecture now recognised in `resolveTokens` so the correct `{arch}` token is substituted in download URLs

#### Changed

- Pinned `kimpure/sha256` dependency to exact version `0.1.1`
- All package manifests now use explicit versioned dependency references instead of workspace references

#### Fixed

- Windows x64 `libopus.dll` and `libsodium.dll` replaced with builds that do not link against libraries unavailable on stock Windows installations

### bit

#### Changed

- Replaced the custom 52-bit integer implementation with the `int64` library, giving true 64-bit integer support
- All bit operations (`bnot`, `bor`, `band`, `lshift`, `rshift`, `shift`) now accept and return decimal strings instead of numbers
- Removed `is32Bit` helper - no longer meaningful with a string-based API

#### Removed

- `bit52.luau` - superseded by `int64`

### builders

#### Changed

- `Permission.bitflag` is now a `string` instead of `number`, matching Discord's wire format for permission bitfields
- `setPermissionBitflag` now accepts `string | number` and stores the value as a string
- `setFlags` on the message builder now accepts a `string` flag value
- Allow and deny bits in `Overwrite.build` are now passed directly as strings rather than converted with `tostring`
- Intent builder now accumulates flags with `bit.bor` and converts to `number` only at the final `build` step

#### Fixed

- Role builder `permissions` field was silently dropping all but the first two permission flags when more than two were set

### classes

#### Changed

- All bitflag classes (`ApplicationBitflag`, `AttachmentBitflag`, `ChannelBitflag`, `GuildMemberBitflag`, `MessageBitflag`, `RoleBitflag`, `SystemChannelBitflag`) now store `flag` internally as a `string`
- `Permission` class now stores the permission bitfield as a `string` rather than `number`, matching Discord's own representation
- Shard calculation in `VoiceBehaviour.joinAsync` now passes the guild snowflake string directly to the bit library instead of calling `tonumber` first

### commands

#### Added

- All `pcall` calls in the dispatch pipeline upgraded to `xpcall` with `debug.traceback`, so error logs now include full stack traces

#### Fixed

- Windows path separators in the loader's require prefix are now normalised so hot-reload works on Windows
- `FutureLike` return casts in `waitForComponent` and `waitForModal` now go through `any` to satisfy strict type analysis

### create_app

#### Added

- `kimpure+sha256` patch template added to all scaffolded project types (vscode, nvim, zed)
- Generated `pesde.toml` now includes the `kimpure/sha256` patch entry alongside the existing `luau_futures` entry

### opus

#### Added

- Windows x86 (`windows-x86`) binary added

#### Fixed

- Windows x64 `libopus.dll` replaced with a build that does not depend on system libraries unavailable on stock Windows

### sodium

#### Added

- Windows x86 (`windows-x86`) binary added

#### Fixed

- Windows x64 `libsodium.dll` replaced with a build that does not depend on system libraries unavailable on stock Windows

### std_polyfills

#### Fixed

- Zune HTTP response body buffer is now normalised to a string before being returned, preventing downstream type errors
- Zune net request options extended with `max_body_size` through a cast to avoid a strict-mode table error
- Zune `fs.watch` callback parameter type now inferred from the Zune typedef instead of a conflicting annotation
- Eryx `ffi.fn` branch now returns the result correctly under strict type analysis
- Resolve `@eryx/` requires for type analysis by adding Eryx typedef stubs and a `.luaurc` alias
- Declare missing Roblox globals (`task`, `Enum`, `DateTime`, `HttpService`) for type analysis
- HTTP response body size limit increased

### tooling

#### Added

- `.zune/publish.luau` script for publishing all non-private workspace packages to the pesde registry with rate-limit pacing

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
