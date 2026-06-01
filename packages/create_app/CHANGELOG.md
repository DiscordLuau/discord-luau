# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixes

- Fixed TUI hanging indefinitely when the target project directory already exists; `setupProject` now raises a catchable error instead of killing the coroutine via `Logger:error`, allowing the wizard to display the failure message correctly.
## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
