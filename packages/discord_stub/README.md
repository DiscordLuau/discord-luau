# discord_stub

A local Discord for tests and examples: an HTTP server and a websocket gateway on `127.0.0.1`, with an optional
virtual clock.

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
`closeCode` and `received` (every payload with the clock time it arrived); `ws:latestConnection()`,
`ws:openConnections()` and `ws:receivedOps(opcode)` read them, and a connection can `send(payload)` and `close(code?)`
on its own. An error raised by the handler lands in `ws.handlerErrors` instead of vanishing into Zune.

Identify starts session `stub-session-{n}` and READY carries `resume_gateway_url = "{ws.url}/resume"`.
`ws:dispatch(event, data)` sends a dispatch to the connections bound to that session; `ws:missDispatch(event, data)`
only logs one. Resume replays every logged dispatch after the client's `seq`, then RESUMED; any other session gets
`{ op = 9, d = false }`. `ws.refuseUpgrades = n` refuses the next `n` upgrades (the client fails with `UpgradeFailed`)
and `ws.upgradeDelaySeconds` holds each upgrade that long in clock time, with `ws.handshaking` true meanwhile.

`discordStub.new({ clock = "virtual", polyfills = stdPolyfills })` runs the stub 100x faster than real time: `task`
and `datetime` on that table are accelerated for the life of the stub, and `stub:stop()` restores them. The table must
be the `std_polyfills` the code under test requires; without it only the stub's own copy is swapped and the code under
test keeps real time. `stub.clock:waitFor(predicate, seconds)` polls in clock time.

`stub:runScenario(scenario, teardown?)` runs a test body, then the teardown, then `stub:stop()` even when either
throws, and returns the body's error, else the teardown's error, else the first handler error, else nil.
`discordStub.recordEmits(emitter)` returns a list that gains the packed arguments of every call the emitter fires.

`discord_stub` is an independent implementation built from Discord's public developer documentation. It is not
affiliated with or endorsed by Discord, and it ships no Discord marks or logos. Use it only as a local test double.
