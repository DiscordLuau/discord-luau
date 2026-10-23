# discord_stub

A local Discord for tests and examples: an HTTP server, a websocket gateway, and a voice gateway with its UDP server,
all on `127.0.0.1`, with an optional virtual clock.

---

Both servers listen on an ephemeral port on `127.0.0.1`; `stub:createHttpServer` and `stub:createWebsocketServer`
return handles with `url`, `port` and `stop()`. An HTTP handler receives the request and may return a response or a
raw string body. A websocket handler receives the connection and the decoded payload and may return a payload to send
instead of the default, or `false` to send nothing. Returning `nil` falls through to the defaults (the
`/api/v10/gateway/bot` route, Hello, heartbeat ACK, READY on Identify, replay and RESUMED on Resume).

`stub.restUrl` is `http://127.0.0.1:{port}/api/v10` once the HTTP server exists, and nil before it. `ws:send(payload)`
sends a payload to every open connection; `ws:close(code?)` closes them all, 1000 by default.

The websocket server records what happened for a test to assert on. `ws.connections` keeps every connection ever
opened, each with its `index`, upgrade `path` (`/` for a fresh dial, `/resume` for a resume), `sessionId`, `open`,
`closeCode` and `received` (every payload with its `opcode`, the `raw` text and the clock time it arrived; Zune decodes
a JSON null to nil, so only the raw text shows `"channel_id":null`); `ws:latestConnection()`, `ws:openConnections()`
and `ws:receivedOps(opcode)` read them, and a connection can `send(payload)`, `sendRaw(message)` (a string as a text
frame, a buffer as a binary frame) and `close(code?)` on its own. An error raised by the handler lands in
`ws.handlerErrors` instead of vanishing into Zune.

Identify starts session `stub-session-{n}` and READY carries `resume_gateway_url = "{ws.url}/resume"`.
`ws:dispatch(event, data)` sends a dispatch to the connections bound to that session; `ws:missDispatch(event, data)`
only logs one. Resume replays every logged dispatch after the client's `seq`, then RESUMED; any other session gets
`{ op = 9, d = false }`. `ws.refuseUpgrades = n` refuses the next `n` upgrades (the client fails with `UpgradeFailed`)
and `ws.upgradeDelaySeconds` holds each upgrade that long in clock time, with `ws.handshaking` true meanwhile.

`discordStub.new({ clock = "virtual", polyfills = stdPolyfills })` runs the stub 100x faster than real time: `task`
and `datetime` on that table are accelerated for the life of the stub, and `stub:stop()` restores them. The table must
be the `std_polyfills` the code under test requires; without it only the stub's own copy is swapped and the code under
test keeps real time. `stub.clock:waitFor(predicate, seconds)` polls in clock time.

`stub:createVoiceServer(options?)` starts a voice gateway speaking version 8 (`stub.voiceServer`) and the UDP server
it points at (`stub.udpServer`), both on the world clock, and attaches the voice server to the gateway websocket
server whether that exists yet or not. The options are `heartbeatIntervalMilliseconds` (41250), `modes`
(`aead_aes256_gcm_rtpsize` and `aead_xchacha20_poly1305_rtpsize`), `daveProtocolVersion` (0), `token` and
`sessionId`.

With a voice server attached, the gateway answers Voice State Update (op 4) as Discord does: VOICE_STATE_UPDATE for
the READY user with `voice.sessionId`, then VOICE_SERVER_UPDATE with `voice.token` and `endpoint = voice.url`
(`ws://127.0.0.1:{port}`, scheme included). A null `channel_id` dispatches the state with a null channel, sends no
VOICE_SERVER_UPDATE, and closes every open voice connection with 4014. `ws:moveVoice(guildId, channelId)` dispatches
the pair for a move. A handler that answers op 4 replaces the default, and without a voice server op 4 gets no
reply.
`ws:disconnectVoice(guildId)` takes the stub user out of voice the way a kick does: a null-channel state, then
4014 on every voice socket.

The voice server sends Hello on open; Ready (`ssrc` 1234, `ip` `127.0.0.1`, the UDP port, `modes`) on Identify;
Session Description (the chosen mode, `secret_key` as the 32 numbers of `voice.secretKey`, `dave_protocol_version`)
on Select Protocol; an ACK echoing `t` on Heartbeat; and Resumed on a Resume whose `server_id`, `session_id` and
`token` match the session, else close 4006. A mode Ready did not offer closes with 4016, and a message that does not
decode closes with 4002. `voice:sendSpeaking(userId, ssrc, speaking)`, `voice:sendClientsConnect(userIds)`,
`voice:sendClientDisconnect(userId)` and `voice:sendJson(opcode, data)` send JSON carrying a rising `seq`;
`voice:sendBinary(opcode, payload)` sends the sequence as 2 big-endian bytes and the opcode as 1 byte before the
payload. `voice:close(code)` closes every open connection. `voice.received` keeps every client message with its
`opcode`, decoded `payload` (a binary one decodes to `{ op, d = payload buffer }`), `raw` text or buffer and clock
time; `voice:receivedOps()` lists the opcodes and `voice:waitForOp(opcode, seconds)` waits for one. An error raised
while answering a message lands in `voice.errors`.
`voice.ackHeartbeats = false` withholds the Heartbeat ACK, `voice.refuseUpgrades = n` fails the next `n` connects
with `UpgradeFailed`, and `voice.upgradeDelaySeconds` holds each upgrade that long in clock time, with
`voice.handshaking` true meanwhile.

The UDP server answers a 74-byte IP discovery request with the address and port the request came from, echoes any
packet that is not RTP (a keepalive) unchanged, and records RTP packets in `udp.packets`. `udp.clientAddress` and
`udp.clientPort` name the latest sender and `udp:send(packet)` answers it. The receive loop yields while it waits,
ends on `udp:stop()`, and puts any other receive error in `udp.errors`. `discordStub.VoiceServer.new` and
`discordStub.UdpServer.new` build either double outside a world.
`udp.ignoreDiscovery = n` drops the next `n` discovery requests without a reply.

```luau
local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
local ws = stub:createWebsocketServer()
local voice = stub:createVoiceServer()

-- connect a shard to ws.url, then have the library send op 4 for guild "10", channel "20"
stub.clock:waitFor(function()
	return voice.selectedMode
end, 30)
```

`stub:runScenario(scenario, teardown?)` runs a test body, then the teardown, then `stub:stop()` even when either
throws, and returns the body's error, else the teardown's error, else the first handler error, else the first voice
or UDP server error, else nil.
`discordStub.recordEmits(emitter)` returns a list that gains the packed arguments of every call the emitter fires.

`discord_stub` is an independent implementation built from Discord's public developer documentation. It is not
affiliated with or endorsed by Discord, and it ships no Discord marks or logos. Use it only as a local test double.
