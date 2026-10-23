local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local logger = require("../luau_packages/logger")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local websocket = require("../luau_packages/websocket")

local voice = require("../src")

local GUILD_ID = "10"
local CHANNEL_ID = "20"
local USER_ID = "1"
local SCRIPTED_OPCODE = 200
local VOICE_SERVER_CRASHED = 4015
local EXTERNAL_SENDER_OPCODE = 25
local BRACE_HIGH_BYTE_SEQUENCE = 0x7B01
local WAIT_SECONDS = 1200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice transport", function() end)
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

local function received(voiceServer: discordStub.VoiceServer, opcode: number): { any }
	local payloads = {}

	for _, record in voiceServer.received do
		if record.opcode == opcode then
			table.insert(payloads, record.payload.d)
		end
	end

	return payloads
end

local function awaitInBackground(pending: any): { result: any }
	local holder = {}

	stdPolyfills.task.spawn(function()
		holder.result = pending:await()
	end)

	return holder
end

return function()
	test.suite("Voice transport", function()
		test.case("heartbeats send seq_ack -1 before any sequenced message, and Resume sends the last seq", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local manager: websocket.Manager?
			local connection: voice.Connection?

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joining = voice.connection.new({
					shard = connectedManager.shards[1],
					guildId = GUILD_ID,
					channelId = CHANNEL_ID,
					userId = USER_ID,
					logLevel = "Error",
				})

				manager = connectedManager
				connection = joining
				joining:requestVoiceAsync():await()

				check.is_true(voiceServer:waitForOp(3, WAIT_SECONDS))
				check.equal(received(voiceServer, 3)[1].seq_ack, -1)

				voiceServer:sendBinary(SCRIPTED_OPCODE, buffer.create(1))
				stub.clock:wait(1)
				voiceServer:close(VOICE_SERVER_CRASHED)

				check.is_true(voiceServer:waitForOp(7, WAIT_SECONDS))
				check.equal(received(voiceServer, 7)[1].seq_ack, voiceServer.sequence)
			end

			check.equal(
				stub:runScenario(scenario, function()
					if connection then
						connection:destroy()
					end

					if manager then
						for shardId in manager.shards do
							manager.shards[shardId]:forceClose()
						end
					end
				end),
				nil
			)
		end)

		test.case("IP discovery retries a lost reply and fails after three", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local udpServer = discordStub.UdpServer.new()
			local transport = voice.udp.new(logger.new("UdpSpec", "Error"))

			local function scenario()
				transport.ssrc = 1234
				transport.udpIp = "127.0.0.1"
				transport.udpPort = udpServer.port
				udpServer.ignoreDiscovery = 2

				local recovered = awaitInBackground(transport:discoverIpAsync())

				check.is_true(stub.clock:waitFor(function()
					return recovered.result
				end, WAIT_SECONDS))
				check.is_true(recovered.result:isOk())

				transport:cleanup()
				transport.ssrc = 1234
				transport.udpIp = "127.0.0.1"
				transport.udpPort = udpServer.port
				udpServer.ignoreDiscovery = 3

				local lost = awaitInBackground(transport:discoverIpAsync())

				check.is_true(stub.clock:waitFor(function()
					return lost.result
				end, WAIT_SECONDS))
				check.is_true(lost.result:isErr())
				check.equal(transport.udpSocket, nil)
			end

			check.equal(
				stub:runScenario(scenario, function()
					transport:cleanup()
					udpServer:stop()
				end),
				nil
			)
		end)

		test.case(
			"a voice socket that opens after it stopped being wanted is closed, and overlapping opens raise",
			function()
				local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
				local voiceServer = stub:createVoiceServer()
				local transport = voice.webSocket.new(logger.new("SocketSpec", "Error"))

				local function scenario()
					transport:openSocket(`{voiceServer.url}/?v=8`, function()
						return false
					end)

					check.is_false(transport.socketActive)
					check.equal(transport.socketInstance, nil)
					check.is_true(stub.clock:waitFor(function()
						return voiceServer.connections[1] and not voiceServer.connections[1].open
					end, WAIT_SECONDS))

					voiceServer.upgradeDelaySeconds = 2

					stdPolyfills.task.spawn(function()
						transport:openSocket(`{voiceServer.url}/?v=8`)
					end)

					check.is_true(stub.clock:waitFor(function()
						return voiceServer.handshaking
					end, WAIT_SECONDS))

					local overlapped =
						pcall(transport.openSocket :: (...any) -> ...any, transport, `{voiceServer.url}/?v=8`)

					check.is_false(overlapped)
					check.is_true(stub.clock:waitFor(function()
						return transport.socketActive
					end, WAIT_SECONDS))
					check.equal(#voiceServer.connections, 2)
				end

				check.equal(
					stub:runScenario(scenario, function()
						transport:forceClose(1000)
					end),
					nil
				)
			end
		)

		test.case("a binary frame whose sequence number starts with the byte of '{' is read as binary", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local binaryMessages: { any } = {}
			local manager: websocket.Manager?
			local connection: voice.Connection?

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joining = voice.connection.new({
					shard = connectedManager.shards[1],
					guildId = GUILD_ID,
					channelId = CHANNEL_ID,
					userId = USER_ID,
					logLevel = "Error",
				})

				manager = connectedManager
				connection = joining
				joining.onRawMessage:listen(function(payload: any)
					if payload.op == EXTERNAL_SENDER_OPCODE then
						table.insert(binaryMessages, payload)
					end
				end)

				check.is_true(joining:joinAsync(WAIT_SECONDS):await():isOk())

				voiceServer.sequence = BRACE_HIGH_BYTE_SEQUENCE - 1
				voiceServer:sendBinary(EXTERNAL_SENDER_OPCODE, buffer.fromstring("sender"))

				check.is_true(stub.clock:waitFor(function()
					return #binaryMessages > 0
				end, WAIT_SECONDS))
				check.equal(binaryMessages[1].seq, BRACE_HIGH_BYTE_SEQUENCE)
				check.equal(buffer.tostring(binaryMessages[1].d), "sender")
			end

			check.equal(
				stub:runScenario(scenario, function()
					if connection then
						connection:destroy()
					end

					if manager then
						for shardId in manager.shards do
							manager.shards[shardId]:forceClose()
						end
					end
				end),
				nil
			)
		end)
	end)
end
