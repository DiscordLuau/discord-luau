# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.4

### Added

- `DaveManager:hasPendingDowngrade()` says whether a transition to DAVE protocol version 0 is prepared and not executed yet
- `connection.dave.mediaReady`, `Connection.onMediaReady` and `Connection:awaitMediaReadyAsync(timeoutSeconds?)` say when audio can flow: at once without DAVE, and with DAVE once the bot holds the group's key. `onReady` still means the connection is ready. `awaitMediaReadyAsync` fails with `timed out waiting for DAVE media readiness` or `voice connection closed: <reason>`, so a caller can tell the two apart
- `Connection:joinAsync(timeoutSeconds?)` resolves once the connection is ready and fails with a reason; `Connection:leaveAsync()` sends op 4 with a null channel and closes; `Connection:destroy()` closes synchronously; `status` and `onClosed(reason, code)` say where a connection is and why it ended (`left`, `removed`, `joinTimedOut`, `gaveUp`, `rejected`, `shardDown`)
- `voice.opusSamples(packet)` returns how many 48 kHz samples an Opus packet holds, read from its TOC byte (RFC 6716 section 3.1), and raises `invalid Opus packet: <reason>`, with no file position, for an empty or malformed packet or one longer than 120 ms
- `Connection.decodeAudio` (true by default): set it to false to skip Opus decoding of received audio, loss concealment included; `onAudioFrame` then never fires while `onRawAudioFrame` still does. `Jitter:start` takes the matching `shouldDecode` predicate, asked once per slot, and a jitter that resumes decoding replaces its idle decoder first

### Changed

- Helper methods drop their leading underscore (`_name` is now `name`; DAVE's `_createDecryptor` is now `createMemberDecryptor`); they stay marked `@private` and out of the docs
- The connection docs describe `onRawAudioFrame` (the Opus payload without the RTP header, as the jitter buffer plays it), `onAudioFrame`, `onReady` and `Connection.new`'s settings, and the README points to `discord_luau/audio` for playing audio
- A supervisor owns every lifecycle decision. It waits for both VOICE_STATE_UPDATE and VOICE_SERVER_UPDATE before connecting, follows moves and voice server changes, resumes once after 4015, abnormal closes and missed heartbeat ACKs, waits five seconds after 4014 and 4022 to tell a kick from a server change or a replaced gateway session, closes for good on fatal codes, and rejoins with backoff up to five attempts otherwise. Every connect is bounded by its deadline, even when the voice handshake never finishes
- Every terminal close except a kick sends op 4 with a null channel, so a failed or abandoned connection no longer leaves the bot sitting in the channel
- `requestVoiceAsync` is now an alias of `joinAsync`, `disconnectAsync` closes the connection for good, and `forceClose` is treated as a drop that the supervisor recovers from
- `WebSocketTransport:forceClose()` also abandons an open still in its handshake, which closes its socket when it finishes, so a new open can start at once
- `onReady` fires once per new session, when the connection's status becomes ready (the first join, a rejoin or a server change); a resumed session fires the new `onResumed` instead of `onReady`
- The gateway needs the `GuildVoiceStates` intent: without it Discord never sends the bot its own voice state, and a join fails with a message saying so
- The DAVE manager makes its MLS session, encryptor and decryptors through `createSession`, `createEncryptor` and `createDecryptor`, which tests can replace, and sends its own voice gateway messages through `sendMessage`. `initSession` is replaced by `handleSessionDescription`; `handleExternalSender` and `handlePrepareEpoch` no longer return a frame or take ids
- `onDaveEpochTransition` fires when a DAVE transition executes (op 22, or at once for transition 0) with the number of MLS group members, the bot included, after media readiness is updated, so a listener sees the new `mediaReady`; it fired at commit time with the size of the commit's change set, and when the bot sent its own commit. `DaveManager.recognizedUserIds` is a set, and the manager's opcode handlers send their own replies and return nothing
- `UdpTransport:sendOpusAsync` requires the DAVE manager in place of its encryptor, reads the DAVE state when the send runs, and fails without sending while the manager's DAVE protocol version is not known yet; `RtpCrypto:encryptRtp` takes the media protocol version and readiness and also returns whether it sent silence; `RtpCrypto:decryptRtp` takes the media protocol version and whether a move to version 0 is pending
- Under DAVE, a payload that is exactly the Opus silence frame `F8 FF FE` goes out without DAVE encryption even when media is ready, as discord.js and DAVEY send it; libdave's decryptors pass it through

### Fixed

- A move away and back during the 4014 grace, with no voice server update, now rejoins and fires `onReady`. Before, the connection was marked ready with no voice socket and no event
- The RTP nonce goes on the wire big-endian, as other clients send it, and a session that would reuse a nonce after 2^32 packets fails the send with `RTP nonce exhausted; the session needs a new key` instead of wrapping to 0
- A received packet with CSRCs is handed on with a CSRC count of 0, matching the 12-byte header it keeps; the count used to survive the dropped CSRC list
- A DAVE commit or welcome libdave cannot process is answered with op 31 and a group reset with a new key package, so the voice gateway adds the bot again; a failure used to leave the bot out of the group for good. A burst of failures sends op 31 once. The handler that treated op 31 as a message from the server is gone
- A binary voice gateway message whose sequence number starts with the byte `0x7B` is read as binary; the reader guessed the frame type from the first byte, took `{` for JSON and dropped the message. The guess remains only for a socket that cannot report the frame type
- The RTP timestamp advances by each Opus packet's own duration; it assumed 20 ms frames, so 2.5, 5, 10, 40 and 60 ms packets and multi-frame packets were stamped wrong. An invalid Opus packet fails the send before it takes a sequence number or timestamp
- `sendOpusAsync` fails with `audio send failed: <reason>` when the UDP send fails; it resolved Ok after a warn. The sequence number and timestamp stay used, so a failed send is plain loss to the receiver
- `setSpeakingAsync` fails with `cannot set speaking: SSRC not assigned` before the voice server assigns an ssrc, instead of sending op 5 without one
- A throw after UDP IP discovery (for example in Select Protocol or while choosing the encryption mode) and in the first heartbeat after Hello is warned and recorded as a handshake or heartbeat failure the supervisor acts on, instead of vanishing into a silent join timeout
- Voice gateway identify, resume, select protocol, speaking and heartbeat sends that cannot go out resolve Err, instead of Ok after a lost warn; a failed periodic heartbeat is warned and the next one is still scheduled
- A packet whose handling raises in the UDP receive loop is warned and the loop keeps receiving, instead of ending with the receive thread still marked running
- A UDP discovery reader that fails on the current socket and a failed UDP keepalive send are logged at warn, not debug
- DAVE sessions created by the voice package log libdave's MLS failures at warn, as `DAVE MLS failure in <source>: <reason>`
- Voice heartbeats and Resume carry `seq_ack`, starting at -1 and reset on every Identify; Resume used to omit it, which v8 requires
- UDP IP discovery retries a lost reply (three requests, two seconds each), checks that the reply is a discovery reply for this ssrc, and fails with a reason instead of resolving with no address or waiting forever
- A voice WebSocket that finishes opening after its connection stopped wanting it is closed at once, and opening a second socket while one is open or opening raises instead of orphaning the first
- The voice WebSocket receive loop runs from the first message. It compared itself with a thread field that was only assigned after its first yield, so it stopped at once and the connection never became ready
- A truncated binary voice frame, undecodable JSON or an error in a message handler is logged at warn and the receive loop carries on; each used to end the loop
- A normal close from the voice server is logged at info; it was reported as `voice socket receive error: no error`
- The UDP receive loop survives truncated packets, transient receive errors and errors in the audio handler, and repeated decrypt failures are reported once per second with a count instead of once per packet
- Opus frames sent back to back carry consecutive RTP sequence numbers and timestamps; the counters moved only after the send yielded, so concurrent sends reused them
- AES-256-GCM is chosen only when the server offers it and the CPU supports it, otherwise XChaCha20-Poly1305; the first offered mode used to win regardless of hardware support
- The jitter buffer plays every packet after the sender pauses, never rewinds on a late duplicate, stops producing frames once the speaker goes quiet, resyncs after a sequence jump, and can be destroyed from inside its own frame callback. Errors in frame callbacks are logged at warn with a traceback
- No voice code logs at error or critical any more; those levels cancel the logging thread, which silently stopped heartbeats, handshakes and reconnects
- Closing a connection or a UDP transport from inside one of its own callbacks no longer raises "cannot close running coroutine"; every thread the voice package starts is resumed and closed with its result checked and logged at warn
- The bot can join a voice channel that already has people in it. DAVE welcomes and commits start with a two-byte transition id, but four bytes were read, so the welcome lost its cipher suite and libdave rejected it. The bot's own user id is now also recognized when a welcome is processed
- After a DAVE welcome or commit the bot sends ready for transition (op 23) as JSON with the transition id, so the server switches keys within a round trip instead of after its two-second timeout, during which incoming audio could not be decrypted. The reply to a prepare transition was a one-byte binary frame and is now the same JSON; transition 0 gets no reply
- Audio from a speaker whose DAVE keys have not arrived yet is dropped instead of being passed to the Opus decoder as ciphertext
- Every path that skips a packet, a frame or a step logs why at debug; libdave's info messages are logged at debug instead of being dropped, and a jitter buffer created without a logger logs as `Jitter` instead of discarding its warnings
- A closed connection no longer reacts to later VOICE_SERVER_UPDATEs, and a voice socket or op 4 that finishes after a close is dropped instead of putting the bot back in the channel. A heartbeat, IP discovery or Select Protocol that finishes for a replaced connect no longer acts on the new one
- Tearing down a UDP transport no longer yields or makes Zune print `Cancel Error: error.NotFound`: the socket closes on its own thread once its sends in flight finish, and the receive and keepalive loops end on their own instead of being closed mid-operation. A failed IP discovery no longer clears a newer session's socket
- A Session Description whose secret key is not 32 bytes fails the connect instead of producing undecryptable audio
- Key rotation skips a missing key ratchet instead of passing nil to libdave
- With DAVE, the bot sends its key package (op 26) as soon as Session Description creates the session, and again after op 24 with epoch 1, instead of only in reply to op 25. Op 25 now stores the external sender and applies it to the session
- Op 24 resets the DAVE group only when its epoch is 1, as a number or a numeric string; it threw away an established group on every prepare epoch. A reset makes a new MLS session, because libdave never clears an old session's roster, applies the stored external sender to it and replaces the encryptor
- The DAVE encryptor is created with the session at Session Description and told the bot's ssrc carries Opus, instead of at the first commit
- An empty DAVE key package is logged at warn and not sent
- The DAVE roster is mirrored from libdave's change sets. Each commit or welcome result lists only what changed, but it was read as the whole roster, so unchanged members lost their decryptors and members who left kept theirs
- Op 11 adds to the recognized users and op 13 removes the user and destroys their decryptor; op 11 replaced the list and op 13 left it alone. Proposals and welcomes both get the recognized users and the bot
- DAVE transitions are tracked by id: a commit's or welcome's transition is recorded, op 21 records its version without applying it, op 22 applies the version it was prepared with, and transition 0 executes at once. The bot's own key is held until its transition executes, and the encryptor gets one key per epoch. A move to protocol version 0 puts decryptors in passthrough at op 21 and the encryptor at op 22, and a move back to DAVE ends passthrough. An op 21 without a numeric transition id and protocol version, or an op 22 without a numeric transition id, is warned and ignored
- Every DAVE key ratchet is destroyed once applied; one leaked per member per epoch. The bot's key held for a transition is taken when it executes and destroyed unused when the transition moves to protocol version 0 or there is no encryptor, and it is held before the members' keys are handed out, so a failing decryptor cannot leak it
- With DAVE, audio is never sent unencrypted: until the bot holds the group's key, each Opus frame is replaced by the 3-byte Opus silence frame, logged at debug once per gap. Plain Opus used to go out whenever the encryptor had no key, and a send created before a group reset could run with the destroyed encryptor
- With DAVE, a plain frame from a sender with no decryptor is dropped, except Opus silence and while a move to protocol version 0 is pending; it used to be played as if it were decrypted
- Received RTP packets whose payload type is not Opus (0x78, marker bit ignored) are skipped at debug before decryption; only RTCP was skipped, so any other payload type was decrypted and handed to the jitter buffer as audio
- A received packet too short for its header, tag and nonce, or whose header extension claims more than it carries, is dropped with a debug line; it used to fail inside the decryptor and count as a decrypt failure at warn

### Removed

- `DaveManager:rotateDaveKeys`, `DaveManager.pendingDaveProtocolVersion` and `DaveManager.isPendingCommitter`: the manager hands out keys itself when it processes a commit or welcome, and tracks transitions by id
- `UdpTransport.udpPing` and `keepaliveSentAt`: Discord never echoes the voice UDP keepalive, so `udpPing` never had a value and `keepaliveSentAt` grew by one entry every five seconds. The keepalive itself is still sent
- `WebSocketTransport.socketReconnecting`; the supervisor sequences reconnects

## 0.0.3

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.2

### Changed

- Updated dependency versions

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
