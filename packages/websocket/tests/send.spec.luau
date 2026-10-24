local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")

local websocket = require("../src")

local SOCKET_VERSION = 10
local DROPPED_MARKER = '{"op":99,"d":"dropped"}'
local KEPT_MARKER = '{"op":99,"d":"kept"}'

local test = frktest.test
local check = frktest.assert.check

local function received(server: any, text: string): number
	local count = 0

	for _, connection in server.connections do
		for _, record in connection.received do
			if record.raw == text then
				count += 1
			end
		end
	end

	return count
end

return function()
	test.suite("Shard sends", function()
		test.case("a send its caller stopped wanting is dropped, and a wanted one goes out", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = websocket.shard.new({
				token = secret.new("stub-token"),
				intents = 0,
				shardId = 0,
				shardCount = 1,
				shouldReconnect = false,
				logLevel = "Warn",
			})

			local function scenario()
				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					return shard.sessionId
				end, 30))

				local dropped = shard
					:sendAsync(DROPPED_MARKER, false, function()
						return false
					end)
					:await()
				local kept = shard
					:sendAsync(KEPT_MARKER, false, function()
						return true
					end)
					:await()

				check.is_true(dropped:isOk())
				check.is_true(kept:isOk())
				check.is_true(stub.clock:waitFor(function()
					return received(server, KEPT_MARKER) == 1
				end, 30))
				check.equal(received(server, DROPPED_MARKER), 0)
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
