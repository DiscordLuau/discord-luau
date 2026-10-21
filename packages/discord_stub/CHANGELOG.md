# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.1

### Added

- `discordStub.new`, a local Discord world with a virtual or real clock
- `stub:createHttpServer`, serving custom routes and the default `GET /api/v10/gateway/bot`
- `stub:createWebsocketServer`, serving Hello, heartbeat ACK and READY, with `send` and `close`
- `stub.clock:waitFor`, polling a predicate in clock time
- `ws.connections`, one connection per accepted websocket with its path, session, close code and received payloads, read through `latestConnection`, `openConnections` and `receivedOps`
- Websocket handlers that receive the connection and may return `false` to send nothing, with handler errors kept in `ws.handlerErrors`
- Sessions and Resume: `stub-session-{n}` per Identify, `dispatch` and `missDispatch` over a dispatch log, replay after `seq` then RESUMED, and op 9 for an unknown session
- `ws.refuseUpgrades` and `ws.upgradeDelaySeconds`, counted by `connectAttempts` and shown by `handshaking`, to fail or hold a client's connect
- `stub:runScenario`, running a test body, its teardown and `stop`, and returning the first error
- `discordStub.recordEmits`, recording every call an emitter fires
