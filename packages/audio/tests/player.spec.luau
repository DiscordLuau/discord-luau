local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local opus = require("../luau_packages/opus")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local voice = require("../luau_packages/voice")
local websocket = require("../luau_packages/websocket")

local audio = require("../src")

local GUILD_ID = "10"
local CHANNEL_ID = "20"
local USER_ID = "1"
local PACKET = "\248\0\0"
local SILENCE = "\248\255\254"
local RTP_HEADER_SIZE = 12
local FRAME_BYTES = 3840
local SPEAKING_OPCODE = 5
local WAIT_SECONDS = 1200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio player", function() end)
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

local function joinedConnection(stub: discordStub.DiscordStub, gateway: any, world: World): voice.Connection
	world.manager = connectManager(stub, gateway.url)
	world.connection = newConnection(world.manager :: websocket.Manager)

	local joining = world.connection :: voice.Connection

	assert(joining:joinAsync(WAIT_SECONDS):await():isOk(), "the join failed")

	return joining
end

local function teardown(world: World)
	if world.connection then
		world.connection:destroy()
	end

	if world.manager then
		for shardId in world.manager.shards do
			world.manager.shards[shardId]:forceClose()
		end
	end
end

local function run(stub: discordStub.DiscordStub, world: World, scenario: () -> ())
	check.equal(
		stub:runScenario(scenario, function()
			teardown(world)
		end),
		nil
	)
end

local function opusPackets(count: number): { buffer }
	local packets = {}

	for _ = 1, count do
		table.insert(packets, buffer.fromstring(PACKET))
	end

	return packets
end

local function tone(byteCount: number): buffer
	local pcm = buffer.create(byteCount)

	for sampleIndex = 0, byteCount // 4 - 1 do
		local sample = math.floor(math.sin(2 * math.pi * 440 * sampleIndex / opus.DISCORD_SAMPLE_RATE) * 3000)

		buffer.writei16(pcm, sampleIndex * 4, sample)
		buffer.writei16(pcm, sampleIndex * 4 + 2, sample)
	end

	return pcm
end

local function startPlayback(player: audio.Player, source: audio.Source): Playback
	local playback: Playback = {}

	stdPolyfills.task.spawn(function()
		playback.result = player:playAsync(source):await()
	end)

	return playback
end

local function finished(stub: discordStub.DiscordStub, playback: Playback): boolean
	return stub.clock:waitFor(function()
		return playback.result
	end, WAIT_SECONDS)
end

local function failureOf(playback: Playback): string
	return if playback.result and playback.result:isErr() then tostring(playback.result:unwrapErr()) else "no error"
end

local function payloadOf(voiceServer: discordStub.VoiceServer, packet: buffer): string
	local crypto = voice.rtp.new()

	crypto.secretKey = voiceServer.secretKey
	crypto.encryptionMode = voiceServer.selectedMode

	local decrypted = crypto:decryptRtp(packet, {}, {})

	return if decrypted then string.sub(buffer.tostring(decrypted), RTP_HEADER_SIZE + 1) else "undecryptable"
end

local function sequenceOf(packet: buffer): number
	return buffer.readu8(packet, 2) * 256 + buffer.readu8(packet, 3)
end

local function speakingValues(voiceServer: discordStub.VoiceServer): string
	local values = {}

	for _, record in voiceServer.received do
		if record.opcode == SPEAKING_OPCODE then
			table.insert(values, tostring(record.payload.d.speaking))
		end
	end

	return table.concat(values, ",")
end

local function speakingReaches(stub: discordStub.DiscordStub, voiceServer: discordStub.VoiceServer, values: string)
	return stub.clock:waitFor(function()
		return speakingValues(voiceServer) == values
	end, WAIT_SECONDS)
end

local function recordSends(connection: voice.Connection): { string }
	local calls = {}
	local recorded = connection :: any
	local setSpeakingAsync = connection.setSpeakingAsync
	local sendOpusAsync = connection.sendOpusAsync

	recorded.setSpeakingAsync = function(self: voice.Connection, speakingFlags: number)
		table.insert(calls, `speaking {speakingFlags}`)

		return setSpeakingAsync(self, speakingFlags)
	end
	recorded.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer)
		table.insert(calls, if buffer.tostring(audioFrame) == SILENCE then "silence" else "packet")

		return sendOpusAsync(self, audioFrame)
	end

	return calls
end

local function captureLines(player: audio.Player): { string }
	local lines = {}

	player.logger:setLogLevel("Debug")
	player.logger:setSink(function(line: string)
		table.insert(lines, line)
	end)

	return lines
end

local function countLines(lines: { string }, text: string): number
	local count = 0

	for _, line in lines do
		if string.find(line, text, 1, true) then
			count += 1
		end
	end

	return count
end

local function raises(callback: () -> ...any, text: string): boolean
	local ran, failure = pcall(callback)
	local found = not ran and string.find(tostring(failure), text, 1, true)

	return if found then true else false
end

local function playWithSilenceHook(player: audio.Player, source: audio.Source, onSilence: () -> ()): Playback
	local connection = player.connection
	local wrapped = connection :: any
	local sendOpusAsync = connection.sendOpusAsync

	wrapped.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer)
		if buffer.tostring(audioFrame) == SILENCE then
			onSilence()
		end

		return sendOpusAsync(self, audioFrame)
	end

	return startPlayback(player, source)
end

local function sourceWhoseDestroyRaises(): audio.Source
	local source = audio.fromOpus(opusPackets(2))
	local breakable = source :: any

	breakable.destroy = function()
		error("destroy broke", 0)
	end

	return source
end

type World = { manager: websocket.Manager?, connection: voice.Connection? }
type Playback = { result: any }

return function()
	test.suite("Audio player", function()
		test.case("Speaking, the packets, five silence frames and Speaking 0 go out in that order", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local calls = recordSends(connection)
				local player = audio.player.new(connection)
				local packets = voiceServer.udpServer.packets
				local packetsBefore = #packets
				local reads = 0
				local spokeFirst = false
				local playback = startPlayback(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 1 then
							spokeFirst = voiceServer:waitForOp(SPEAKING_OPCODE, WAIT_SECONDS)
						end

						return if reads <= 10 then buffer.fromstring(PACKET) else nil
					end)
				)

				check.is_true(finished(stub, playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.is_true(spokeFirst)
				check.equal(
					table.concat(calls, ","),
					`speaking 1,{string.rep("packet,", 10)}{string.rep("silence,", 5)}speaking 0`
				)
				check.is_true(stub.clock:waitFor(function()
					return #packets >= packetsBefore + 15
				end, WAIT_SECONDS))
				check.equal(#packets, packetsBefore + 15)

				for index = packetsBefore + 2, packetsBefore + 15 do
					check.equal(sequenceOf(packets[index]), (sequenceOf(packets[index - 1]) + 1) % 65536)
				end

				for index = packetsBefore + 11, packetsBefore + 15 do
					check.equal(payloadOf(voiceServer, packets[index]), SILENCE)
				end

				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
			end)
		end)

		test.case("PCM goes out as Opus that decodes to 20 ms frames", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local packets = voiceServer.udpServer.packets
				local packetsBefore = #packets
				local playback = startPlayback(audio.player.new(connection), audio.fromPCM(tone(5 * FRAME_BYTES)))
				local decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)

				check.is_true(finished(stub, playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.is_true(stub.clock:waitFor(function()
					return #packets >= packetsBefore + 10
				end, WAIT_SECONDS))
				check.equal(#packets, packetsBefore + 10)
				check.equal(
					buffer.len(decoder:decode(buffer.fromstring(payloadOf(voiceServer, packets[packetsBefore + 1])))),
					FRAME_BYTES
				)
				decoder:destroy()
			end)
		end)

		test.case("stop mid-stream ends with the silence tail and Speaking 0 and resolves stopped", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local calls = recordSends(connection)
				local player = audio.player.new(connection)
				local reads = 0
				local playback = startPlayback(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 3 then
							player:stop()
						end

						return buffer.fromstring(PACKET)
					end)
				)

				check.is_true(finished(stub, playback))
				check.equal(playback.result:unwrapOk(), "stopped")
				check.equal(
					table.concat(calls, ","),
					`speaking 1,{string.rep("packet,", 3)}{string.rep("silence,", 5)}speaking 0`
				)
				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
				check.is_false(player.playing)
			end)
		end)

		test.case("stop on an idle player logs at debug, and a later playback plays in full", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local player = audio.player.new(joinedConnection(stub, gateway, world))
				local lines = captureLines(player)

				player:stop()

				local playback = startPlayback(player, audio.fromOpus(opusPackets(4)))

				check.is_true(finished(stub, playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(countLines(lines, "stop with nothing playing"), 1)
				check.equal(player.packetsSent, 4)
				check.equal(player.silenceFramesSent, 5)
			end)
		end)

		test.case("a second playAsync on a playing player fails and leaves the first alone", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local player = audio.player.new(joinedConnection(stub, gateway, world))
				local rejected = audio.fromOpus(opusPackets(2))
				local first = startPlayback(player, audio.fromOpus(opusPackets(20)))
				local second = startPlayback(player, rejected)

				check.is_true(finished(stub, second))
				check.equal(
					failureOf(second),
					"audio player is already playing; await the previous playAsync future first"
				)
				check.is_true(finished(stub, first))
				check.equal(first.result:unwrapOk(), "finished")
				check.equal(player.packetsSent, 20)

				local replayed = startPlayback(player, rejected)

				check.is_true(finished(stub, replayed))
				check.equal(replayed.result:unwrapOk(), "finished")
				check.equal(player.packetsSent, 2)
			end)
		end)

		test.case("a second player on the same connection fails, and a source plays only once", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player = audio.player.new(connection)
				local source = audio.fromOpus(opusPackets(10))
				local first = startPlayback(player, source)
				local other = startPlayback(audio.player.new(connection), audio.fromOpus(opusPackets(1)))

				check.is_true(finished(stub, other))
				check.equal(failureOf(other), "another audio player is playing on this voice connection")
				check.is_true(finished(stub, first))
				check.equal(first.result:unwrapOk(), "finished")

				local again = startPlayback(player, source)

				check.is_true(finished(stub, again))
				check.equal(failureOf(again), "audio source has already been played")
			end)
		end)

		test.case("each playback sends Speaking 1 before its first packet, on the same session too", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local calls = recordSends(connection)
				local player = audio.player.new(connection)
				local first = startPlayback(player, audio.fromOpus(opusPackets(2)))

				check.is_true(finished(stub, first))

				local second = startPlayback(player, audio.fromOpus(opusPackets(2)))

				check.is_true(finished(stub, second))
				check.equal(second.result:unwrapOk(), "finished")
				check.equal(calls[1 + 2 + 5 + 1 + 1], "speaking 1")
				check.equal(calls[1 + 2 + 5 + 1 + 2], "packet")
				check.is_true(speakingReaches(stub, voiceServer, "1,0,1,0"))
			end)
		end)

		test.case("a never-joined or destroyed connection fails at once", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				world.manager = connectManager(stub, gateway.url)
				world.connection = newConnection(world.manager :: websocket.Manager)

				local idle = startPlayback(
					audio.player.new(world.connection :: voice.Connection),
					audio.fromOpus(opusPackets(1))
				)
				local destroyed = newConnection(world.manager :: websocket.Manager)

				destroyed:destroy()

				local closed = startPlayback(audio.player.new(destroyed), audio.fromOpus(opusPackets(1)))

				check.is_true(finished(stub, idle))
				check.equal(failureOf(idle), "voice connection was never joined")
				check.is_true(finished(stub, closed))
				check.equal(failureOf(closed), "voice connection closed: the voice connection was destroyed")
			end)
		end)

		test.case("a source that raises gets the silence tail, then fails the playback", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local calls = recordSends(connection)
				local player = audio.player.new(connection)
				local reads = 0
				local playback = startPlayback(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 4 then
							error("the decoder broke", 0)
						end

						return buffer.fromstring(PACKET)
					end)
				)

				check.is_true(finished(stub, playback))
				check.equal(failureOf(playback), "audio source failed: the decoder broke")
				check.equal(
					table.concat(calls, ","),
					`speaking 1,{string.rep("packet,", 3)}{string.rep("silence,", 5)}speaking 0`
				)
				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
				check.is_false(player.playing)
			end)
		end)

		test.case("a packet that is not Opus fails the playback", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local player = audio.player.new(joinedConnection(stub, gateway, world))
				local playback = startPlayback(player, audio.fromOpus({ buffer.fromstring(PACKET), buffer.create(0) }))

				check.is_true(finished(stub, playback))
				check.not_nil(
					(string.find(failureOf(playback), "invalid Opus packet from the audio source: ", 1, true))
				)
				check.not_nil((string.find(failureOf(playback), "invalid Opus packet: it is empty", 1, true)))
				check.equal(player.packetsSent, 1)
			end)
		end)

		test.case("a failed send fails the playback with its error after a best-effort tail", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player = audio.player.new(connection)
				local lines = captureLines(player)
				local reads = 0
				local playback = startPlayback(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 3 then
							(connection.udp.udpSocket :: stdPolyfills.UdpSocket).close()
						end

						return buffer.fromstring(PACKET)
					end)
				)

				check.is_true(finished(stub, playback))
				check.not_nil((string.find(failureOf(playback), "audio send failed: socket closed", 1, true)))
				check.equal(countLines(lines, "silence tail after an error failed: "), 5)
				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
			end)
		end)

		test.case("a tail send that fails after the source ended resolves Err with the send's error", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player = audio.player.new(connection)
				local reads = 0
				local playback = startPlayback(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 3 then
							(connection.udp.udpSocket :: stdPolyfills.UdpSocket).close()

							return
						end

						return buffer.fromstring(PACKET)
					end)
				)

				check.is_true(finished(stub, playback))
				check.not_nil((string.find(failureOf(playback), "audio send failed: socket closed", 1, true)))
				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
				check.is_false(player.playing)
			end)
		end)

		test.case("every tail failure after the first is logged at warn", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player = audio.player.new(connection, { silenceFrames = 2 })
				local lines = captureLines(player)
				local reads = 0
				local playback = startPlayback(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 2 then
							(connection.udp.udpSocket :: stdPolyfills.UdpSocket).close()

							return
						end

						return buffer.fromstring(PACKET)
					end)
				)

				check.is_true(finished(stub, playback))
				check.not_nil((string.find(failureOf(playback), "audio send failed: socket closed", 1, true)))
				check.equal(countLines(lines, "silence tail failed: "), 1)
				check.not_nil((string.find(lines[#lines - 1] or "", "silence tail failed: ", 1, true)))
			end)
		end)

		test.case("stop during the silence tail changes nothing and the playback still finishes", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local calls = recordSends(connection)
				local player = audio.player.new(connection)
				local lines = captureLines(player)
				local stopped = false
				local playback = playWithSilenceHook(player, audio.fromOpus(opusPackets(2)), function()
					if not stopped then
						stopped = true
						player:stop()
					end
				end)

				check.is_true(finished(stub, playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(
					table.concat(calls, ","),
					`speaking 1,{string.rep("packet,", 2)}{string.rep("silence,", 5)}speaking 0`
				)
				check.equal(countLines(lines, "stop during the silence tail; the tail completes"), 1)
				check.is_false(player.stopRequested)
				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
			end)
		end)

		test.case("stop during the tail after an error is ignored too", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player = audio.player.new(connection)
				local lines = captureLines(player)
				local reads = 0
				local playback = playWithSilenceHook(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 2 then
							error("the decoder broke", 0)
						end

						return buffer.fromstring(PACKET)
					end),
					function()
						player:stop()
					end
				)

				check.is_true(finished(stub, playback))
				check.equal(failureOf(playback), "audio source failed: the decoder broke")
				check.equal(countLines(lines, "stop during the silence tail; the tail completes"), 5)
				check.is_false(player.stopRequested)
			end)
		end)

		test.case("a source whose destroy raises keeps the playback result and frees the player", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local player = audio.player.new(joinedConnection(stub, gateway, world))
				local lines = captureLines(player)
				local playback = startPlayback(player, sourceWhoseDestroyRaises())

				check.is_true(finished(stub, playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.is_false(player.playing)
				check.equal(countLines(lines, "destroying the audio source failed: destroy broke"), 1)
				check.equal(countLines(lines, "playback finished after 2 packets and 5 silence frames"), 1)

				local next = startPlayback(player, audio.fromOpus(opusPackets(3)))

				check.is_true(finished(stub, next))
				check.equal(next.result:unwrapOk(), "finished")
				check.equal(player.packetsSent, 3)
			end)
		end)

		test.case("a log sink that raises on playback started fails the playback and frees the player", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local player = audio.player.new(joinedConnection(stub, gateway, world), { logLevel = "Debug" })
				local raised = false

				player.logger:setSink(function(line: string)
					if not raised and string.find(line, "playback started", 1, true) then
						raised = true
						error("the sink broke", 0)
					end
				end)

				local playback = startPlayback(player, audio.fromOpus(opusPackets(2)))

				check.is_true(finished(stub, playback))
				check.equal(failureOf(playback), "the sink broke")
				check.is_false(player.playing)

				local second = startPlayback(player, audio.fromOpus(opusPackets(3)))

				check.is_true(finished(stub, second))
				check.equal(second.result:unwrapOk(), "finished")
				check.equal(player.packetsSent, 3)
			end)
		end)

		test.case("new raises for a missing connection and invalid options", function()
			local connection = ({} :: any) :: voice.Connection

			check.is_true(raises(function()
				audio.player.new(nil :: any)
			end, "audio.player.new needs a voice connection"))
			check.is_true(raises(function()
				audio.player.new(connection, { speakingFlags = 0 })
			end, "speakingFlags must not be 0"))
			check.is_true(raises(function()
				audio.player.new(connection, { silenceFrames = -1 })
			end, "silenceFrames must not be negative"))
			check.is_true(raises(function()
				audio.player.new(connection, { mediaWaitSeconds = -1 })
			end, "mediaWaitSeconds must not be negative"))
		end)
	end)
end
