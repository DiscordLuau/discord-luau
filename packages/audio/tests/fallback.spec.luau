local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local voice = require("../luau_packages/voice")
local websocket = require("../luau_packages/websocket")

local audio = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local GUILD_ID = "10"
local CHANNEL_ID = "20"
local USER_ID = "1"
local SILENCE = "\248\255\254"
local HEARTBEAT_MILLISECONDS = 1000
local JOIN_SECONDS = 60
local PLAY_SECONDS = 30
local POLL_SECONDS = 0.01
local MAX_PACKETS = 1000
local LARGE_CHUNK_BYTES = 64 * 1024
local SMALL_CHUNK_BYTES = 1024
local CAF_CHUNK_BYTES = 4096
local FREE_BOX_BYTES = 1024 * 1024
local CAP_BEFORE_FAILURE_BYTES = 32 * 1024
local CAP_DURING_FALLBACK_BYTES = 256 * 1024
local MAX_SAME_TICK_READS = 2
local CAP_FAILURE =
	"audio source failed: could not open audio: this file must be complete before it plays and is larger than 128 MiB"

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio whole-file fallback", function() end)
	end
end

local function waitUntil(predicate: () -> boolean, seconds: number): boolean
	local deadline = os.clock() + seconds

	while not predicate() do
		if os.clock() >= deadline then
			return false
		end

		stdPolyfills.task.wait(POLL_SECONDS)
	end

	return true
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function indexLastM4a(): string
	local bytes = readFixture("tone.m4a")
	local indexAt = (string.find(bytes, "moov", 1, true) :: number) - 4
	local freeBox = buffer.create(FREE_BOX_BYTES + 8)

	buffer.writeu32(freeBox, 0, bit32.byteswap(buffer.len(freeBox)))
	buffer.writestring(freeBox, 4, "free")

	return string.sub(bytes, 1, indexAt) .. buffer.tostring(freeBox) .. string.sub(bytes, indexAt + 1)
end

local function expectedPackets(bytes: string): number
	local source = audio.fromEncoded(bytes)
	local packets = 0

	for _ = 1, MAX_PACKETS do
		if not source:read() then
			break
		end

		packets += 1
	end

	source:destroy()

	return packets
end

local function chunkedReader(bytes: string, chunkBytes: number, feedOf: () -> audio.StreamFeed?): Reader
	local reader = { reads = 0, fallbackReads = {} } :: Reader
	local offset = 1

	reader.read = function(): string?
		local feed = feedOf()

		reader.reads += 1

		if feed and feed.fallingBack then
			table.insert(reader.fallbackReads, reader.ticks or 0)
		end

		if offset > #bytes then
			return
		end

		local chunk = string.sub(bytes, offset, offset + chunkBytes - 1)

		offset += chunkBytes

		return chunk
	end

	return reader
end

local function longestSameTickRun(ticks: { number }): number
	local longest = 0
	local run = 0
	local previous = -1

	for _, tick in ticks do
		run = if tick == previous then run + 1 else 1
		previous = tick
		longest = math.max(longest, run)
	end

	return longest
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
		end, JOIN_SECONDS),
		"the gateway never became ready"
	)

	return manager
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

local function recordEvents(world: World, connection: voice.Connection)
	local recorded = connection :: any
	local setSpeakingAsync = connection.setSpeakingAsync
	local sendOpusAsync = connection.sendOpusAsync

	recorded.setSpeakingAsync = function(self: voice.Connection, speakingFlags: number)
		table.insert(world.events, `speaking {speakingFlags}`)

		return setSpeakingAsync(self, speakingFlags)
	end
	recorded.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer)
		table.insert(world.events, if buffer.tostring(audioFrame) == SILENCE then "silence" else "packet")

		return sendOpusAsync(self, audioFrame)
	end
end

local function onStub(scenario: (world: World, player: audio.Player) -> ())
	local stub = discordStub.new({ clock = "real", polyfills = stdPolyfills })
	local gateway = stub:createWebsocketServer()
	local world: World = { events = {} }

	gateway.heartbeatIntervalMilliseconds = HEARTBEAT_MILLISECONDS
	stub:createVoiceServer({ heartbeatIntervalMilliseconds = HEARTBEAT_MILLISECONDS })

	check.equal(
		stub:runScenario(function()
			world.manager = connectManager(stub, gateway.url)
			world.connection = voice.connection.new({
				shard = (world.manager :: websocket.Manager).shards[1],
				guildId = GUILD_ID,
				channelId = CHANNEL_ID,
				userId = USER_ID,
				logLevel = "Error",
			})

			local connection = world.connection :: voice.Connection

			assert(connection:joinAsync(JOIN_SECONDS):await():isOk(), "the join failed")
			recordEvents(world, connection)
			scenario(world, audio.player.new(connection))
		end, function()
			teardown(world)
		end),
		nil
	)
end

local function play(player: audio.Player, source: audio.Source): Playback
	local playback: Playback = {}

	stdPolyfills.task.spawn(function()
		playback.result = player:playAsync(source):await()
	end)

	return playback
end

local function finished(playback: Playback): boolean
	return waitUntil(function()
		return if playback.result then true else false
	end, PLAY_SECONDS)
end

local function failureOf(playback: Playback): string
	return if playback.result and playback.result:isErr() then tostring(playback.result:unwrapErr()) else "no error"
end

local function summary(events: { string }): string
	local runs = {}
	local kind = ""
	local count = 0

	for _, event in events do
		if event ~= kind and count > 0 then
			table.insert(runs, if count == 1 then kind else `{kind} x{count}`)
			count = 0
		end

		kind = event
		count += 1
	end

	if count > 0 then
		table.insert(runs, if count == 1 then kind else `{kind} x{count}`)
	end

	return table.concat(runs, ", ")
end

local function streamOf(
	bytes: string,
	chunkBytes: number,
	options: audio.StreamOptions?,
	maxRetainedBytes: number?
): (audio.Source, Reader)
	local source: audio.Source? = nil
	local reader = chunkedReader(bytes, chunkBytes, function(): audio.StreamFeed?
		return if source then source.feed else nil
	end)
	local built = audio.fromStream(reader.read, options)
	local feed = built.feed :: audio.StreamFeed

	source = built
	feed.maxRetainedBytes = maxRetainedBytes or feed.maxRetainedBytes

	return built, reader
end

type Reader = { read: () -> string?, reads: number, ticks: number?, fallbackReads: { number } }
type World = { manager: websocket.Manager?, connection: voice.Connection?, events: { string } }
type Playback = { result: any }

return function()
	test.suite("Audio whole-file fallback", function()
		test.case("an M4A over 1 MiB with its index at the end plays whole, and the kept bytes go", function()
			local m4a = indexLastM4a()
			local packets = expectedPackets(m4a)

			onStub(function(world, player)
				local source = streamOf(m4a, LARGE_CHUNK_BYTES, { bufferSeconds = 0.2 })
				local feed = source.feed :: audio.StreamFeed
				local playback = play(player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.greater(#m4a, FREE_BOX_BYTES)
				check.equal(summary(world.events), `speaking 1, packet x{packets}, silence x5, speaking 0`)
				check.equal(feed.retained, nil)
				check.is_false(feed.fallingBack)
			end)
		end)

		test.case("a CAF, which fails only once all its bytes are in, plays whole", function()
			local caf = readFixture("tone.caf")
			local packets = expectedPackets(caf)

			onStub(function(world, player)
				local source = streamOf(caf, CAF_CHUNK_BYTES, { bufferSeconds = 0.2 })
				local playback = play(player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), `speaking 1, packet x{packets}, silence x5, speaking 0`)
			end)
		end)

		test.case("past the cap, the fallback is off and the stream fails with the 128 MiB message", function()
			local m4a = indexLastM4a()

			onStub(function(world, player)
				local beforeSource, beforeReader = streamOf(m4a, LARGE_CHUNK_BYTES, nil, CAP_BEFORE_FAILURE_BYTES)
				local duringSource, duringReader = streamOf(m4a, LARGE_CHUNK_BYTES, nil, CAP_DURING_FALLBACK_BYTES)
				local beforePlayback = play(player, beforeSource)

				check.is_true(finished(beforePlayback))
				check.equal(failureOf(beforePlayback), CAP_FAILURE)
				check.is_false((beforeSource.feed :: audio.StreamFeed).fallbackEnabled)
				check.lesser(beforeReader.reads, #m4a // LARGE_CHUNK_BYTES)

				local duringPlayback = play(player, duringSource)

				check.is_true(finished(duringPlayback))
				check.equal(failureOf(duringPlayback), CAP_FAILURE)
				check.lesser_eq(duringReader.reads, CAP_DURING_FALLBACK_BYTES // LARGE_CHUNK_BYTES + 2)
				check.equal(#world.events, 0)
			end)
		end)

		test.case("the fallback yields after every read, even when the stream never yields", function()
			local m4a = indexLastM4a()
			local packets = expectedPackets(m4a)

			onStub(function(world, player)
				local source, reader = streamOf(m4a, SMALL_CHUNK_BYTES, { bufferSeconds = 0.2 })
				local ticking = true
				local playback = play(player, source)

				reader.ticks = 0
				stdPolyfills.task.spawn(function()
					while ticking do
						reader.ticks = (reader.ticks :: number) + 1
						stdPolyfills.task.wait()
					end
				end)

				check.is_true(finished(playback))

				ticking = false

				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), `speaking 1, packet x{packets}, silence x5, speaking 0`)
				check.greater(#reader.fallbackReads, FREE_BOX_BYTES // SMALL_CHUNK_BYTES // 2)
				check.lesser_eq(longestSameTickRun(reader.fallbackReads), MAX_SAME_TICK_READS)
			end)
		end)
	end)
end
