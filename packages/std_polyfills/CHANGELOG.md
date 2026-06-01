# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Resolve `@eryx/` requires for type analysis by adding Eryx typedef stubs and a `.luaurc` alias
- Declare missing Roblox globals (`task`, `Enum`, `DateTime`, `HttpService`) for type analysis
- Zune `fs.watch` callback parameter type now inferred from the Zune typedef instead of a conflicting annotation
- Zune net request options extended with `max_body_size` through a cast to avoid a strict-mode table error
- `ffi.fn` Eryx branch now returns the result correctly under strict type analysis

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
