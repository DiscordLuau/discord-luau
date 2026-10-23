local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")
local discordStub = require("../luau_packages/discord_stub")

local discordLuau = require("../src/init")

local RESOLVE_TIMEOUT_SECONDS = 10
local REFUSED_UPGRADES = 1000

local test = frktest.test
local check = frktest.assert.check

local function connectAndWait(stub: discordStub.DiscordStub, bot: discordLuau.Bot): (boolean, boolean)
	local resolved = false
	local failed = false

	stdPolyfills.task.spawn(function()
		failed = bot:connectAsync():await():isErr()
		resolved = true
	end)

	stub.clock:waitFor(function()
		return resolved
	end, RESOLVE_TIMEOUT_SECONDS)

	return resolved, failed
end

return function()
	test.suite("Bot connect failures", function()
		test.case("connectAsync resolves Err when the gateway information request fails", function()
			local stub = discordStub.new()

			stub:createWebsocketServer()
			stub:createHttpServer(function(request)
				if request.path == "/api/v10/gateway/bot" then
					return {
						status_code = 401,
						headers = { ["content-type"] = "application/json" },
						body = '{"message":"401: Unauthorized","code":0}',
					}
				end

				return
			end)

			local function scenario()
				local bot = discordLuau.bot.new({ token = "stub-token", intents = 0, isUsingStub = stub })
				local resolved, failed = connectAndWait(stub, bot)

				check.is_true(resolved)
				check.is_true(failed)
			end

			check.equal(stub:runScenario(scenario), nil)
		end)

		test.case("connectAsync resolves instead of hanging when every shard fails to connect", function()
			local stub = discordStub.new()
			local server = stub:createWebsocketServer()
			local bot: discordLuau.Bot? = nil

			stub:createHttpServer()

			server.refuseUpgrades = REFUSED_UPGRADES

			local function scenario()
				local newBot = discordLuau.bot.new({ token = "stub-token", intents = 0, isUsingStub = stub })
				local resolved = connectAndWait(stub, newBot)

				bot = newBot

				check.is_true(resolved)
			end

			check.equal(
				stub:runScenario(scenario, function()
					if not bot then
						return
					end

					local shards = bot.state.webSocketManager.shards

					for shardId in shards do
						shards[shardId]:forceClose()
					end
				end),
				nil
			)
		end)
	end)
end
