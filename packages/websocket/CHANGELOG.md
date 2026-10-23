# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- The first heartbeat waits `heartbeat_interval * jitter` after Hello, as Discord documents, instead of up to one second, while Identify or Resume goes out on Hello rather than after the first heartbeat ACK; the new `heartbeatJitter` field (default `math.random`) pins the jitter in tests, and a first heartbeat skipped for a replaced socket is logged at debug
- A gateway message whose handler raises is logged at warn and no longer ends the receive loop
- `heartbeatAsync` and `identifyAsync` resolve Err when the send fails, and every caller logs that Err at warn instead of dropping it
- `Manager:connectAsync` logs each shard that fails to connect and resolves Err when none connected, instead of resolving Ok
- Manager test 12a holds the reconnect handshake, so it no longer misses a reconnect that finishes inside one poll

### Added

- `Shard:sendAsync` takes an optional `isStillWanted` callback, checked after any rate-limit wait and just before the send, so a caller can cancel a queued send. Voice uses it so a join request that waited out the rate limit after the connection closed is never sent

### Changed

- Helper methods drop their leading underscore (`_name` is now `name`); they stay marked `@private` and out of the docs

## 0.0.4

### Added

- `Shard:sendResumeAsync`, which sends op 6 Resume for the current session with the last sequence seen
- `Shard.stayDisconnected`, `true` while a shard stays down until `connectAsync` or `reconnectAsync`

### Fixed

- Shards no longer stay offline forever when a reconnect fails part way, after about 95 failed connects or an op 9 mid-reconnect; one reconnect loop now retries with backoff from 1s to 30s until it succeeds, and every attempt ends
- The shard no longer logs at `error` level or above, which cancelled the thread that was reconnecting

### Changed

- Automatic reconnects follow the `reconnect` option; with it off, a shard closes, fires `onSocketDisconnected` with `-1` and stays down until `connectAsync` or `reconnectAsync`
- Reconnects resume the session with op 6 on `resume_gateway_url`, so missed events are replayed; IDENTIFY is only sent when the session is gone, at most once every 90 seconds from the reconnect loop
- Close code 4003 now reconnects with a fresh session
- `reinstantiateAsync` no longer takes `noFail`
- `connectAsync`, `disconnectAsync` and `forceClose` end the session
- `onSocketDisconnected` also fires for server closes during a reconnect, and `-1` now means the shard closed itself
- `Manager:sendAsync` no longer waits on a shard that is staying down

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Changed

- Updated dependency versions

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
