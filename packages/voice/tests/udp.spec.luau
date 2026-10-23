local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local opus = require("../luau_packages/opus")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local websocket = require("../luau_packages/websocket")

local voice = require("../src")

local SPEAKER_SSRC = 4321
local RTP_HEADER_SIZE = 12
local FORTY_MS_SILK_PACKET = "\16\0\0"
local FORTY_MS_SAMPLES = 1920
local WAIT_SECONDS = 1200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice UDP", function() end)
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

local function joinVoice(stub: discordStub.DiscordStub, manager: websocket.Manager): voice.Connection
	local connection = voice.connection.new({
		shard = manager.shards[1],
		guildId = "10",
		channelId = "20",
		userId = "1",
		logLevel = "Error",
	})
	local ready = false

	connection.onReady:listen(function()
		ready = true
	end)
	connection:requestVoiceAsync():await()

	assert(
		stub.clock:waitFor(function()
			return ready
		end, WAIT_SECONDS),
		"voice never became ready"
	)

	return connection
end

local function speakerPacket(voiceServer: discordStub.VoiceServer, sequence: number, payloadType: number?): buffer
	local encoder = opus.encoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS, opus.application.voip)
	local payload = encoder:encode(buffer.create(opus.DISCORD_FRAME_SIZE * opus.DISCORD_CHANNELS * 2))
	local rtpPacket = buffer.create(RTP_HEADER_SIZE + buffer.len(payload))
	local crypto = voice.rtp.new()

	encoder:destroy()
	buffer.writeu8(rtpPacket, 0, 0x80)
	buffer.writeu8(rtpPacket, 1, payloadType or 0x78)
	buffer.writeu16(rtpPacket, 2, bit32.byteswap(sequence) // 0x10000)
	buffer.writeu32(rtpPacket, 8, bit32.byteswap(SPEAKER_SSRC))
	buffer.copy(rtpPacket, RTP_HEADER_SIZE, payload)

	crypto.secretKey = voiceServer.secretKey
	crypto.encryptionMode = voiceServer.selectedMode

	return (crypto:encryptRtp(rtpPacket, nil, SPEAKER_SSRC))
end

local function findLine(lines: { string }, text: string): string?
	for _, line in lines do
		if string.find(line, text, 1, true) then
			return line
		end
	end

	return
end

local function rtpTimestamp(packet: buffer): number
	return bit32.byteswap(buffer.readu32(packet, 4))
end

local function closeAll(manager: websocket.Manager?, connection: voice.Connection?)
	if connection then
		connection:destroy()
	end

	if manager then
		for shardId in manager.shards do
			manager.shards[shardId]:forceClose()
		end
	end
end

return function()
	test.suite("Voice UDP", function()
		test.case("keeps receiving audio after a truncated RTP packet", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local received: { number } = {}
			local manager: websocket.Manager?
			local connection: voice.Connection?

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joined = joinVoice(stub, connectedManager)

				manager = connectedManager
				connection = joined
				joined.udp.onAudioPacket = function(ssrc: number, sequence: number)
					if ssrc == SPEAKER_SSRC then
						table.insert(received, sequence)
					end
				end

				voiceServer.udpServer:send(buffer.fromstring("\128"))
				voiceServer.udpServer:send(speakerPacket(voiceServer, 700))

				check.is_true(stub.clock:waitFor(function()
					return #received > 0
				end, 10))
				check.equal(received[1], 700)
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("frames sent back to back carry consecutive sequence numbers", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local manager: websocket.Manager?
			local connection: voice.Connection?

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joined = joinVoice(stub, connectedManager)
				local packetsBefore = #voiceServer.udpServer.packets
				local frame = buffer.create(3)

				manager = connectedManager
				connection = joined
				joined:sendOpusAsync(frame):poll()
				joined:sendOpusAsync(frame):poll()

				check.is_true(stub.clock:waitFor(function()
					return #voiceServer.udpServer.packets >= packetsBefore + 2
				end, 10))

				local first = voiceServer.udpServer.packets[packetsBefore + 1]
				local second = voiceServer.udpServer.packets[packetsBefore + 2]

				check.equal(
					(buffer.readu8(second, 2) * 256 + buffer.readu8(second, 3))
						- (buffer.readu8(first, 2) * 256 + buffer.readu8(first, 3)),
					1
				)
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("the timestamp advances by each packet's samples; an invalid packet reserves nothing", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local manager: websocket.Manager?
			local connection: voice.Connection?

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joined = joinVoice(stub, connectedManager)
				local packets = voiceServer.udpServer.packets
				local packetsBefore = #packets

				manager = connectedManager
				connection = joined

				for _ = 1, 3 do
					check.is_true(joined:sendOpusAsync(buffer.fromstring(FORTY_MS_SILK_PACKET)):await():isOk())
				end

				local sequenceBefore = joined.rtp.rtpSequence
				local timestampBefore = joined.rtp.rtpTimestamp
				local invalid = joined:sendOpusAsync(buffer.create(0)):await()

				check.is_true(stub.clock:waitFor(function()
					return #packets >= packetsBefore + 3
				end, 10))
				check.equal(
					rtpTimestamp(packets[packetsBefore + 2]) - rtpTimestamp(packets[packetsBefore + 1]),
					FORTY_MS_SAMPLES
				)
				check.equal(
					rtpTimestamp(packets[packetsBefore + 3]) - rtpTimestamp(packets[packetsBefore + 2]),
					FORTY_MS_SAMPLES
				)
				check.is_true(invalid:isErr())
				check.equal(joined.rtp.rtpSequence, sequenceBefore)
				check.equal(joined.rtp.rtpTimestamp, timestampBefore)
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("a send whose socket send fails resolves Err and still uses its sequence number", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local manager: websocket.Manager?
			local connection: voice.Connection?

			stub:createVoiceServer()

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joined = joinVoice(stub, connectedManager)
				local udpSocket = joined.udp.udpSocket :: stdPolyfills.UdpSocket
				local sequenceBefore = joined.rtp.rtpSequence

				manager = connectedManager
				connection = joined
				udpSocket.close()

				local result = joined:sendOpusAsync(buffer.create(3)):await()

				check.is_true(result:isErr())
				check.not_nil(
					(string.find(tostring(result:unwrapErr() or ""), "audio send failed: socket closed", 1, true))
				)
				check.equal(joined.rtp.rtpSequence, sequenceBefore + 1)
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("a non-Opus packet is skipped at debug, and Opus with the marker bit still arrives", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local received: { number } = {}
			local lines: { string } = {}
			local manager: websocket.Manager?
			local connection: voice.Connection?

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joined = joinVoice(stub, connectedManager)

				manager = connectedManager
				connection = joined
				joined.logger:setLogLevel("Debug")
				joined.logger:setSink(function(line: string)
					table.insert(lines, line)
				end)
				joined.udp.onAudioPacket = function(ssrc: number, sequence: number)
					if ssrc == SPEAKER_SSRC then
						table.insert(received, sequence)
					end
				end

				voiceServer.udpServer:send(speakerPacket(voiceServer, 800, 0x65))
				voiceServer.udpServer:send(speakerPacket(voiceServer, 801, 0xF8))

				check.is_true(stub.clock:waitFor(function()
					return #received > 0
				end, 10))
				check.equal(received[1], 801)
				check.not_nil(findLine(lines, "skipping an RTP packet with payload type 101"))
			end

			check.equal(
				stub:runScenario(scenario, function()
					closeAll(manager, connection)
				end),
				nil
			)
		end)

		test.case("a packet too short for its header, tag and nonce is dropped at debug, without a warn", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local received: { number } = {}
			local lines: { string } = {}
			local manager: websocket.Manager?
			local connection: voice.Connection?

			local function scenario()
				local connectedManager = connectManager(stub, gateway.url)
				local joined = joinVoice(stub, connectedManager)
				local truncated = buffer.create(20)

				manager = connectedManager
				connection = joined
				joined.logger:setLogLevel("Debug")
				joined.logger:setSink(function(line: string)
					table.insert(lines, line)
				end)
				joined.udp.onAudioPacket = function(ssrc: number, sequence: number)
					if ssrc == SPEAKER_SSRC then
						table.insert(received, sequence)
					end
				end
				buffer.writeu8(truncated, 0, 0x80)
				buffer.writeu8(truncated, 1, 0x78)

				voiceServer.udpServer:send(truncated)
				voiceServer.udpServer:send(speakerPacket(voiceServer, 900))

				check.is_true(stub.clock:waitFor(function()
					return #received > 0
				end, 10))
				check.equal(received[1], 900)
				check.equal(findLine(lines, "[WARN]"), nil)
				check.not_nil(findLine(lines, "dropping an RTP packet: it is 20 bytes"))
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
