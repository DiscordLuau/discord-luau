local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local discordStub = require("../src/init")

local IDENTIFY_PAYLOAD = { op = 2, d = { token = "stub-token", intents = 0 } }

local test = frktest.test
local check = frktest.assert.check

local function connect(url: string, received: { any }, closed: { number? }): HttpWebSocket
	return zune.net.http.websocket(url, {
		message = function(_, message)
			table.insert(received, stdPolyfills.serde.decode("json", message))
		end,
		close = function(_, code)
			table.insert(closed, code)
		end,
	})
end

local function sendPayload(socket: HttpWebSocket, payload: any)
	socket:send(stdPolyfills.serde.encode("json", payload))
end

local function findOp(received: { any }, op: number): any
	for _, payload in received do
		if payload.op == op then
			return payload
		end
	end

	return
end

local function findEvent(received: { any }, event: string): any
	for _, payload in received do
		if payload.t == event then
			return payload
		end
	end

	return
end

local function dispatchSummary(received: { any }): { string }
	local summary = {}

	for _, payload in received do
		if payload.op == 0 then
			table.insert(summary, `{payload.t} {payload.s}`)
		end
	end

	return summary
end

return function()
	test.suite("discord_stub websocket", function()
		test.case("hello, heartbeat ACK and READY are the defaults", function()
			local stub = discordStub.new()
			local ws = stub:createWebsocketServer()
			local received = {}
			local closed = {}
			local socket = connect(ws.url, received, closed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(received, 10)
			end, 2))

			check.equal(findOp(received, 10).d.heartbeat_interval, 41250)

			sendPayload(socket, { op = 1 })

			check.is_true(stub.clock:waitFor(function()
				return findOp(received, 11)
			end, 2))

			sendPayload(socket, IDENTIFY_PAYLOAD)

			check.is_true(stub.clock:waitFor(function()
				return findEvent(received, "READY")
			end, 2))

			local ready = findEvent(received, "READY")

			check.equal(ready.s, 1)
			check.equal(ready.d.user.username, "Stub")
			check.equal(ready.d.session_id, "stub-session-1")
			check.equal(ready.d.resume_gateway_url, `{ws.url}/resume`)

			ws:close(4000)

			check.is_true(stub.clock:waitFor(function()
				return #closed > 0 and closed[1] == 4000
			end, 2))

			stub:stop()
		end)

		test.case("a handler replaces the default reply and send broadcasts", function()
			local stub = discordStub.new()
			local ws = stub:createWebsocketServer(function(_, payload)
				return if payload.op == 2
					then { op = 0, t = "READY", s = 7, d = { v = 10, session_id = "custom-session" } }
					else nil
			end)
			local received = {}
			local closed = {}
			local socket = connect(ws.url, received, closed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(received, 10)
			end, 2))

			sendPayload(socket, { op = 2 })

			check.is_true(stub.clock:waitFor(function()
				return findEvent(received, "READY")
			end, 2))

			check.equal(findEvent(received, "READY").d.session_id, "custom-session")

			ws:send({ op = 0, t = "MESSAGE_CREATE", d = { id = "3" } })

			check.is_true(stub.clock:waitFor(function()
				local message = findEvent(received, "MESSAGE_CREATE")

				return message and message.d.id == "3"
			end, 2))

			check.equal(ws:openConnections(), 1)

			stub:stop()
		end)

		test.case("gateway/bot reports the websocket url", function()
			local stub = discordStub.new()
			local ws = stub:createWebsocketServer()
			local http = stub:createHttpServer()
			local response = zune.net.http.request(`{http.url}/api/v10/gateway/bot`)
			local body = stdPolyfills.serde.decode("json", response.body)

			check.equal(response.status_code, 200)
			check.equal(body.url, ws.url)
			check.equal(body.shards, 1)

			stub:stop()
		end)

		test.case("stopping the handle detaches it and gateway/bot returns 503", function()
			local stub = discordStub.new()
			local ws = stub:createWebsocketServer()
			local http = stub:createHttpServer()

			ws:stop()

			local response = zune.net.http.request(`{http.url}/api/v10/gateway/bot`)

			check.equal(response.status_code, 503)
			check.equal(stub.webSocketServer, nil)

			stub:createWebsocketServer()

			stub:stop()
		end)

		test.case("refused upgrades are counted, queue no path and fail the client with UpgradeFailed", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()

			ws.refuseUpgrades = 2

			local firstConnected, firstFailure = pcall(connect, `{ws.url}/resume/?v=10`, {}, {})
			local secondConnected, secondFailure = pcall(connect, `{ws.url}/resume/?v=10`, {}, {})
			local thirdConnected = pcall(connect, `{ws.url}/?v=10`, {}, {})

			check.is_false(firstConnected)
			check.equal(firstFailure, "UpgradeFailed")
			check.is_false(secondConnected)
			check.equal(secondFailure, "UpgradeFailed")
			check.is_true(thirdConnected)
			check.equal(ws.connectAttempts, 3)
			check.equal(ws.refuseUpgrades, 0)

			check.is_true(stub.clock:waitFor(function()
				return #ws.connections == 1
			end, 30))

			check.equal(ws.connections[1].path, "/")
			check.equal(#ws.pendingPaths, 0)

			stub:stop()
		end)

		test.case("upgradeDelaySeconds holds the client's connect while handshaking is true", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local connected = false
			local started = stub.clock:now()

			ws.upgradeDelaySeconds = 20

			zune.task.spawn(function()
				connect(ws.url, {}, {})

				connected = true
			end)

			check.is_true(stub.clock:waitFor(function()
				return ws.handshaking
			end, 10))

			check.is_false(connected)
			check.equal(#ws.connections, 0)

			check.is_true(stub.clock:waitFor(function()
				return connected
			end, 60))

			check.is_false(ws.handshaking)
			check.greater_eq(stub.clock:now() - started, 20)
			check.equal(ws.connectAttempts, 1)

			check.is_true(stub.clock:waitFor(function()
				return #ws.connections == 1
			end, 30))

			stub:stop()
		end)

		test.case("a handler returning false suppresses the default reply", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer(function(_, payload)
				return if payload.op == 1 then false else nil
			end)
			local received = {}
			local socket = connect(ws.url, received, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(received, 10)
			end, 30))

			sendPayload(socket, { op = 1 })
			sendPayload(socket, IDENTIFY_PAYLOAD)

			check.is_true(stub.clock:waitFor(function()
				return findEvent(received, "READY")
			end, 30))

			check.equal(#ws:receivedOps(1), 1)
			check.equal(findOp(received, 11), nil)

			stub:stop()
		end)

		test.case("a handler error lands in handlerErrors and runScenario returns it", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer(function(_, payload)
				if payload.op == 1 then
					error("the heartbeat handler failed", 0)
				end

				return
			end)
			local result = stub:runScenario(function()
				local received = {}
				local socket = connect(ws.url, received, {})

				assert(
					stub.clock:waitFor(function()
						return findOp(received, 10)
					end, 30),
					"no Hello"
				)

				sendPayload(socket, { op = 1 })

				assert(
					stub.clock:waitFor(function()
						return #ws.handlerErrors == 1
					end, 30),
					"the handler error was not recorded"
				)
			end)

			check.equal(result, "the heartbeat handler failed")
			check.equal(ws.handlerErrors[1], "the heartbeat handler failed")
			check.equal(stub.webSocketServer, nil)
		end)

		test.case("Resume replays missed dispatches after seq then RESUMED, and never READY or RESUMED", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local first = {}
			local firstSocket = connect(`{ws.url}/?v=10`, first, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(first, 10)
			end, 30))

			sendPayload(firstSocket, IDENTIFY_PAYLOAD)

			check.is_true(stub.clock:waitFor(function()
				return findEvent(first, "READY")
			end, 30))

			ws:dispatch("MESSAGE_CREATE", { content = "live" })

			check.is_true(stub.clock:waitFor(function()
				return findEvent(first, "MESSAGE_CREATE")
			end, 30))

			ws:missDispatch("MESSAGE_CREATE", { content = "missed 1" })
			ws:missDispatch("MESSAGE_CREATE", { content = "missed 2" })
			firstSocket:close(4000)

			check.is_true(stub.clock:waitFor(function()
				return not ws.connections[1].open
			end, 30))

			check.equal(#first, 3)

			local second = {}
			local secondSocket = connect(`{ws.url}/resume/?v=10`, second, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(second, 10)
			end, 30))

			sendPayload(secondSocket, { op = 6, d = { token = "stub-token", session_id = "stub-session-1", seq = 2 } })

			check.is_true(stub.clock:waitFor(function()
				return findEvent(second, "RESUMED")
			end, 30))

			check.array.equal(dispatchSummary(second), { "MESSAGE_CREATE 3", "MESSAGE_CREATE 4", "RESUMED 5" })
			check.equal(second[2].d.content, "missed 1")
			check.equal(ws.connections[2].sessionId, "stub-session-1")
			check.equal(ws.connections[2].path, "/resume")

			local third = {}
			local thirdSocket = connect(`{ws.url}/resume/?v=10`, third, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(third, 10)
			end, 30))

			sendPayload(thirdSocket, { op = 6, d = { token = "stub-token", session_id = "stub-session-1", seq = 3 } })

			check.is_true(stub.clock:waitFor(function()
				return findEvent(third, "RESUMED")
			end, 30))

			check.array.equal(dispatchSummary(third), { "MESSAGE_CREATE 4", "RESUMED 6" })
			check.array.equal(
				dispatchSummary(ws.dispatchLog),
				{ "MESSAGE_CREATE 2", "MESSAGE_CREATE 3", "MESSAGE_CREATE 4" }
			)

			stub:stop()
		end)

		test.case("Resume with an unknown session is answered with op 9 false", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local received = {}
			local socket = connect(ws.url, received, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(received, 10)
			end, 30))

			sendPayload(socket, IDENTIFY_PAYLOAD)

			check.is_true(stub.clock:waitFor(function()
				return findEvent(received, "READY")
			end, 30))

			sendPayload(socket, { op = 6, d = { token = "stub-token", session_id = "stub-session-404", seq = 1 } })

			check.is_true(stub.clock:waitFor(function()
				return findOp(received, 9)
			end, 30))

			check.equal(findOp(received, 9).d, false)
			check.equal(findEvent(received, "RESUMED"), nil)
			check.equal(ws.sessionId, "stub-session-1")

			stub:stop()
		end)

		test.case("a Resume with no seq replays every logged dispatch", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local first = {}
			local firstSocket = connect(ws.url, first, {})
			local second = {}
			local secondSocket = connect(`{ws.url}/resume/?v=10`, second, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(first, 10) and findOp(second, 10)
			end, 30))

			sendPayload(firstSocket, IDENTIFY_PAYLOAD)

			check.is_true(stub.clock:waitFor(function()
				return findEvent(first, "READY")
			end, 30))

			ws:missDispatch("MESSAGE_CREATE", { content = "missed 1" })
			ws:missDispatch("MESSAGE_CREATE", { content = "missed 2" })
			sendPayload(secondSocket, { op = 6, d = { token = "stub-token", session_id = "stub-session-1" } })

			check.is_true(stub.clock:waitFor(function()
				return findEvent(second, "RESUMED")
			end, 30))

			check.array.equal(dispatchSummary(second), { "MESSAGE_CREATE 2", "MESSAGE_CREATE 3", "RESUMED 4" })

			stub:stop()
		end)

		test.case(
			"a second Identify starts stub-session-2 with an empty dispatchLog and session 1 no longer resumes",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local ws = stub:createWebsocketServer()
				local first = {}
				local firstSocket = connect(ws.url, first, {})
				local second = {}
				local secondSocket = connect(ws.url, second, {})

				check.is_true(stub.clock:waitFor(function()
					return findOp(first, 10) and findOp(second, 10)
				end, 30))

				sendPayload(firstSocket, IDENTIFY_PAYLOAD)

				check.is_true(stub.clock:waitFor(function()
					return findEvent(first, "READY")
				end, 30))

				ws:missDispatch("MESSAGE_CREATE", { content = "session 1" })
				sendPayload(secondSocket, IDENTIFY_PAYLOAD)

				check.is_true(stub.clock:waitFor(function()
					return findEvent(second, "READY")
				end, 30))

				check.equal(findEvent(second, "READY").d.session_id, "stub-session-2")
				check.equal(findEvent(second, "READY").s, 3)
				check.equal(ws.sessionId, "stub-session-2")
				check.equal(ws.identifyCount, 2)
				check.equal(#ws.dispatchLog, 0)

				sendPayload(
					secondSocket,
					{ op = 6, d = { token = "stub-token", session_id = "stub-session-1", seq = 1 } }
				)

				check.is_true(stub.clock:waitFor(function()
					return findOp(second, 9)
				end, 30))

				check.equal(findOp(second, 9).d, false)
				check.equal(findEvent(second, "RESUMED"), nil)

				stub:stop()
			end
		)

		test.case(
			"dispatch reaches open connections bound to the session and skips one that never identified",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local ws = stub:createWebsocketServer()
				local bound = {}
				local boundSocket = connect(ws.url, bound, {})
				local unbound = {}

				connect(ws.url, unbound, {})

				check.is_true(stub.clock:waitFor(function()
					return findOp(bound, 10) and findOp(unbound, 10)
				end, 30))

				sendPayload(boundSocket, IDENTIFY_PAYLOAD)

				check.is_true(stub.clock:waitFor(function()
					return findEvent(bound, "READY")
				end, 30))

				ws:dispatch("MESSAGE_CREATE", { content = "bound only" })
				ws:send({ op = 0, t = "MARKER" })

				check.is_true(stub.clock:waitFor(function()
					return findEvent(bound, "MARKER") and findEvent(unbound, "MARKER")
				end, 30))

				check.equal(findEvent(bound, "MESSAGE_CREATE").d.content, "bound only")
				check.equal(findEvent(unbound, "MESSAGE_CREATE"), nil)

				stub:stop()
			end
		)

		test.case("received records carry clock times and receivedOps merges connections in time order", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local first = {}
			local firstSocket = connect(ws.url, first, {})
			local second = {}
			local secondSocket = connect(ws.url, second, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(first, 10) and findOp(second, 10)
			end, 30))

			local sentAt = stub.clock:now()

			sendPayload(secondSocket, { op = 1, d = 2 })

			check.is_true(stub.clock:waitFor(function()
				return #ws.connections[2]:receivedOps(1) == 1
			end, 30))

			sendPayload(firstSocket, { op = 1, d = 1 })

			check.is_true(stub.clock:waitFor(function()
				return #ws:receivedOps(1) == 2
			end, 30))

			local record = ws.connections[2].received[1]
			local heartbeats = ws:receivedOps(1)

			check.equal(record.payload.d, 2)
			check.greater_eq(record.at, sentAt)
			check.lesser_eq(record.at, stub.clock:now())
			check.equal(heartbeats[1], record)
			check.equal(heartbeats[2].payload.d, 1)

			stub:stop()
		end)

		test.case("a resume dial records path /resume and a fresh dial records /", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()

			connect(`{ws.url}/?v=10`, {}, {})
			connect(`{ws.url}/resume/?v=10`, {}, {})

			check.is_true(stub.clock:waitFor(function()
				return #ws.connections == 2
			end, 30))

			check.equal(ws.connections[1].index, 1)
			check.equal(ws.connections[1].path, "/")
			check.equal(ws.connections[2].index, 2)
			check.equal(ws.connections[2].path, "/resume")
			check.equal(ws:latestConnection(), ws.connections[2])
			check.equal(ws:openConnections(), 2)

			stub:stop()
		end)
	end)
end
