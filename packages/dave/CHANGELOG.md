# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.5

### Fixed

- An error raised by the MLS failure callback, the encryptor's protocol-version-changed callback or the log sink callback is logged at warn through the package logger (`Dave.log`) instead of vanishing; an unreadable MLS failure source or reason is warned instead of becoming an empty string
- The pairwise-fingerprint closure no longer lets an error escape into libdave, which aborted Zune; it warns instead
- A NULL from libdave (no key ratchet yet, a rejected welcome) no longer tags Zune's shared null pointer, which broke every later call that passed NULL, in sodium and opus too
- Pointers libdave hands back have any stale tag from a freed and reused address cleared before use
- `Decryptor:decrypt` and `Encryptor:encrypt` raise an error naming the libdave result when a frame fails, instead of logging at error level, which cancelled the calling thread. One undecryptable frame during a key transition used to stop the voice receive loop for good
- A libdave log message that cannot be read reaches the log sink callback with the read error, instead of as an empty string

### Changed

- `Session:getKeyRatchet` returns nil when there is no ratchet; `Session.new`, `Encryptor.new`, `Decryptor.new` and `Session:processCommit` raise when libdave returns NULL
- `destroy()` on a `Session`, `Encryptor` or `Decryptor` clears its handle, so a later call raises instead of using freed native memory, and a second `destroy()` does nothing
- The `CommitResult`, `WelcomeResult`, `Session:processCommit` and `Session:processWelcome` docs say the results hold a change set, not the roster, and `getRosterMemberSignature` aborts on an id from elsewhere; `Session:getPairwiseFingerprint` warns that it crashes Zune once a group exists

## 0.0.4

### Fixed

- `Session:getProtocolVersion()` returns 0 before `init` on every platform; libdave leaves it uninitialised until then, so it returned garbage on Windows
- Native libraries load on Windows and other platforms without a system copy, through the `binary` checksum fix

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Changed

- Updated dependency versions

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
