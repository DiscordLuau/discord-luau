local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")
local discordStub = require("../luau_packages/discord_stub")

local discordLuau = require("../src/init")

local test = frktest.test
local check = frktest.assert.check
local requireCheck = frktest.assert.require

return function()
	test.suite("discord_stub end to end", function()
		test.case("a bot connects, identifies and receives READY through the stub", function()
			local stub = discordStub.new()
			local server = stub:createWebsocketServer()
			local httpServer = stub:createHttpServer()
			local bot: discordLuau.Bot? = nil

			local function scenario()
				local newBot = discordLuau.bot.new({
					token = "stub-token",
					intents = 0,
					isUsingStub = stub,
				})
				local readyCount = 0

				bot = newBot

				check.equal(stub.restUrl, `{httpServer.url}/api/v10`)

				requireCheck.equal(newBot.state.stub, stub)

				newBot.onReady:listen(function()
					readyCount += 1
				end)

				newBot:connectAsync():await()

				check.is_true(stub.clock:waitFor(function()
					return readyCount > 0 and newBot.user and newBot.application
				end, 5))

				local user = newBot.user
				local application = newBot.application

				assert(user, "the bot did not receive its user")
				assert(application, "the bot did not receive its application")

				check.equal(user.id, "1")
				check.equal(application.id, "2")
				check.equal(server:openConnections(), 1)
			end

			check.equal(
				stub:runScenario(scenario, function()
					if not bot then
						return
					end

					local shards = bot.state.webSocketManager.shards

					-- indexed: the old solver rejects forceClose's self on a shard taken by generalised iteration over this table
					for shardId in shards do
						shards[shardId]:forceClose()
					end
				end),
				nil
			)
			check.equal(httpServer.server, nil)
			check.equal(server.server, nil)
		end)

		test.case("a stub without an HTTP server is rejected", function()
			local stub = discordStub.new()
			local message = "isUsingStub requires a stub with an HTTP server - call stub:createHttpServer() first"

			local function scenario()
				local succeeded, failure = pcall(function()
					discordLuau.bot.new({ token = "stub-token", intents = 0, isUsingStub = stub })
				end)

				check.equal(succeeded, false)
				check.equal(string.sub(failure, -#message), message)
			end

			check.equal(stub:runScenario(scenario), nil)
		end)

		test.case("virtual clock swaps the consumer's polyfills", function()
			local originalTask = stdPolyfills.task
			local originalDatetime = stdPolyfills.datetime
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })

			check.is_true(stdPolyfills.task ~= originalTask)
			check.is_true(stdPolyfills.datetime ~= originalDatetime)

			stub:stop()

			check.equal(stdPolyfills.task, originalTask)
			check.equal(stdPolyfills.datetime, originalDatetime)
		end)
	end)
end
