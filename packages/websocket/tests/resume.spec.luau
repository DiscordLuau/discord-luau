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

local function reconnected(shard: websocket.Shard, reconnects: { { any } }, count: number): () -> boolean
	return function()
		return #reconnects >= count and not shard.socketReconnecting and shard.socketActive
	end
end

local function hasDispatchedContent(dispatches: { { any } }, content: string): boolean
	for _, emit in dispatches do
		if emit[1].d.content == content then
			return true
		end
	end

	return false
end

return function()
	test.suite("Shard resume", function()
		test.case("3. resumes with op 6 on the resume url and replays missed events", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)
			local dispatches = discordStub.recordEmits(shard.onSocketDispatch)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server:dispatch("MESSAGE_CREATE", { content = "live" })
				server:dispatch("MESSAGE_CREATE", { content = "live" })

				check.is_true(stub.clock:waitFor(function()
					return shard.lastSequence == server.sequence
				end, 30))

				local sessionId = shard.sessionId
				local lastSequence = server.sequence

				server:missDispatch("MESSAGE_CREATE", { content = "replayed" })
				server.connections[1]:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 120))

				local resumeConnection = assert(server.connections[2], "the server saw no second connection")
				local resumes = resumeConnection:receivedOps(opcodes.Resume)
				local resumeData = assert(resumes[1] and resumes[1].payload.d, "the shard sent no Resume")

				check.equal(#resumeConnection:receivedOps(opcodes.Identify), 0)
				check.equal(#resumes, 1)
				check.equal(resumeConnection.path, "/resume")
				check.equal(resumeData.seq, lastSequence)
				check.equal(resumeData.session_id, sessionId)
				check.is_true(hasDispatchedContent(dispatches, "replayed"))
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("10. a late close from the old socket does not touch the new one", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local droppingHeartbeats = false
			local server = stub:createWebsocketServer(function(connection, payload)
				if droppingHeartbeats and connection.index == 1 and payload.op == opcodes.Heartbeat then
					return false
				end

				return
			end)
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				droppingHeartbeats = true

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 300))

				stub.clock:wait(120)

				local latestConnection = assert(server:latestConnection(), "the server saw no connection")

				check.is_true(shard.socketActive)
				check.equal(server:openConnections(), 1)
				check.equal(latestConnection.index, 2)
				check.equal(#reconnects, 1)
				check.equal(#server.connections, 2)
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
