# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Pinned `kimpure/sha256` dependency to exact version `0.1.1` rather than the loose `^0.1.1` range

### Removed

- `kimpure+sha256` patch - the upstream `0.1.1` release already includes the binary blob hashing fix the patch was applying

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
