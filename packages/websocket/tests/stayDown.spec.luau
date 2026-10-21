local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local apiTypes = require("../luau_packages/api_types")

local websocket = require("../src")

local SOCKET_VERSION = 10

local test = frktest.test
local check = frktest.assert.check
local opcodes = apiTypes.gateway.opcodes
local closeCodes = apiTypes.gateway.closeCodes

local function newShard(shouldReconnect: boolean): websocket.Shard
	return websocket.shard.new({
		token = secret.new("stub-token"),
		intents = 0,
		shardId = 0,
		shardCount = 1,
		shouldReconnect = shouldReconnect,
		logLevel = "Warn",
	})
end

local function connectFresh(stub: discordStub.DiscordStub, shard: websocket.Shard, url: string): boolean
	shard:connectAsync(url, SOCKET_VERSION):await()

	return stub.clock:waitFor(function()
		return shard.sessionId
	end, 30)
end

local function isAuthPayload(payload: { op: number }): boolean
	return payload.op == opcodes.Identify or payload.op == opcodes.Resume
end

local function hasServerDisconnect(disconnects: { { any } }, code: number): boolean
	for _, emit in disconnects do
		if emit[1] == code and not emit[2] then
			return true
		end
	end

	return false
end

return function()
	test.suite("Shard staying down", function()
		test.case("5. stays down on a fatal close code during a reconnect", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local fatalIndex = 2
			local server = stub:createWebsocketServer(function(connection, payload)
				if connection.index ~= fatalIndex or not isAuthPayload(payload) then
					return
				end

				connection:close(closeCodes.DisallowedIntents)

				return false
			end)
			local shard = newShard(true)
			local disconnects = discordStub.recordEmits(shard.onSocketDisconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(function()
					return hasServerDisconnect(disconnects, closeCodes.DisallowedIntents)
				end, 120))

				local connectionCount = #server.connections
				local identifyCount = #server:receivedOps(opcodes.Identify)

				stub.clock:wait(5 * server.heartbeatIntervalMilliseconds / 1000)

				check.equal(#server.connections, connectionCount)
				check.equal(#server:receivedOps(opcodes.Identify), identifyCount)
				check.is_false(shard.socketReconnecting)
				check.is_true(shard.stayDisconnected)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("6. with reconnect off, op 7 closes and stays down until reconnectAsync", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(false)
			local disconnects = discordStub.recordEmits(shard.onSocketDisconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				local connectionCount = #server.connections

				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(function()
					return hasServerDisconnect(disconnects, -1)
				end, 30))

				stub.clock:wait(60)

				check.is_false(shard.socketActive)
				check.equal(#server.connections, connectionCount)

				shard:reconnectAsync():poll()

				check.is_true(stub.clock:waitFor(function()
					return shard.socketActive and shard.sessionId
				end, 300))

				local latestConnection = assert(server:latestConnection(), "the server saw no connection")

				check.equal(#latestConnection:receivedOps(opcodes.Identify), 1)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("7a. forceClose during a backoff wait stops the loop at once", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.refuseUpgrades = 1000
				server.connections[1]:close(closeCodes.UnknownError)

				check.is_true(stub.clock:waitFor(function()
					return server.connectAttempts >= 4
				end, 120))

				shard:forceClose()

				check.is_true(stub.clock:waitFor(function()
					return not shard.socketReconnecting
				end, 1))

				local connectAttempts = server.connectAttempts

				stub.clock:wait(120)

				check.equal(server.connectAttempts, connectAttempts)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("7b. forceClose during a slow handshake leaves no socket and sends no heartbeat", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.upgradeDelaySeconds = 20
				server.connections[1]:close(closeCodes.UnknownError)

				check.is_true(stub.clock:waitFor(function()
					return server.handshaking
				end, 30))

				shard:forceClose()

				check.is_true(stub.clock:waitFor(function()
					return not server.handshaking
				end, 40))

				stub.clock:wait(60)

				local handshakeConnection = assert(server:latestConnection(), "the server saw no connection")

				check.is_false(shard.socketActive)
				check.is_false(shard.socketReconnecting)
				check.equal(server:openConnections(), 0)
				check.equal(#handshakeConnection:receivedOps(opcodes.Heartbeat), 0)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		for _, shouldReconnect in { true, false } do
			test.case(
				`11. a developer connectAsync from a disconnect listener wins (reconnect {shouldReconnect})`,
				function()
					local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
					local server = stub:createWebsocketServer()
					local shard = newShard(shouldReconnect)
					local developerConnected = false

					shard.onSocketDisconnected:listen(function(code, closedBySelf)
						if developerConnected or closedBySelf or code ~= closeCodes.UnknownError then
							return
						end

						developerConnected = true
						shard:connectAsync(server.url, SOCKET_VERSION):poll()
					end)

					local function scenario()
						check.is_true(connectFresh(stub, shard, server.url))

						server.connections[1]:close(closeCodes.UnknownError)
						stub.clock:wait(300)

						local developerConnection = assert(server:latestConnection(), "the server saw no connection")

						check.is_true(developerConnected)
						check.equal(server:openConnections(), 1)
						check.equal(developerConnection.index, 2)
						check.equal(developerConnection.path, "/")
						check.is_false(shard.stayDisconnected)
						check.is_false(shard.socketReconnecting)
						check.greater_eq(#developerConnection:receivedOps(opcodes.Heartbeat), 3)
					end

					check.equal(
						stub:runScenario(scenario, function()
							shard:forceClose()
						end),
						nil
					)
				end
			)
		end

		test.case("14. a zombie heartbeat with reconnect off stays down", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local droppingHeartbeats = false
			local server = stub:createWebsocketServer(function(_, payload)
				if droppingHeartbeats and payload.op == opcodes.Heartbeat then
					return false
				end

				return
			end)
			local shard = newShard(false)
			local disconnects = discordStub.recordEmits(shard.onSocketDisconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				droppingHeartbeats = true

				check.is_true(stub.clock:waitFor(function()
					return hasServerDisconnect(disconnects, -1)
				end, 120))

				local connectionCount = #server.connections

				stub.clock:wait(120)

				check.is_true(shard.stayDisconnected)
				check.falsy(shard.sessionId)
				check.is_false(shard.socketActive)
				check.is_false(shard.socketReconnecting)
				check.equal(#disconnects, 1)
				check.equal(#server.connections, connectionCount)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("15. a fatal close outside a reconnect stays down", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)
			local disconnects = discordStub.recordEmits(shard.onSocketDisconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.connections[1]:close(closeCodes.AuthenticationFailed)

				check.is_true(stub.clock:waitFor(function()
					return hasServerDisconnect(disconnects, closeCodes.AuthenticationFailed)
				end, 30))

				local connectionCount = #server.connections
				local identifyCount = #server:receivedOps(opcodes.Identify)

				stub.clock:wait(120)

				check.is_true(shard.stayDisconnected)
				check.falsy(shard.sessionId)
				check.is_false(shard.socketActive)
				check.is_false(shard.socketReconnecting)
				check.equal(#disconnects, 1)
				check.equal(#server.connections, connectionCount)
				check.equal(#server:receivedOps(opcodes.Identify), identifyCount)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)
	end)
end
