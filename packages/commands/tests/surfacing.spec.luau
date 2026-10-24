local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")
local discordStub = require("../../discord_stub/src")
local discordLuau = require("../../discord_luau/src")

local commands = require("../src")

local OVERWRITE_PATH = "/api/v10/applications/2/commands"
local CALLBACK_PATTERN = "^/api/v10/interactions/[^/]+/[^/]+/callback"
local REJECTION_BODY = '{"message":"Invalid Form Body","code":50035}'

local test = frktest.test
local check = frktest.assert.check

local function rejection(): any
	return {
		status_code = 400,
		headers = { ["content-type"] = "application/json" },
		body = REJECTION_BODY,
	}
end

local function runWithCommands(
	rejectCallbacks: boolean,
	body: (commands.Commands, discordStub.DiscordStub, { string }) -> ()
)
	local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
	stub:createWebsocketServer()
	local warnings: { string } = {}
	local bot: discordLuau.Bot? = nil

	stub:createHttpServer(function(request)
		if request.method == "PUT" and request.path == OVERWRITE_PATH then
			return rejection()
		end

		if rejectCallbacks and request.method == "POST" and string.match(request.path, CALLBACK_PATTERN) then
			return rejection()
		end

		return
	end)

	local function scenario()
		local newBot = discordLuau.bot.new({ token = "stub-token", intents = 0, isUsingStub = stub })

		bot = newBot
		newBot:connectAsync():await()

		assert(
			stub.clock:waitFor(function()
				return if newBot.application then true else false
			end, 300),
			"the bot never became ready"
		)

		local instance = commands.new(newBot, { watch = false, help = false })

		instance.logger:setSink(function(message)
			table.insert(warnings, message)
		end)

		body(instance, stub, warnings)
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
end

local function dispatchInteraction(stub: discordStub.DiscordStub, data: any)
	local server = assert(stub.webSocketServer, "the stub has no websocket server")

	server:dispatch("INTERACTION_CREATE", data)
end

local function dispatchCommand(stub: discordStub.DiscordStub, name: string, interactionId: string)
	dispatchInteraction(stub, {
		id = interactionId,
		application_id = "2",
		type = 2,
		token = `token-{interactionId}`,
		version = 1,
		data = { id = "3", name = name, type = 1 },
		user = { id = "5", username = "tester", discriminator = "0", global_name = "tester" },
	})
end

local function waitForWarning(stub: discordStub.DiscordStub, warnings: { string }, needle: string): boolean
	return stub.clock:waitFor(function()
		for _, line in warnings do
			if string.find(line, needle, 1, true) then
				return true
			end
		end

		return false
	end, 60)
end

local function definition(name: string, extra: { [string]: any }): any
	local entry = {
		command = { name = name, description = "test", type = 1 },
		execute = function() end,
	}

	for key, value in extra do
		entry[key] = value
	end

	return entry
end

return function()
	test.suite("commands error surfacing", function()
		test.case("registerAsync returns an Err when Discord rejects the overwrite", function()
			runWithCommands(false, function(instance)
				instance.registry:set(definition("ping", {}))

				local result = instance:registerAsync():await()

				check.is_true(result:isErr())
			end)
		end)

		test.case("unregisterAsync returns an Err when Discord rejects the overwrite", function()
			runWithCommands(false, function(instance)
				local result = instance:unregisterAsync():await()

				check.is_true(result:isErr())
			end)
		end)

		test.case("a failed error reply is logged", function()
			runWithCommands(true, function(instance, stub, warnings)
				instance.registry:set(definition("boom", {
					execute = function()
						error("command failure")
					end,
				}))
				dispatchCommand(stub, "boom", "100")

				check.is_true(waitForWarning(stub, warnings, "error reply"))
			end)
		end)

		test.case("a failed guard denial reply is logged", function()
			runWithCommands(true, function(instance, stub, warnings)
				instance.registry:set(definition("guarded", {
					guards = {
						function()
							return false
						end,
					},
				}))
				dispatchCommand(stub, "guarded", "101")

				check.is_true(waitForWarning(stub, warnings, "guard denial reply"))
			end)
		end)

		test.case("a failed cooldown reply is logged", function()
			runWithCommands(true, function(instance, stub, warnings)
				instance.registry:set(definition("slow", { cooldown = { { seconds = 60, per = "user" } } }))
				dispatchCommand(stub, "slow", "102")
				dispatchCommand(stub, "slow", "103")

				check.is_true(waitForWarning(stub, warnings, "cooldown reply"))
			end)
		end)

		test.case("a failed concurrency reply is logged", function()
			runWithCommands(true, function(instance, stub, warnings)
				instance.registry:set(definition("busy", {
					maxConcurrency = { limit = 1, per = "user" },
					execute = function()
						stdPolyfills.task.wait(30)
					end,
				}))
				dispatchCommand(stub, "busy", "104")
				dispatchCommand(stub, "busy", "105")

				check.is_true(waitForWarning(stub, warnings, "concurrency reply"))
			end)
		end)

		test.case("a failed ping acknowledgement is logged", function()
			runWithCommands(true, function(_, stub, warnings)
				dispatchInteraction(stub, {
					id = "106",
					application_id = "2",
					type = 1,
					token = "token-106",
					version = 1,
				})

				check.is_true(waitForWarning(stub, warnings, "ping acknowledgement"))
			end)
		end)

		test.case("a failed help reply is logged", function()
			runWithCommands(true, function(instance, stub, warnings)
				instance.registry:set(require("../src/defaults/help")(instance.registry))
				dispatchCommand(stub, "help", "107")

				check.is_true(waitForWarning(stub, warnings, "failed to send the help reply"))
			end)
		end)
	end)
end
