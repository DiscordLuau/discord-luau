local frktest = require("../../../luau_packages/frktest")
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
local SPEAKER_ID = "77"
local SPEAKER_SSRC = 4321
local RTP_HEADER_SIZE = 12
local DISCONNECTED_CLOSE_CODE = 4014

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice connection", function() end)
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

local function newConnection(manager: websocket.Manager, logLevel: any): voice.Connection
	return voice.connection.new({
		shard = manager.shards[1],
		guildId = GUILD_ID,
		channelId = CHANNEL_ID,
		userId = USER_ID,
		logLevel = logLevel,
	})
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

local function closeAll(manager: websocket.Manager, connection: voice.Connection?)
	if connection then
		connection:destroy()
	end

	for shardId in manager.shards do
		manager.shards[shardId]:forceClose()
	end
end

return function()
	test.suite("Voice connection", function()
		test.case("joins, identifies, negotiates encryption and becomes ready", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local manager: websocket.Manager
			local connection: voice.Connection
			local readyCount = 0

			local function scenario()
				manager = connectManager(stub, gateway.url)
				connection = newConnection(manager, "Warn")
				connection.onReady:listen(function()
					readyCount += 1
				end)
				connection:requestVoiceAsync():await()

				check.is_true(stub.clock:waitFor(function()
					return readyCount > 0
				end, 30))
				check.equal(
					voiceServer.selectedMode,
					if sodium.aes256gcm.isAvailable()
						then "aead_aes256_gcm_rtpsize"
						else "aead_xchacha20_poly1305_rtpsize"
				)
				check.not_nil(connection.rtp.secretKey)
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("a close from the server is not reported as a receive error", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local manager: websocket.Manager
			local connection: voice.Connection
			local readyCount = 0
			local closeCodes: { number } = {}
			local warnings: { string } = {}

			local function scenario()
				manager = connectManager(stub, gateway.url)
				connection = newConnection(manager, "Warn")
				connection.logger:setSink(function(message: string)
					if string.find(message, "[WARN]", 1, true) then
						table.insert(warnings, message)
					end
				end)
				connection.onReady:listen(function()
					readyCount += 1
				end)
				connection.onDisconnected:listen(function(code: number?)
					table.insert(closeCodes, code or -1)
				end)
				connection:requestVoiceAsync():await()

				check.is_true(stub.clock:waitFor(function()
					return readyCount > 0
				end, 30))

				voiceServer:close(DISCONNECTED_CLOSE_CODE)

				check.is_true(stub.clock:waitFor(function()
					return #closeCodes > 0
				end, 10))
				check.equal(closeCodes[1], DISCONNECTED_CLOSE_CODE)

				for _, warning in warnings do
					check.equal(string.find(warning, "receive error", 1, true), nil)
				end
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("keeps receiving after a malformed binary frame and undecodable JSON", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local manager: websocket.Manager
			local connection: voice.Connection
			local readyCount = 0
			local speakers: { string } = {}

			local function scenario()
				manager = connectManager(stub, gateway.url)
				connection = newConnection(manager, "Error")
				connection.onReady:listen(function()
					readyCount += 1
				end)
				connection.onSpeaking:listen(function(event)
					table.insert(speakers, event.userId)
				end)
				connection:requestVoiceAsync():await()

				check.is_true(stub.clock:waitFor(function()
					return readyCount > 0
				end, 30))

				local voiceConnection = voiceServer.connections[#voiceServer.connections]

				voiceConnection:sendRaw(buffer.fromstring("\1"))
				voiceConnection:sendRaw("{not json")
				voiceServer:sendSpeaking(SPEAKER_ID, 4321, 1)

				check.is_true(stub.clock:waitFor(function()
					return #speakers > 0
				end, 10))
				check.equal(speakers[1], SPEAKER_ID)
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("with decodeAudio false, raw frames arrive and no PCM frame does", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local manager: websocket.Manager
			local connection: voice.Connection

			local function scenario()
				manager = connectManager(stub, gateway.url)
				connection = newConnection(manager, "Error")

				local rawFrames = discordStub.recordEmits(connection.onRawAudioFrame)
				local pcmFrames = discordStub.recordEmits(connection.onAudioFrame)

				connection.decodeAudio = false

				check.is_true(connection:joinAsync(30):await():isOk())

				for sequence = 100, 104 do
					voiceServer.udpServer:send(speakerPacket(voiceServer, sequence))
				end

				check.is_true(stub.clock:waitFor(function()
					return #rawFrames == 5
				end, 100))
				check.equal(#pcmFrames, 0)
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)
	end)
end
