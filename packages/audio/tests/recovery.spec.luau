local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local future = require("../luau_packages/future")
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
local SPEAKING_OPCODE = 5
local VOICE_SERVER_CRASHED = 4015
local SESSION_NO_LONGER_VALID = 4006
local DESTROYED = "voice connection closed: the voice connection was destroyed"
local MEDIA_TIMEOUT = "DAVE media was not ready after"
local MEDIA_TIMEOUT_LINE =
	"DAVE media was not ready after 2s (timed out waiting for DAVE media readiness); playing anyway, as silence until it is"
local HELD_UPGRADE_SECONDS = 30
local HELD_REJOIN_SECONDS = 8
local WAIT_SECONDS = 1200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio recovery", function() end)
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

local function newConnection(stub: discordStub.DiscordStub, gateway: any, world: World): voice.Connection
	world.manager = connectManager(stub, gateway.url)
	world.connection = voice.connection.new({
		shard = (world.manager :: websocket.Manager).shards[1],
		guildId = GUILD_ID,
		channelId = CHANNEL_ID,
		userId = USER_ID,
		logLevel = "Error",
	})

	return world.connection :: voice.Connection
end

local function joinedConnection(stub: discordStub.DiscordStub, gateway: any, world: World): voice.Connection
	local connection = newConnection(stub, gateway, world)

	assert(connection:joinAsync(WAIT_SECONDS):await():isOk(), "the join failed")

	return connection
end

local function joiningConnection(stub: discordStub.DiscordStub, gateway: any, world: World): voice.Connection
	local connection = newConnection(stub, gateway, world)

	stdPolyfills.task.spawn(function()
		connection:joinAsync(WAIT_SECONDS):await()
	end)

	assert(
		stub.clock:waitFor(function()
			return connection.status ~= "idle"
		end, WAIT_SECONDS),
		"the join never started"
	)

	return connection
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

local function debugPlayer(connection: voice.Connection, mediaWaitSeconds: number?): (audio.Player, { string })
	local player = audio.player.new(connection, { mediaWaitSeconds = mediaWaitSeconds, logLevel = "Debug" })
	local lines = {}

	player.logger:setSink(function(line: string)
		table.insert(lines, line)
	end)

	return player, lines
end

local function startPlayback(player: audio.Player, source: audio.Source): Playback
	local playback: Playback = {}

	stdPolyfills.task.spawn(function()
		playback.result = player:playAsync(source):await()
	end)

	return playback
end

local function resolvesWithin(stub: discordStub.DiscordStub, playback: Playback, seconds: number): boolean
	return stub.clock:waitFor(function()
		return playback.result
	end, seconds)
end

local function failureOf(playback: Playback): string
	return if playback.result and playback.result:isErr() then tostring(playback.result:unwrapErr()) else "no error"
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

local function logged(stub: discordStub.DiscordStub, lines: { string }, text: string): boolean
	return stub.clock:waitFor(function()
		return countLines(lines, text) > 0
	end, WAIT_SECONDS)
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

local function speakingCallTimes(stub: discordStub.DiscordStub, connection: voice.Connection): { number }
	local times = {}
	local recorded = connection :: any
	local setSpeakingAsync = connection.setSpeakingAsync

	recorded.setSpeakingAsync = function(self: voice.Connection, speakingFlags: number)
		table.insert(times, stub.clock:now())

		return setSpeakingAsync(self, speakingFlags)
	end

	return times
end

local function speakingReaches(stub: discordStub.DiscordStub, voiceServer: discordStub.VoiceServer, values: string)
	return stub.clock:waitFor(function()
		return speakingValues(voiceServer) == values
	end, WAIT_SECONDS)
end

local function payloadOf(voiceServer: discordStub.VoiceServer, packet: buffer): string
	local crypto = voice.rtp.new()

	crypto.secretKey = voiceServer.secretKey
	crypto.encryptionMode = voiceServer.selectedMode

	local decrypted = crypto:decryptRtp(packet, {}, {})

	return if decrypted then string.sub(buffer.tostring(decrypted), RTP_HEADER_SIZE + 1) else "undecryptable"
end

local function joinOps(gateway: any, channelId: string): number
	local count = 0

	for _, record in gateway:receivedOps(4) do
		if (record.payload.d or {}).channel_id == channelId then
			count += 1
		end
	end

	return count
end

local function closeAtRead(voiceServer: discordStub.VoiceServer, code: number, reads: { number }): () -> buffer?
	return function(): buffer?
		reads[1] += 1

		if reads[1] == 10 then
			voiceServer:close(code)
		end

		return if reads[1] <= 50 then buffer.fromstring(PACKET) else nil
	end
end

local function dropSessionAtSend(
	stub: discordStub.DiscordStub,
	connection: voice.Connection,
	voiceServer: discordStub.VoiceServer,
	sends: { number }
)
	local recorded = connection :: any
	local sendOpusAsync = connection.sendOpusAsync

	recorded.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer): any
		sends[1] += 1

		if sends[1] ~= 10 then
			return sendOpusAsync(self, audioFrame)
		end

		voiceServer:close(SESSION_NO_LONGER_VALID)

		return future.Future.new(function()
			stub.clock:waitFor(function()
				return connection.status ~= "ready"
			end, WAIT_SECONDS)
			error(`audio send failed: the voice session dropped`, 0)
		end)
	end
end

type World = { manager: websocket.Manager?, connection: voice.Connection? }
type Playback = { result: any }

return function()
	test.suite("Audio recovery", function()
		test.case("stop in the readiness wait ends the playback at once with nothing sent", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			voiceServer.upgradeDelaySeconds = HELD_UPGRADE_SECONDS

			run(stub, world, function()
				local connection = joiningConnection(stub, gateway, world)
				local player, lines = debugPlayer(connection)
				local playback = startPlayback(player, audio.fromOpus(opusPackets(5)))

				check.is_true(logged(stub, lines, "waiting for the voice connection"))
				player:stop()
				check.is_true(resolvesWithin(stub, playback, 1))
				check.equal(playback.result:unwrapOk(), "stopped")
				check.is_true(connection.status ~= "ready")
				check.is_true(stub.clock:waitFor(function()
					return connection.status == "ready"
				end, WAIT_SECONDS))
				check.equal(speakingValues(voiceServer), "")
				check.equal(#voiceServer.udpServer.packets, 0)
			end)
		end)

		test.case("a close in the readiness wait fails the playback at once", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			voiceServer.upgradeDelaySeconds = HELD_UPGRADE_SECONDS

			run(stub, world, function()
				local connection = joiningConnection(stub, gateway, world)
				local player, lines = debugPlayer(connection)
				local playback = startPlayback(player, audio.fromOpus(opusPackets(5)))

				check.is_true(logged(stub, lines, "waiting for the voice connection"))
				connection:destroy()
				check.is_true(resolvesWithin(stub, playback, 1))
				check.equal(failureOf(playback), DESTROYED)
				check.equal(speakingValues(voiceServer), "")
			end)
		end)

		test.case("stop during the DAVE media wait takes effect when the wait ends, with nothing sent", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local player, lines = debugPlayer(joinedConnection(stub, gateway, world), 2)
				local playback = startPlayback(player, audio.fromOpus(opusPackets(5)))

				check.is_true(logged(stub, lines, "waiting up to 2s for DAVE media readiness"))
				player:stop()
				check.falsy(playback.result)
				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "stopped")
				check.equal(speakingValues(voiceServer), "")
				check.equal(#voiceServer.udpServer.packets, 0)
				check.equal(countLines(lines, MEDIA_TIMEOUT), 0)
			end)
		end)

		test.case("a close during the DAVE media wait fails the playback at once", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player, lines = debugPlayer(connection, 30)
				local playback = startPlayback(player, audio.fromOpus(opusPackets(5)))

				check.is_true(logged(stub, lines, "waiting up to 30s for DAVE media readiness"))
				connection:destroy()
				check.is_true(resolvesWithin(stub, playback, 1))
				check.equal(failureOf(playback), DESTROYED)
				check.equal(speakingValues(voiceServer), "")
				check.equal(countLines(lines, MEDIA_TIMEOUT), 0)
				check.equal(
					countLines(lines, "not speaking: a stop came or the voice session changed during the media wait"),
					1
				)
			end)
		end)

		test.case("a session that drops during a DAVE media wait that times out logs no info line", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player, lines = debugPlayer(connection, 2)
				local playback = startPlayback(player, audio.fromOpus(opusPackets(5)))

				check.is_true(logged(stub, lines, "waiting up to 2s for DAVE media readiness"))
				voiceServer.upgradeDelaySeconds = HELD_REJOIN_SECONDS
				voiceServer:close(SESSION_NO_LONGER_VALID)
				check.is_true(logged(stub, lines, "not speaking: a stop came or the voice session changed"))
				check.is_true(connection.status ~= "ready")
				check.equal(countLines(lines, MEDIA_TIMEOUT), 0)
				check.equal(
					countLines(lines, "the media wait ended on a session change, a close or a stop: timed out"),
					1
				)
				player:stop()
				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "stopped")
				check.equal(speakingValues(voiceServer), "")
				check.equal(countLines(lines, MEDIA_TIMEOUT), 0)
			end)
		end)

		test.case("alone under DAVE, Speaking waits out the media wait and the packets go out as silence", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player, lines = debugPlayer(connection, 2)
				local spokenAt = speakingCallTimes(stub, connection)
				local packets = voiceServer.udpServer.packets
				local startedAt = stub.clock:now()
				local playback = startPlayback(player, audio.fromOpus(opusPackets(5)))

				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "finished")
				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
				check.greater_eq(spokenAt[1] - startedAt, 2)
				check.lesser(spokenAt[1] - startedAt, 10)
				check.equal(countLines(lines, MEDIA_TIMEOUT_LINE), 1)
				check.is_true(stub.clock:waitFor(function()
					return #packets >= 10
				end, WAIT_SECONDS))
				check.equal(#packets, 10)

				for _, packet in packets do
					check.equal(payloadOf(voiceServer, packet), SILENCE)
				end
			end)
		end)

		test.case("media readiness during the wait lets Speaking out at once, and silence skips DAVE", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player, lines = debugPlayer(connection, 30)
				local spokenAt = speakingCallTimes(stub, connection)
				local packets = voiceServer.udpServer.packets
				local playback = startPlayback(player, audio.fromOpus({}))

				check.is_true(logged(stub, lines, "waiting up to 30s for DAVE media readiness"))

				local readyAt = stub.clock:now()

				connection.dave.selfRatchetApplied = true
				connection.dave:updateMediaReady()
				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "finished")
				check.is_true(speakingReaches(stub, voiceServer, "1,0"))
				check.lesser(spokenAt[1] - readyAt, 1)
				check.is_true(stub.clock:waitFor(function()
					return #packets >= 5
				end, WAIT_SECONDS))
				check.equal(#packets, 5)

				for _, packet in packets do
					check.equal(payloadOf(voiceServer, packet), SILENCE)
				end

				check.equal(countLines(lines, MEDIA_TIMEOUT), 0)
			end)
		end)

		test.case("a resume sends Speaking again and the playback plays to its end", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local player, lines = debugPlayer(joinedConnection(stub, gateway, world))
				local reads = { 0 }
				local playback =
					startPlayback(player, audio.fromOpus(closeAtRead(voiceServer, VOICE_SERVER_CRASHED, reads)))

				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(reads[1], 51)
				check.is_true(speakingReaches(stub, voiceServer, "1,1,0"))
				check.equal(countLines(lines, MEDIA_TIMEOUT), 0)
				check.not_nil(table.find(voiceServer:receivedOps(), 7))
			end)
		end)

		test.case("a rejoin sends Speaking again and the playback ends with the silence tail", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local player = debugPlayer(joinedConnection(stub, gateway, world))
				local packets = voiceServer.udpServer.packets
				local reads = { 0 }
				local playback =
					startPlayback(player, audio.fromOpus(closeAtRead(voiceServer, SESSION_NO_LONGER_VALID, reads)))

				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(joinOps(gateway, CHANNEL_ID), 2)
				check.is_true(speakingReaches(stub, voiceServer, "1,1,0"))
				check.is_true(stub.clock:waitFor(function()
					return #packets >= player.packetsSent + 5
				end, WAIT_SECONDS))

				for index = #packets - 4, #packets do
					check.equal(payloadOf(voiceServer, packets[index]), SILENCE)
				end
			end)
		end)

		test.case("a send lost to a rejoin is logged at debug, not sent again, and the playback plays on", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player, lines = debugPlayer(connection)
				local sends = { 0 }
				local reads = 0

				dropSessionAtSend(stub, connection, voiceServer, sends)

				local playback = startPlayback(
					player,
					audio.fromOpus(function(): buffer?
						reads += 1

						return if reads <= 50 then buffer.fromstring(PACKET) else nil
					end)
				)

				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(countLines(lines, "a send was lost to a voice reconnect"), 1)
				check.equal(reads, 51)
				check.equal(player.packetsSent, 49)
				check.equal(sends[1], 50 + 5)
				check.equal(joinOps(gateway, CHANNEL_ID), 2)
				check.is_true(speakingReaches(stub, voiceServer, "1,1,0"))
			end)
		end)

		test.case("stop during a rejoin ends the playback before the new session, with nothing sent on it", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local player = debugPlayer(connection)
				local packets = voiceServer.udpServer.packets
				local playback = startPlayback(player, audio.fromOpus(opusPackets(1000)))

				check.is_true(stub.clock:waitFor(function()
					return player.packetsSent >= 5
				end, WAIT_SECONDS))
				voiceServer.upgradeDelaySeconds = HELD_REJOIN_SECONDS
				voiceServer:close(SESSION_NO_LONGER_VALID)
				check.is_true(stub.clock:waitFor(function()
					return connection.status ~= "ready"
				end, WAIT_SECONDS))
				player:stop()
				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(playback.result:unwrapOk(), "stopped")
				check.is_true(connection.status ~= "ready")

				local packetsAtStop = #packets

				check.is_true(stub.clock:waitFor(function()
					return connection.status == "ready"
				end, WAIT_SECONDS))
				check.equal(speakingValues(voiceServer), "1")
				check.equal(#packets, packetsAtStop)
				check.equal(player.silenceFramesSent, 0)
			end)
		end)

		test.case("a close mid-play fails the playback with the close and sends nothing after it", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer()
			local world: World = {}

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local waits = 0
				local player = audio.player.new(connection, {
					clock = {
						nowMillis = function(): number
							return stdPolyfills.datetime.now().unixTimestampMillis
						end,
						wait = function(seconds: number): number
							waits += 1

							if waits == 5 then
								connection:destroy()
							end

							return stdPolyfills.task.wait(seconds)
						end,
					},
				})
				local playback = startPlayback(player, audio.fromOpus(opusPackets(1000)))

				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(failureOf(playback), DESTROYED)
				check.equal(player.packetsSent, 5)
				check.equal(player.silenceFramesSent, 0)
				check.equal(speakingValues(voiceServer), "1")
			end)
		end)

		test.case("a destroy during a send fails the playback with the close, not the send's error", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}

			stub:createVoiceServer()

			run(stub, world, function()
				local connection = joinedConnection(stub, gateway, world)
				local recorded = connection :: any
				local sendOpusAsync = connection.sendOpusAsync
				local sendFailures: { string } = {}
				local reads = 0
				local playback = startPlayback(
					audio.player.new(connection),
					audio.fromOpus(function(): buffer?
						reads += 1

						if reads == 3 then
							connection:destroy()
						end

						return buffer.fromstring(PACKET)
					end)
				)

				recorded.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer)
					return sendOpusAsync(self, audioFrame):inspectErr(function(failure: string)
						table.insert(sendFailures, failure)
					end)
				end

				check.is_true(resolvesWithin(stub, playback, WAIT_SECONDS))
				check.equal(failureOf(playback), DESTROYED)
				check.equal(#sendFailures, 1)
				check.not_nil(
					(string.find(sendFailures[1] or "", "cannot send audio: UDP socket is not open", 1, true))
				)
			end)
		end)
	end)
end
