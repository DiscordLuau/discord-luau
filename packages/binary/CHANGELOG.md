# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.4

### Fixed

- `kimpure+sha256` patch now includes the `index` blob hash line required by `git2`/libgit2 for patch application to succeed
- Hunk headers now include function context so libgit2 can locate hunks correctly

## 0.0.3

### Fixed

- `kimpure+sha256` patch now uses the correct git diff header so it applies cleanly via `git2`
- Removed timestamps from patch `---`/`+++` lines which were causing parse failures

## 0.0.2

### Added

- x86 architecture now recognised in `resolveTokens` so `{arch}` resolves correctly for 32-bit Windows targets

### Changed

- Pinned `kimpure/sha256` dependency to exact version `0.1.1`
- `kimpure+sha256` patch re-registered - required to fix raw byte hashing and integer overflow that the upstream release did not fully resolve

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
