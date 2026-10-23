local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local apiTypes = require("../luau_packages/api_types")

local websocket = require("../src")

local SOCKET_VERSION = 10
local SESSION_OUTCOME_TIMEOUT_SECONDS = 30

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

local function reconnected(shard: websocket.Shard, reconnects: { { any } }, count: number): () -> boolean
	return function()
		return #reconnects >= count and not shard.socketReconnecting and shard.socketActive
	end
end

return function()
	test.suite("Shard reconnect", function()
		test.case("1. recovers after 120 failed connects (2026-06-23)", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.refuseUpgrades = 120
				server.connections[1]:close(closeCodes.UnknownError)

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 5000))
				check.equal(#reconnects, 1)
				check.equal(server.refuseUpgrades, 0)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("2. identifies on a fresh socket when the resume is refused with op 9 (2026-07-13)", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local refusedIndex = 2
			local refused = false
			local server = stub:createWebsocketServer(function(connection, payload)
				if refused or connection.index ~= refusedIndex or not isAuthPayload(payload) then
					return
				end

				refused = true

				return { op = opcodes.InvalidSession, d = false }
			end)
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 600))

				local latestConnection = assert(server:latestConnection(), "the server saw no connection")

				check.is_true(refused)
				check.greater(latestConnection.index, refusedIndex)
				check.equal(#latestConnection:receivedOps(opcodes.Identify), 1)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("4a. retries when the new socket closes right after its Resume", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local closingIndex = 2
			local server = stub:createWebsocketServer(function(connection, payload)
				if connection.index ~= closingIndex or payload.op ~= opcodes.Resume then
					return
				end

				connection:close(closeCodes.UnknownError)

				return false
			end)
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 300))

				local latestConnection = assert(server:latestConnection(), "the server saw no connection")

				check.greater(latestConnection.index, closingIndex)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("4c. retries when the new socket closes in the same tick as its Hello", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local closingIndex = 2
			local server = stub:createWebsocketServer()
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)
			local open = server.open

			server.open = function(self, socket)
				open(self, socket)

				local connection = self.connections[closingIndex]

				if connection and connection.open and #self.connections == closingIndex then
					connection:close(closeCodes.UnknownError)
				end
			end

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 300))

				local latestConnection = assert(server:latestConnection(), "the server saw no connection")

				check.greater(latestConnection.index, closingIndex)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("4b. retries when the new socket closes in the same tick as RESUMED", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local closingIndex = 2
			local closedAfterResumed = false
			local server = stub:createWebsocketServer(function(connection, payload)
				if closedAfterResumed or connection.index ~= closingIndex or not isAuthPayload(payload) then
					return
				end

				closedAfterResumed = true

				-- the leading ACK holds RESUMED and the close behind Nagle, so they reach the shard together
				connection:send({ op = opcodes.HeartbeatACK })
				connection:send({ op = opcodes.Dispatch, t = "RESUMED", s = (payload.d.seq or 0) + 1, d = {} })
				connection:close(closeCodes.UnknownError)

				return false
			end)
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(function()
					local latestConnection = server:latestConnection()

					return latestConnection
						and latestConnection.index > closingIndex
						and #reconnects >= 1
						and shard.socketActive
						and not shard.socketReconnecting
				end, 300))
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("8. op 7 and a server close in the same tick run one reconnect", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				local firstConnection = server.connections[1]

				firstConnection:send({ op = opcodes.Reconnect })
				firstConnection:close(closeCodes.UnknownError)

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 120))

				stub.clock:wait(60)

				check.equal(#reconnects, 1)
				check.equal(server:openConnections(), 1)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("13. a resume the server never answers times out, then the next pass resumes", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local timedOutIndex = 2
			local ignored = false
			local server = stub:createWebsocketServer(function(connection, payload)
				if ignored or connection.index ~= timedOutIndex or payload.op ~= opcodes.Resume then
					return
				end

				ignored = true

				return false
			end)
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)
			local disconnects = discordStub.recordEmits(shard.onSocketDisconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				local sessionId = shard.sessionId

				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 120))

				local timedOutResumes = server.connections[timedOutIndex]:receivedOps(opcodes.Resume)
				local resumes = server:receivedOps(opcodes.Resume)

				check.is_true(ignored)
				check.equal(#timedOutResumes, 1)
				check.equal(#server.connections, timedOutIndex + 1)
				check.equal(#resumes, 2)
				check.greater_eq(resumes[2].at - resumes[1].at, SESSION_OUTCOME_TIMEOUT_SECONDS)
				check.equal(shard.sessionId, sessionId)
				check.equal(#disconnects, 0)
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
