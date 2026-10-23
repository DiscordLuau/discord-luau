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

return function()
	test.suite("Shard first heartbeat", function()
		test.case("15. the first heartbeat waits heartbeat_interval times the jitter", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(false)
			local jitter = 0.5

			shard.heartbeatJitter = function()
				return jitter
			end

			local function scenario()
				local helloAt = stub.clock:now()

				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					local connection = server.connections[1]

					return connection and #connection:receivedOps(opcodes.Heartbeat) >= 1
				end, 60))

				local connection = assert(server.connections[1], "the server saw no connection")
				local heartbeat = assert(connection:receivedOps(opcodes.Heartbeat)[1], "no heartbeat arrived")
				local expectedSeconds = server.heartbeatIntervalMilliseconds / 1000 * jitter

				check.greater_eq(heartbeat.at - helloAt, expectedSeconds - 0.5)
				check.lesser_eq(heartbeat.at - helloAt, expectedSeconds + 2)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("16. a fresh connect identifies on Hello, before the first heartbeat", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(false)

			shard.heartbeatJitter = function()
				return 0.9
			end

			local function scenario()
				local helloAt = stub.clock:now()

				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					return #server:receivedOps(opcodes.Identify) >= 1
				end, 5))

				local identify = assert(server:receivedOps(opcodes.Identify)[1], "no identify arrived")

				check.lesser_eq(identify.at - helloAt, 1)
				check.equal(#server:receivedOps(opcodes.Heartbeat), 0)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("17. a reconnect with a session resumes on Hello, before the first heartbeat", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)

			shard.heartbeatJitter = function()
				return 0.9
			end

			local function scenario()
				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					return shard.sessionId
				end, 5))

				local firstConnection = assert(server.connections[1], "the server saw no connection")

				firstConnection:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(function()
					return server.connections[2]
				end, 60))

				local openedAt = stub.clock:now()

				check.is_true(stub.clock:waitFor(function()
					local resumeConnection = server.connections[2]

					return resumeConnection and #resumeConnection:receivedOps(opcodes.Resume) >= 1
				end, 5))

				local resumeConnection = assert(server.connections[2], "the server saw no second connection")
				local resume = assert(resumeConnection:receivedOps(opcodes.Resume)[1], "no resume arrived")

				check.lesser_eq(resume.at - openedAt, 1)
				check.equal(#resumeConnection:receivedOps(opcodes.Heartbeat), 0)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("18. forceClose during the first-heartbeat wait cancels it", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(false)

			shard.heartbeatJitter = function()
				return 0.9
			end

			local function scenario()
				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					return #server:receivedOps(opcodes.Identify) >= 1
				end, 5))

				local waitingThread = assert(shard.heartbeatThread, "no first-heartbeat thread is waiting")

				check.equal(coroutine.status(waitingThread), "suspended")

				shard:forceClose()

				check.equal(coroutine.status(waitingThread), "dead")
				check.equal(shard.heartbeatThread, nil)

				stub.clock:wait(server.heartbeatIntervalMilliseconds / 1000 * 2)

				check.equal(#server:receivedOps(opcodes.Heartbeat), 0)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("19. a fatal close during the first-heartbeat wait cancels it", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local shard = newShard(true)
			local waitingThread: thread? = nil
			local server = stub:createWebsocketServer(function(connection, payload)
				if payload.op ~= opcodes.Identify then
					return
				end

				waitingThread = shard.heartbeatThread

				connection:close(closeCodes.AuthenticationFailed)

				return false
			end)

			shard.heartbeatJitter = function()
				return 0.9
			end

			local function scenario()
				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					return shard.stayDisconnected
				end, 5))

				local thread = assert(waitingThread, "no first-heartbeat thread was waiting at the close")

				check.equal(coroutine.status(thread), "dead")
				check.equal(shard.heartbeatThread, nil)

				stub.clock:wait(server.heartbeatIntervalMilliseconds / 1000 * 2)

				check.equal(#server:receivedOps(opcodes.Heartbeat), 0)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("20. an ACK before the first heartbeat of a reconnected socket reports no stale ping", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)
			local beats = discordStub.recordEmits(shard.onSocketHeartbeat)
			local jitter = 0

			shard.heartbeatJitter = function()
				return jitter
			end

			local function scenario()
				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					return #beats >= 1
				end, 5))

				local beatsBefore = #beats

				jitter = 0.9

				assert(server.connections[1], "the server saw no connection"):send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(function()
					local connection = server.connections[2]

					return connection and #connection:receivedOps(opcodes.Resume) >= 1
				end, 60))

				local connection = assert(server.connections[2], "the server saw no second connection")

				connection:send({ op = opcodes.HeartbeatACK })

				check.is_true(stub.clock:waitFor(function()
					return shard.heartbeatAcknowledged
				end, 30))

				check.equal(#connection:receivedOps(opcodes.Heartbeat), 0)
				check.equal(#beats, beatsBefore)
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
