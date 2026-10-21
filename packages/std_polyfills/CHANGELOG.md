# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.4

### Fixed

- Lute `task.delay` returns a thread, so `task.cancel` works on it
- Lute `io.stderrWrite` no longer prints a stray `2`; it writes to stdout because Lute has no stderr writer
- Lune `process.getArch` returns the CPU architecture
- Lune `fileSystem.stat` returns the size of a file
- Zune `serde.decode("json", buffer)` accepts a buffer
- Eryx `ffi` requires `@eryx/experimental/_ffi`

### Changed

- `runtime.capabilities().ffi` is `true` on Zune again, so `dave`, `opus` and `sodium` work there; tested on Linux x64 and Windows x64 with Zune 0.5.9
- Verified on Lune 0.11.0, Zune 0.5.9, Lute 1.0.1-nightly.20261021 and Eryx 0.1.0

## 0.0.3

### Added

- Lute runtime support: full polyfill implementation across all modules (`task`, `process`, `net`, `fileSystem`, `datetime`, `stdio`, `io`, `serde`)
- Lute runtime detection via `pcall(require, "@lute/fs")` probe - Lute does not override `_VERSION` so it cannot be identified by version string alone
- All dispatch layers now route to Lute implementations instead of erroring with an unsupported-runtime message
- `process.onSignal` dispatch extended to support Lute alongside Zune
- Lute `serde.decode` sanitizes JSON null - Lute's JSON parser returns a userdata singleton for null values and encodes null-type flag fields (e.g. `"premium_subscriber": null`) as `{[null_userdata] = true}` entries; both forms are now recursively converted to Lua `nil`
- Lute `net.request` builds query parameters directly into the URL, as Lute's native HTTP client ignores the `query` field in the opts table
- Lute `fileSystem.stat` returns `{kind = "none"}` for missing paths instead of throwing

### Fixed

- Lute `onSignal` capability corrected to `true` - signal handling is available via `@std/process`
- Zune `ffi` capability corrected to `false`
- `task.defer`, `task.delay`, and `task.spawn` variadic argument type widened from `T...` to `any` to resolve type errors at call sites

## 0.0.2

### Fixed

- Zune HTTP response body buffer normalised to a string before returning, preventing downstream type errors
- Zune net request options extended with `max_body_size` through a cast to avoid a strict-mode table error
- Zune `fs.watch` callback parameter type now inferred from the Zune typedef instead of a conflicting annotation
- `ffi.fn` Eryx branch now returns the result correctly under strict type analysis
- Resolve `@eryx/` requires for type analysis by adding Eryx typedef stubs and a `.luaurc` alias
- Declare missing Roblox globals (`task`, `Enum`, `DateTime`, `HttpService`) for type analysis
- HTTP response body size limit increased to accommodate larger API responses

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
