local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local websocket = require("../luau_packages/websocket")

local voice = require("../src")

local GUILD_ID = "10"
local CHANNEL_ID = "20"
local OTHER_CHANNEL_ID = "21"
local USER_ID = "1"
local VOICE_SERVER_CRASHED = 4015
local SESSION_NO_LONGER_VALID = 4006
local DISCONNECTED = 4014
local DAVE_PROTOCOL_REQUIRED = 4017
local DISCONNECTED_RATE_LIMITED = 4021
local WAIT_SECONDS = 1200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice recovery", function() end)
	end
end

local function connectManager(stub: discordStub.DiscordStub, url: string): websocket.Manager
	local manager = websocket.manager.new({
		token = secret.new("stub-token"),
		intents = 0,
		webSocketVersion = 10,
		reconnect = true,
	})

	manager.logger:setLogLevel("Warn")
	manager
		:connectAsync({
			url = url,
			shards = 1,
			session_start_limit = { total = 1000, remaining = 1000, reset_after = 0, max_concurrency = 1 },
		})
		:await()

	assert(
		stub.clock:waitFor(function()
			return manager.ready
		end, WAIT_SECONDS),
		"the gateway never became ready"
	)

	return manager
end

local function newConnection(manager: websocket.Manager): voice.Connection
	return voice.connection.new({
		shard = manager.shards[1],
		guildId = GUILD_ID,
		channelId = CHANNEL_ID,
		userId = USER_ID,
		logLevel = "Error",
	})
end

local function joinOps(gateway: any, channelId: string?): number
	local count = 0

	for _, record in gateway:receivedOps(4) do
		if (record.payload.d or {}).channel_id == channelId then
			count += 1
		end
	end

	return count
end

local function countResumes(voiceServer: discordStub.VoiceServer): number
	local count = 0

	for _, opcode in voiceServer:receivedOps() do
		if opcode == 7 then
			count += 1
		end
	end

	return count
end

local function watchClose(connection: voice.Connection): CloseRecord
	local record: CloseRecord = { count = 0 }

	connection.onClosed:listen(function(reason: string, code: number?)
		record.count += 1
		record.reason = reason
		record.code = code
	end)

	return record
end

local function teardown(manager: websocket.Manager?, connection: voice.Connection?)
	if connection then
		connection:destroy()
	end

	if manager then
		for shardId in manager.shards do
			manager.shards[shardId]:forceClose()
		end
	end
end

local function run(stub: discordStub.DiscordStub, world: World, scenario: () -> ())
	check.equal(
		stub:runScenario(scenario, function()
			teardown(world.manager, world.connection)
		end),
		nil
	)
end

local function joinedWorld(stub: discordStub.DiscordStub, gateway: any, world: World): voice.Connection
	world.manager = connectManager(stub, gateway.url)
	world.connection = newConnection(world.manager :: websocket.Manager)

	local joining = world.connection :: voice.Connection

	assert(joining:joinAsync(WAIT_SECONDS):await():isOk(), "the first join failed")

	return joining
end

type CloseRecord = { count: number, reason: string?, code: number? }
type World = { manager: websocket.Manager?, connection: voice.Connection? }

return function()
	test.suite("Voice recovery", function()
		test.case("4015 resumes the session and fires onResumed, not onReady", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local readies = 0
				local resumes = 0

				joining.onReady:listen(function()
					readies += 1
				end)
				joining.onResumed:listen(function()
					resumes += 1
				end)
				voiceServer:close(VOICE_SERVER_CRASHED)

				check.is_true(voiceServer:waitForOp(7, WAIT_SECONDS))
				check.is_true(stub.clock:waitFor(function()
					return resumes == 1
				end, WAIT_SECONDS))
				check.equal(joining.status, "ready")
				check.equal(readies, 0)
				check.equal(joinOps(gateway, CHANNEL_ID), 1)
			end)
		end)

		test.case("a resume whose socket will not open falls back to a rejoin", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)

				voiceServer.refuseUpgrades = 1
				voiceServer:close(VOICE_SERVER_CRASHED)

				check.is_true(stub.clock:waitFor(function()
					return joinOps(gateway, CHANNEL_ID) == 2 and joining.status == "ready"
				end, WAIT_SECONDS))
			end)
		end)

		test.case("4006 rejoins with a fresh op 4", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)

				voiceServer:close(SESSION_NO_LONGER_VALID)

				check.is_true(stub.clock:waitFor(function()
					return joinOps(gateway, CHANNEL_ID) == 2 and joining.status == "ready"
				end, WAIT_SECONDS))
			end)
		end)

		test.case("a silent 4014 on the same gateway session closes with rejected and leaves", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local closes = watchClose(joining)

				voiceServer:close(DISCONNECTED)

				check.is_true(stub.clock:waitFor(function()
					return closes.count > 0
				end, WAIT_SECONDS))
				check.equal(closes.reason, "rejected")
				check.equal(closes.code, DISCONNECTED)
				check.is_true(stub.clock:waitFor(function()
					return joinOps(gateway, nil) == 1
				end, WAIT_SECONDS))
			end)
		end)

		test.case("a silent 4014 after the gateway session was replaced rejoins", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local shard = (world.manager :: websocket.Manager).shards[1]
				local firstSession = shard.sessionId

				gateway.connections[1]:send({ op = 9, d = false })

				check.is_true(stub.clock:waitFor(function()
					return shard.sessionId and shard.sessionId ~= firstSession
				end, WAIT_SECONDS))

				voiceServer:close(DISCONNECTED)

				check.is_true(stub.clock:waitFor(function()
					return joinOps(gateway, CHANNEL_ID) == 2 and joining.status == "ready"
				end, WAIT_SECONDS))
			end)
		end)

		test.case("fatal close codes close with rejected", function()
			for _, code in { DAVE_PROTOCOL_REQUIRED, DISCONNECTED_RATE_LIMITED } do
				local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
				local gateway = stub:createWebsocketServer()
				local voiceServer = stub:createVoiceServer()
				local world: World = {}

				run(stub, world, function()
					local joining = joinedWorld(stub, gateway, world)
					local closes = watchClose(joining)

					voiceServer:close(code)

					check.is_true(stub.clock:waitFor(function()
						return closes.count > 0
					end, WAIT_SECONDS))
					check.equal(closes.reason, "rejected")
					check.equal(closes.code, code)
					check.equal(joinOps(gateway, CHANNEL_ID), 1)
				end)
			end
		end)

		test.case("five failed rejoins close with gaveUp", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local closes = watchClose(joining)

				voiceServer.refuseUpgrades = 5
				voiceServer:close(SESSION_NO_LONGER_VALID)

				check.is_true(stub.clock:waitFor(function()
					return closes.count > 0
				end, WAIT_SECONDS))
				check.equal(closes.reason, "gaveUp")
				check.equal(joinOps(gateway, CHANNEL_ID), 6)
			end)
		end)

		test.case("resumes that keep missing heartbeat ACKs end in gaveUp", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ heartbeatIntervalMilliseconds = 5000 })
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local closes = watchClose(joining)

				voiceServer.ackHeartbeats = false

				check.is_true(stub.clock:waitFor(function()
					return closes.count > 0
				end, WAIT_SECONDS))
				check.equal(closes.reason, "gaveUp")
				check.greater_eq(countResumes(voiceServer), 5)
			end)
		end)

		test.case("rejoins whose voice handshake never finishes spend their attempts and end in gaveUp", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local closes = watchClose(joining)

				voiceServer.upgradeDelaySeconds = 100
				voiceServer:close(SESSION_NO_LONGER_VALID)

				check.is_true(stub.clock:waitFor(function()
					return closes.count > 0
				end, WAIT_SECONDS))
				check.equal(closes.reason, "gaveUp")
				check.equal(joinOps(gateway, CHANNEL_ID), 6)
			end)
		end)

		test.case("a move that lands after the server update's grace waits for its own server, then rejoins", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)

				voiceServer.upgradeDelaySeconds = 8
				gateway:dispatch(
					"VOICE_SERVER_UPDATE",
					{ token = voiceServer.token, guild_id = GUILD_ID, endpoint = voiceServer.url }
				)

				check.is_true(stub.clock:waitFor(function()
					return voiceServer.handshaking
				end, WAIT_SECONDS))

				stub.clock:wait(6)
				voiceServer.upgradeDelaySeconds = 0
				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = OTHER_CHANNEL_ID,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})

				check.is_true(stub.clock:waitFor(function()
					return joining.channelId == OTHER_CHANNEL_ID
						and joining.status == "ready"
						and joinOps(gateway, OTHER_CHANNEL_ID) == 1
				end, WAIT_SECONDS))
			end)
		end)

		test.case("a UDP discovery left over from a superseded connect does not drop the new session", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local udpServer = voiceServer.udpServer

				udpServer.ignoreDiscovery = 3
				gateway:dispatch(
					"VOICE_SERVER_UPDATE",
					{ token = voiceServer.token, guild_id = GUILD_ID, endpoint = voiceServer.url }
				)

				check.is_true(stub.clock:waitFor(function()
					return udpServer.ignoreDiscovery < 3
				end, WAIT_SECONDS))

				udpServer.ignoreDiscovery = 0
				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = OTHER_CHANNEL_ID,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})

				check.is_true(stub.clock:waitFor(function()
					return joining.channelId == OTHER_CHANNEL_ID and joining.status == "ready"
				end, WAIT_SECONDS))

				stub.clock:wait(10)

				check.equal(joining.status, "ready")
				check.equal(joining.recoveryAttempts, 0)
				check.equal(joinOps(gateway, OTHER_CHANNEL_ID), 0)
				check.not_nil(joining.udp.udpSocket)
			end)
		end)

		test.case("a destroy during the rejoin backoff sends no further op 4", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)

				voiceServer.refuseUpgrades = 1
				voiceServer:close(SESSION_NO_LONGER_VALID)

				check.is_true(stub.clock:waitFor(function()
					return joinOps(gateway, CHANNEL_ID) == 2 and joining.status == "disconnected"
				end, WAIT_SECONDS))

				joining:destroy()
				stub.clock:wait(30)

				check.equal(joinOps(gateway, CHANNEL_ID), 2)
				check.equal(joinOps(gateway, nil), 1)
			end)
		end)

		test.case("lost discovery replies fail a first join, and a rejoin moves on to its next attempt", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)
				voiceServer.udpServer.ignoreDiscovery = 3

				local failedJoin = world.connection :: voice.Connection

				check.is_true(failedJoin:joinAsync(WAIT_SECONDS):await():isErr())

				failedJoin:destroy()
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				voiceServer.udpServer.ignoreDiscovery = 3
				voiceServer:close(SESSION_NO_LONGER_VALID)

				check.is_true(stub.clock:waitFor(function()
					return joinOps(gateway, CHANNEL_ID) >= 4 and joining.status == "ready"
				end, WAIT_SECONDS))
			end)
		end)

		test.case("a move away and back during the 4014 grace rejoins and fires onReady", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local joining = joinedWorld(stub, gateway, world)
				local readies = 0
				local resumes = 0

				joining.onReady:listen(function()
					readies += 1
				end)
				joining.onResumed:listen(function()
					resumes += 1
				end)
				voiceServer:close(DISCONNECTED)

				check.is_true(stub.clock:waitFor(function()
					return joining.status == "disconnected"
				end, WAIT_SECONDS))

				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = OTHER_CHANNEL_ID,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})
				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = CHANNEL_ID,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})

				check.is_true(stub.clock:waitFor(function()
					return readies == 1 and joining.status == "ready"
				end, WAIT_SECONDS))
				check.equal(joinOps(gateway, CHANNEL_ID), 2)
				check.is_true(joining.webSocket.socketActive)
				check.equal(resumes, 0)
				check.equal(countResumes(voiceServer), 0)
			end)
		end)
	end)
end
