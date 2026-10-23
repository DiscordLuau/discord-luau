local frktest = require("../../../luau_packages/frktest")
local apiTypes = require("../luau_packages/api_types")
local discordStub = require("../luau_packages/discord_stub")
local opus = require("../luau_packages/opus")
local secret = require("../luau_packages/secret")
local sodium = require("../luau_packages/sodium")
local stdPolyfills = require("../luau_packages/std_polyfills")
local websocket = require("../luau_packages/websocket")

local voice = require("../src")

local GUILD_ID = "10"
local CHANNEL_ID = "20"
local USER_ID = "1"
local BOT_SSRC = 1234
local SPEAKER_SSRC = 4321
local RTP_HEADER_SIZE = 12

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice error surfacing", function() end)
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
		end, 30),
		"the gateway never became ready"
	)

	return manager
end

local function newConnection(manager: websocket.Manager): (voice.Connection, { string })
	local connection = voice.connection.new({
		shard = manager.shards[1],
		guildId = GUILD_ID,
		channelId = CHANNEL_ID,
		userId = USER_ID,
		logLevel = "Warn",
	})
	local lines: { string } = {}

	connection.logger:setSink(function(line: string)
		table.insert(lines, line)
	end)

	return connection, lines
end

local function hasLine(lines: { string }, needle: string): boolean
	for _, line in lines do
		if string.find(line, needle, 1, true) then
			return true
		end
	end

	return false
end

local function run(stub: discordStub.DiscordStub, world: World, scenario: () -> ())
	check.equal(
		stub:runScenario(scenario, function()
			if world.connection then
				world.connection:destroy()
			end

			if world.manager then
				for shardId in world.manager.shards do
					world.manager.shards[shardId]:forceClose()
				end
			end
		end),
		nil
	)
end

local function speakerPacket(voiceServer: discordStub.VoiceServer, sequence: number): buffer
	local encoder = opus.encoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS, opus.application.voip)
	local payload = encoder:encode(buffer.create(opus.DISCORD_FRAME_SIZE * opus.DISCORD_CHANNELS * 2))
	local rtpPacket = buffer.create(RTP_HEADER_SIZE + buffer.len(payload))
	local crypto = voice.rtp.new()

	encoder:destroy()
	buffer.writeu8(rtpPacket, 0, 0x80)
	buffer.writeu8(rtpPacket, 1, 0x78)
	buffer.writeu16(rtpPacket, 2, bit32.byteswap(sequence) // 0x10000)
	buffer.writeu32(rtpPacket, 8, bit32.byteswap(SPEAKER_SSRC))
	buffer.copy(rtpPacket, RTP_HEADER_SIZE, payload)

	crypto.secretKey = voiceServer.secretKey
	crypto.encryptionMode = voiceServer.selectedMode

	return (crypto:encryptRtp(rtpPacket, nil, SPEAKER_SSRC))
end

local function countReceived(voiceServer: discordStub.VoiceServer, opcode: number): number
	local count = 0

	for _, receivedOpcode in voiceServer:receivedOps() do
		if receivedOpcode == opcode then
			count += 1
		end
	end

	return count
end

type World = { manager: websocket.Manager?, connection: voice.Connection? }

return function()
	test.suite("Voice error surfacing", function()
		test.case("a throw after UDP discovery is warned and drops the handshake for the supervisor", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}
			local originalIsAvailable = sodium.aes256gcm.isAvailable

			stub:createVoiceServer()

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)

				local connection, lines = newConnection(world.manager :: websocket.Manager)

				world.connection = connection
				sodium.aes256gcm.isAvailable = function()
					error("sodium boom")
				end

				check.not_nil((string.find(connection:joinAsync(30):await():unwrapErr(), "handshakeFailed", 1, true)))

				sodium.aes256gcm.isAvailable = originalIsAvailable

				check.is_true(hasLine(lines, "UDP discovery and Select Protocol failed"))
				check.is_true(hasLine(lines, "sodium boom"))
			end)

			sodium.aes256gcm.isAvailable = originalIsAvailable
		end)

		test.case("voice gateway sends that cannot go out resolve Err instead of Ok", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)

				local connection = newConnection(world.manager :: websocket.Manager)

				world.connection = connection
				connection.udp.ssrc = BOT_SSRC

				check.is_true(connection:identifyAsync():await():isErr())
				check.is_true(connection:resumeAsync():await():isErr())
				check.is_true(connection:selectProtocolAsync("127.0.0.1", 1, "mode"):await():isErr())
				check.is_true(connection:setSpeakingAsync(1):await():isErr())
				check.is_true(connection.webSocket:heartbeatAsync(true):await():isErr())
			end)
		end)

		test.case("a packet whose handling raises is warned and the next packet is still received", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}
			local received: { number } = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)

				local connection, lines = newConnection(world.manager :: websocket.Manager)
				local ready = false

				world.connection = connection
				connection.onReady:listen(function()
					ready = true
				end)
				connection:requestVoiceAsync():await()

				assert(
					stub.clock:waitFor(function()
						return ready
					end, 30),
					"voice never became ready"
				)

				local realDecrypt = connection.udp.decryptPacket :: (buffer) -> (buffer?, string?)
				local decryptCalls = 0

				connection.udp.decryptPacket = function(rawPacket: buffer): (buffer?, string?)
					decryptCalls += 1

					if decryptCalls == 1 then
						return buffer.create(5), nil
					end

					return realDecrypt(rawPacket)
				end
				connection.udp.onAudioPacket = function(_: number, sequence: number)
					table.insert(received, sequence)
				end

				voiceServer.udpServer:send(speakerPacket(voiceServer, 600))
				voiceServer.udpServer:send(speakerPacket(voiceServer, 700))

				check.is_true(stub.clock:waitFor(function()
					return #received > 0
				end, 10))
				check.equal(received[1], 700)
				check.is_true(hasLine(lines, "UDP packet handling errored"))
			end)
		end)

		test.case("Speaking with no ssrc resolves Err and sends no op 5", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)

				local connection = newConnection(world.manager :: websocket.Manager)

				world.connection = connection

				check.is_true(connection:joinAsync(30):await():isOk())

				local speakingBefore = countReceived(voiceServer, apiTypes.voice.opcodes.Speaking)

				connection.udp.ssrc = nil

				local result = connection:setSpeakingAsync(1):await()

				stub.clock:wait(1)

				check.is_true(result:isErr())
				check.not_nil(
					(string.find(tostring(result:unwrapErr() or ""), "cannot set speaking: SSRC not assigned", 1, true))
				)
				check.equal(countReceived(voiceServer, apiTypes.voice.opcodes.Speaking), speakingBefore)
			end)
		end)
	end)
end
