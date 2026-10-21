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

local function reconnected(shard: websocket.Shard, reconnects: { { any } }, count: number): () -> boolean
	return function()
		return #reconnects >= count and not shard.socketReconnecting and shard.socketActive
	end
end

return function()
	test.suite("Shard identify pacing", function()
		test.case("9. paces IDENTIFY 90 seconds apart, and not once 90 seconds have passed", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local refusals = 0
			local server = stub:createWebsocketServer(function(connection, payload)
				if refusals >= 3 or connection.index == 1 or payload.op ~= opcodes.Identify then
					return
				end

				refusals += 1

				return { op = opcodes.InvalidSession, d = false }
			end)
			local shard = newShard(true)
			local reconnects = discordStub.recordEmits(shard.onSocketReconnected)

			local function scenario()
				check.is_true(connectFresh(stub, shard, server.url))

				server.connections[1]:send({ op = opcodes.InvalidSession, d = false })

				check.is_true(stub.clock:waitFor(reconnected(shard, reconnects, 1), 900))

				local identifies = server:receivedOps(opcodes.Identify)

				check.equal(#identifies, 5)

				for index = 2, #identifies do
					check.greater_eq(identifies[index].at - identifies[index - 1].at, 89)
				end

				stub.clock:wait(100)

				local latestConnection = assert(server:latestConnection(), "the server saw no connection")

				latestConnection:close(closeCodes.SessionTimedOut)

				check.is_true(stub.clock:waitFor(function()
					return #server:receivedOps(opcodes.Identify) == 6
				end, 10))
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
