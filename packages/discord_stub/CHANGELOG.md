# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- On Windows, the UDP server keeps receiving after a send to a client that has gone. Windows reports it as `ConnectionResetByPeer` on the next receive, which ended the receive loop and failed the scenario with that error
- The UDP server skips an empty datagram. Zune 0.5.9 on Windows can complete a receive with one from no address (seen only while the audio tests kill child processes), and the server took `::` port 0 as the client's address and failed the scenario with "offset out of bounds" when it echoed the empty buffer
- The UDP server sends one packet at a time. On macOS a send that overlapped another, such as a test's `send` during a keepalive echo, was never sent and never returned, which hung the voice specs there. Stopping the server fails the sends still waiting for their turn
- `clock:wait` returns the time that passed on the clock, as `task.wait` does, instead of the duration it was asked for, so callers that add up waits no longer drift from `waitFor` deadlines under load
- An undecodable client message and an error raised by a socket open, message or close callback are recorded in `handlerErrors` instead of being dropped or printed by the runtime

### Added

- `stub:createVoiceServer`, a voice gateway (version 8) double and its UDP server on `127.0.0.1`, attached to the gateway websocket server
- `discordStub.VoiceServer`: Hello, Ready, Session Description, heartbeat ACK echoing `t`, Resumed or close 4006 on Resume, scripted Speaking, Clients Connect, Client Disconnect, JSON and binary messages with `seq`, and every received message with its raw text or buffer
- `discordStub.UdpServer`: IP discovery answers, keepalive echoes and recorded RTP packets
- A default Voice State Update reply on the gateway: VOICE_STATE_UPDATE and VOICE_SERVER_UPDATE pointing at the voice server, a null channel closing the voice connection with 4014, and `ws:moveVoice`
- `connection:sendRaw`, sending a string as a text frame and a buffer as a binary frame
- `opcode` and `raw` on every received record, so a test can see a JSON null that decoding drops
- `WebsocketServer:disconnectVoice(guildId)` takes the stub user out of voice the way a kick does: a null-channel VOICE_STATE_UPDATE, then 4014 on every voice socket
- The voice server can withhold heartbeat ACKs (`ackHeartbeats`), refuse upgrades (`refuseUpgrades`) and hold them (`upgradeDelaySeconds`), and the UDP server can drop discovery requests (`ignoreDiscovery`), so voice reconnect paths can be tested

### Changed

- Helper methods drop their leading underscore (`_name` is now `name`); they stay marked `@private` and out of the docs
- `stub:runScenario` also returns the first voice or UDP server error

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
