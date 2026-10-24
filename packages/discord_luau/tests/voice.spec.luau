local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")
local discordStub = require("../luau_packages/discord_stub")

local discordLuau = require("../src/init")

local GUILD_ID = "10"
local CHANNEL_ID = "20"
local OTHER_CHANNEL_ID = "21"
local STUB_USER_ID = "1"
local GUILD_VOICE_STATES_INTENT = 128
local LEAVE_TEXT = '{"op":4,"d":{"guild_id":"10","channel_id":null,"self_mute":false,"self_deaf":false}}'

local test = frktest.test
local check = frktest.assert.check

if stdPolyfills.runtime.getRuntime() ~= "Zune" then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Bot voice", function() end)
	end
end

local function serveVoiceChannels(request: any): any
	local channelId = string.match(request.path, "^/api/v10/channels/(%d+)$")

	if request.method ~= "GET" or not channelId then
		return
	end

	return {
		status_code = 200,
		headers = { ["content-type"] = "application/json" },
		body = stdPolyfills.serde.encode("json", {
			id = channelId,
			type = 2,
			guild_id = GUILD_ID,
			name = `voice {channelId}`,
			position = 0,
			permission_overwrites = {},
			bitrate = 64000,
			user_limit = 0,
			nsfw = false,
			flags = 0,
			rate_limit_per_user = 0,
		}),
	}
end

local function newWorld(): (discordStub.DiscordStub, any, discordStub.VoiceServer)
	local stub = discordStub.new()
	local gateway = stub:createWebsocketServer()
	local voiceServer = stub:createVoiceServer()

	stub:createHttpServer(serveVoiceChannels)

	return stub, gateway, voiceServer
end

local function newBot(stub: discordStub.DiscordStub, intents: number): discordLuau.Bot
	return discordLuau.bot.new({ token = "stub-token", intents = intents, isUsingStub = stub })
end

local function startBot(stub: discordStub.DiscordStub, world: World, intents: number?): discordLuau.Bot
	local bot = newBot(stub, intents or GUILD_VOICE_STATES_INTENT)

	world.bot = bot
	bot:connectAsync():await()

	assert(
		stub.clock:waitFor(function()
			return bot.state.userId == STUB_USER_ID
		end, 10),
		"the bot never learned its user id"
	)

	return bot
end

local function voiceChannel(bot: discordLuau.Bot, channelId: string): any
	return bot:getVoiceChannelAsync(channelId):await():unwrapOk()
end

local function identifyUserId(voiceServer: discordStub.VoiceServer): string?
	for _, record in voiceServer.received do
		if record.opcode == 0 then
			return (record.payload.d :: any).user_id
		end
	end

	return
end

local function openVoiceSockets(voiceServer: discordStub.VoiceServer): number
	local count = 0

	for _, connection in voiceServer.connections do
		if connection.open then
			count += 1
		end
	end

	return count
end

local function stopBot(bot: discordLuau.Bot?)
	if not bot then
		return
	end

	for _, connection in bot.state.voiceConnections do
		connection:destroy()
	end

	local shards = bot.state.webSocketManager.shards

	for shardId in shards do
		shards[shardId]:forceClose()
	end
end

local function run(stub: discordStub.DiscordStub, world: World, scenario: () -> ())
	check.equal(
		stub:runScenario(scenario, function()
			stopBot(world.bot)
		end),
		nil
	)
end

type World = { bot: discordLuau.Bot? }

return function()
	test.suite("Bot voice", function()
		test.case("a join identifies as the bot user and resolves with the guild's connection", function()
			local stub, _, voiceServer = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)
				local joined = voiceChannel(bot, CHANNEL_ID):joinAsync():await()

				check.is_true(joined:isOk())
				check.equal(bot.state.voiceConnections[GUILD_ID], joined:unwrapOk())
				check.equal(identifyUserId(voiceServer), STUB_USER_ID)
			end)
		end)

		test.case("joining the same channel again resolves with the same connection", function()
			local stub, _, voiceServer = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)
				local first = voiceChannel(bot, CHANNEL_ID):joinAsync():await():unwrapOk()
				local again = voiceChannel(bot, CHANNEL_ID):joinAsync():await():unwrapOk()

				check.equal(again, first)
				check.equal(#voiceServer.connections, 1)
			end)
		end)

		test.case("joining another channel of the guild leaves the first, then joins", function()
			local stub, gateway = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)
				local first = voiceChannel(bot, CHANNEL_ID):joinAsync():await():unwrapOk()
				local second = voiceChannel(bot, OTHER_CHANNEL_ID):joinAsync():await()
				local requests = gateway:receivedOps(4)

				check.is_true(second:isOk())
				check.equal(first.status, "closed")
				check.equal(second:unwrapOk().status, "ready")
				check.equal(second:unwrapOk().channelId, OTHER_CHANNEL_ID)
				check.equal(requests[2].raw, LEAVE_TEXT)
				check.equal((requests[3].payload.d :: any).channel_id, OTHER_CHANNEL_ID)
				check.equal(bot.state.voiceConnections[GUILD_ID], second:unwrapOk())
			end)
		end)

		test.case("concurrent joins to two channels end with one live connection", function()
			local stub, _, voiceServer = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)
				local joinFirst = voiceChannel(bot, CHANNEL_ID):joinAsync()

				joinFirst:poll()

				local joinSecond = voiceChannel(bot, OTHER_CHANNEL_ID):joinAsync():await()

				joinFirst:await()

				check.is_true(joinSecond:isOk())
				check.equal(bot.state.voiceConnections[GUILD_ID], joinSecond:unwrapOk())
				check.equal(joinSecond:unwrapOk().status, "ready")
				check.is_true(stub.clock:waitFor(function()
					return openVoiceSockets(voiceServer) == 1
				end, 5))
			end)
		end)

		test.case("leaveAsync from a fresh channel object leaves the guild's connection", function()
			local stub, gateway = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)

				check.is_true(voiceChannel(bot, CHANNEL_ID):joinAsync():await():isOk())
				check.is_true(voiceChannel(bot, CHANNEL_ID):leaveAsync():await():isOk())
				check.equal(bot.state.voiceConnections[GUILD_ID], nil)
				check.is_true(stub.clock:waitFor(function()
					return #gateway:receivedOps(4) == 2
				end, 5))
				check.equal(gateway:receivedOps(4)[2].raw, LEAVE_TEXT)
			end)
		end)

		test.case("a join before READY or without the GuildVoiceStates intent fails at once", function()
			local stub = newWorld()
			local world: World = {}

			run(stub, world, function()
				local unready = voiceChannel(newBot(stub, GUILD_VOICE_STATES_INTENT), CHANNEL_ID):joinAsync():await()

				check.is_true(unready:isErr())
				check.truthy((string.find(tostring(unready:unwrapErr()), "wait for onAllShardsReady", 1, true)))

				local bot = startBot(stub, world, 0)
				local intentless = voiceChannel(bot, CHANNEL_ID):joinAsync():await()

				check.is_true(intentless:isErr())
				check.truthy((string.find(tostring(intentless:unwrapErr()), "GuildVoiceStates", 1, true)))
			end)
		end)

		test.case("a failed join clears the guild's connection", function()
			local stub, _, voiceServer = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)
				voiceServer.refuseUpgrades = 1

				check.is_true(voiceChannel(bot, CHANNEL_ID):joinAsync():await():isErr())
				check.equal(bot.state.voiceConnections[GUILD_ID], nil)
			end)
		end)

		test.case("a channel object forwards onMediaReady from the guild's connection", function()
			local stub = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)
				local channel = voiceChannel(bot, CHANNEL_ID)
				local mediaReadyEmits = discordStub.recordEmits(channel.onMediaReady)

				check.is_true(channel:joinAsync():await():isOk())
				check.is_true(stub.clock:waitFor(function()
					return #mediaReadyEmits == 1
				end, 5))
			end)
		end)

		test.case("sending audio or Speaking with no connection returns an Err instead of throwing", function()
			local stub = newWorld()
			local world: World = {}

			run(stub, world, function()
				local bot = startBot(stub, world)
				local channel = voiceChannel(bot, CHANNEL_ID)
				local sendCalled, sent = pcall(function()
					return channel:sendOpusAsync(buffer.create(3)):await()
				end)
				local speakingCalled, spoke = pcall(function()
					return channel:setSpeakingAsync(1):await()
				end)

				check.is_true(sendCalled)
				check.is_true(speakingCalled)
				check.truthy(
					sendCalled
						and string.find(tostring(sent:unwrapErr() or ""), "not connected to a voice channel", 1, true)
				)
				check.truthy(
					speakingCalled
						and string.find(tostring(spoke:unwrapErr() or ""), "not connected to a voice channel", 1, true)
				)
			end)
		end)
	end)
end
