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
local LEAVE_TEXT = '{"op":4,"d":{"guild_id":"10","channel_id":null,"self_mute":false,"self_deaf":false}}'
local SESSION_NO_LONGER_VALID = 4006
local WAIT_SECONDS = 1200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice lifecycle", function() end)
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

local function watchClose(connection: voice.Connection): CloseRecord
	local record: CloseRecord = { count = 0 }

	connection.onClosed:listen(function(reason: string, code: number?)
		record.count += 1
		record.reason = reason
		record.code = code
	end)

	return record
end

local function silenceVoiceStateUpdates(_: any, payload: any): false?
	if payload.op == 4 then
		return false
	end

	return
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

type CloseRecord = { count: number, reason: string?, code: number? }
type World = { manager: websocket.Manager?, connection: voice.Connection? }

return function()
	test.suite("Voice lifecycle", function()
		test.case("joinAsync sends op 4 once and resolves when the connection is ready", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())
				check.equal(joining.status, "ready")
				check.equal(joinOps(gateway, CHANNEL_ID), 1)
			end)
		end)

		test.case(
			"a join Discord never answers fails after its timeout, closes with joinTimedOut and leaves",
			function()
				local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
				local gateway = stub:createWebsocketServer(silenceVoiceStateUpdates)
				local world: World = {}

				stub:createVoiceServer()

				run(stub, world, function()
					world.manager = connectManager(stub, gateway.url)
					world.connection = newConnection(world.manager :: websocket.Manager)

					local joining = world.connection :: voice.Connection
					local closes = watchClose(joining)
					local joined = joining:joinAsync(5):await()

					check.is_true(joined:isErr())
					check.truthy((string.find(tostring(joined:unwrapErr()), "was not ready after 5s", 1, true)))
					check.equal(closes.reason, "joinTimedOut")
					check.equal(joining.status, "closed")
					check.is_true(stub.clock:waitFor(function()
						return joinOps(gateway, nil) == 1
					end, WAIT_SECONDS))
				end)
			end
		)

		test.case("a voice handshake that never finishes fails the join at its timeout and closes", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			voiceServer.upgradeDelaySeconds = 100

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection
				local closes = watchClose(joining)
				local started = stub.clock:now()
				local joined = joining:joinAsync(8):await()

				check.is_true(joined:isErr())
				check.lesser(stub.clock:now() - started, 12)
				check.equal(closes.reason, "joinTimedOut")
				check.equal(joining.status, "closed")
			end)
		end)

		test.case("the connection connects only once both voice events have arrived", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer(silenceVoiceStateUpdates)
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection
				local pending = joining:joinAsync(30)

				pending:poll()

				check.is_true(stub.clock:waitFor(function()
					return joinOps(gateway, CHANNEL_ID) == 1
				end, WAIT_SECONDS))

				gateway:dispatch(
					"VOICE_SERVER_UPDATE",
					{ token = voiceServer.token, guild_id = GUILD_ID, endpoint = voiceServer.url }
				)
				stub.clock:wait(2)

				check.equal(#voiceServer.connections, 0)

				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = CHANNEL_ID,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})

				check.is_true(pending:await():isOk())
				check.equal(#voiceServer.connections, 1)
			end)
		end)

		test.case("a second joinAsync while connecting sends no second op 4", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection
				local first = joining:joinAsync(30)

				first:poll()

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())
				check.is_true(first:await():isOk())
				check.equal(joinOps(gateway, CHANNEL_ID), 1)
			end)
		end)

		test.case("leaveAsync sends the leave and closes with left", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				local closes = watchClose(joining)

				check.is_true(joining:leaveAsync():await():isOk())
				check.equal(closes.reason, "left")
				check.equal(joining.status, "closed")
				check.is_true(stub.clock:waitFor(function()
					return #gateway:receivedOps(4) == 2
				end, WAIT_SECONDS))
				check.equal(gateway:receivedOps(4)[2].raw, LEAVE_TEXT)
			end)
		end)

		test.case("a disconnected connection ignores later voice events and closes once", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				local closes = watchClose(joining)

				joining:disconnectAsync():await()
				joining:destroy()
				gateway:dispatch(
					"VOICE_SERVER_UPDATE",
					{ token = voiceServer.token, guild_id = GUILD_ID, endpoint = voiceServer.url }
				)
				stub.clock:wait(2)

				check.equal(#voiceServer.connections, 1)
				check.equal(closes.count, 1)
				check.equal(closes.reason, "left")
			end)
		end)

		test.case("destroying a connection mid-handshake leaves no open voice socket", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				voiceServer.upgradeDelaySeconds = 5
				joining:joinAsync(30):poll()

				check.is_true(stub.clock:waitFor(function()
					return voiceServer.handshaking
				end, WAIT_SECONDS))

				joining:destroy()
				stub.clock:wait(10)

				check.is_false(joining.webSocket.socketActive)
				check.equal(table.find(voiceServer:receivedOps(), 0), nil)

				for _, voiceConnection in voiceServer.connections do
					check.is_false(voiceConnection.open)
				end
			end)
		end)

		test.case("a kick closes with removed and sends no further op 4", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				local closes = watchClose(joining)

				gateway:disconnectVoice(GUILD_ID)

				check.is_true(stub.clock:waitFor(function()
					return closes.count > 0
				end, WAIT_SECONDS))

				stub.clock:wait(10)

				check.equal(closes.reason, "removed")
				check.equal(joinOps(gateway, CHANNEL_ID), 1)
				check.equal(joinOps(gateway, nil), 0)
			end)
		end)

		test.case("a null endpoint waits for the replacement server and connects to it", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				gateway:dispatch(
					"VOICE_SERVER_UPDATE",
					{ token = voiceServer.token, guild_id = GUILD_ID, endpoint = zune.serde.json.values.null }
				)

				check.is_true(stub.clock:waitFor(function()
					return joining.status == "disconnected"
				end, WAIT_SECONDS))

				gateway:dispatch(
					"VOICE_SERVER_UPDATE",
					{ token = voiceServer.token, guild_id = GUILD_ID, endpoint = voiceServer.url }
				)

				check.is_true(stub.clock:waitFor(function()
					return joining.status == "ready" and #voiceServer.connections == 2
				end, WAIT_SECONDS))
				check.equal(joinOps(gateway, CHANNEL_ID), 1)
			end)
		end)

		test.case("a move follows the new channel when the state update comes first", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				gateway:moveVoice(GUILD_ID, OTHER_CHANNEL_ID)

				check.is_true(stub.clock:waitFor(function()
					return joining.channelId == OTHER_CHANNEL_ID
						and joining.status == "ready"
						and #voiceServer.connections == 2
				end, WAIT_SECONDS))
				check.equal(joinOps(gateway, OTHER_CHANNEL_ID), 0)
				check.equal(joining.recoveryAttempts, 0)
			end)
		end)

		test.case("a move follows the new channel when the server update comes first", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				gateway:dispatch(
					"VOICE_SERVER_UPDATE",
					{ token = voiceServer.token, guild_id = GUILD_ID, endpoint = voiceServer.url }
				)
				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = OTHER_CHANNEL_ID,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})

				check.is_true(stub.clock:waitFor(function()
					return joining.channelId == OTHER_CHANNEL_ID and joining.status == "ready"
				end, WAIT_SECONDS))
				check.equal(joinOps(gateway, OTHER_CHANNEL_ID), 0)
				check.equal(joining.recoveryAttempts, 0)
			end)
		end)

		test.case("a kick that arrives while a rejoin is signalling closes with removed", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local voiceServer = stub:createVoiceServer()
			local world: World = {}
			local gateway: any
			local joinRequests = 0

			gateway = stub:createWebsocketServer(function(_, payload)
				if payload.op ~= 4 or not (payload.d or {}).channel_id then
					return
				end

				joinRequests += 1

				if joinRequests < 2 then
					return
				end

				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = CHANNEL_ID,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})
				gateway:dispatch("VOICE_STATE_UPDATE", {
					guild_id = GUILD_ID,
					channel_id = zune.serde.json.values.null,
					user_id = USER_ID,
					session_id = voiceServer.sessionId,
				})

				return false
			end)

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				local closes = watchClose(joining)

				voiceServer:close(SESSION_NO_LONGER_VALID)

				check.is_true(stub.clock:waitFor(function()
					return closes.count > 0
				end, WAIT_SECONDS))
				check.equal(closes.reason, "removed")
				check.equal(joinOps(gateway, nil), 0)
			end)
		end)

		test.case("a Session Description with a short secret key fails the first join", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local joining = world.connection :: voice.Connection
				local closes = watchClose(joining)

				voiceServer.secretKey = buffer.create(16)

				check.is_true(joining:joinAsync(30):await():isErr())
				check.equal(closes.reason, "joinTimedOut")
			end)
		end)
	end)
end
