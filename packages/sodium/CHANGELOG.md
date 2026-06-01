# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.2

### Changes

- Binaries are no longer bundled with the package. The `binary` package is now used to resolve, cache, and download the platform-specific `libsodium` shared library on first use. This was necessary because pesde does not permit binary uploads.

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
