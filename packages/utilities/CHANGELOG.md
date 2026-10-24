# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.3

### Fixed

- Requiring utilities no longer reseeds `math.random` to the same sequence in every process, so GUIDs no longer repeat across restarts
- `coroutineRun` rethrows a first-run error with the thread traceback instead of the bare message

## 0.0.2

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
