local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local opus = require("../luau_packages/opus")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local symphonia = require("../luau_packages/symphonia")
local voice = require("../luau_packages/voice")
local websocket = require("../luau_packages/websocket")

local audio = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local GUILD_ID = "10"
local CHANNEL_ID = "20"
local USER_ID = "1"
local SILENCE = "\248\255\254"
local SAMPLE_RATE = 48000
local PACKET_FRAMES = 960
local WAV_HEADER_BYTES = 44
local WAV_FRAME_BYTES = 4
local TONE_BLOCK_FRAMES = 4800
local TONE_AMPLITUDE = 16384
local HEARTBEAT_MILLISECONDS = 1000
local JOIN_SECONDS = 60
local PLAY_SECONDS = 30
local GATE_SECONDS = 10
local POLL_SECONDS = 0.01
local SETTLE_SECONDS = 0.2
local SLOW_LOAD_SECONDS = 0.3
local SLOW_OPEN_SECONDS = 0.2
local OPEN_DECISION_SECONDS = 0.5
local START_SLACK_SECONDS = 0.25
local STOP_SLACK_SECONDS = 0.25
local QUIET_SAMPLE = 1000
local LONGEST_QUIET_RUN = 100
local PEAK_FLOOR = 1000
local SILENT_PEAK = 100
local SETTLED_PACKETS_AFTER_CHANGE = 3
local MAX_PUSH_BYTES = 65536
local ENDLESS_CHUNK_FRAMES = 16384
local MAX_ENDLESS_READS = 3000
local MAX_PACKETS = 200
local OGG_CAPTURE = "OggS"
local OGG_SEGMENT_COUNT_OFFSET = 26
local OGG_HEADER_BYTES = 27
local OGG_CHECKSUM_OFFSET = 22
local OGG_CRC_POLYNOMIAL = 0x04C11DB7
local OGG_FIRST_AUDIO_PAGE = 3
local JUNK = string.rep("this is not audio at all. ", 160)
local STALLED_SHAPE = "speaking 1, packets, silence x5, speaking 0, speaking 1, packets, silence x5, speaking 0"
local READ_FAILURE = "network down"
local CHAINED_FAILURE = "could not decode audio: the stream changed its parameters mid-file, which is not supported"
local NOT_AUDIO_REASON =
	"not a supported audio file: unsupported feature: core (probe): no suitable format reader found"
local LOAD_FAILURE = "the library broke"
local FINISH_FAILURE = "finish broke"
local FAILED_PREFIX = "audio source failed: "
local OPEN_PREFIX = "audio source failed: could not open audio: "
local BAD_BUFFER_SECONDS: { any } = { 0.05, 4.5, 0 / 0, "1", true }
local BAD_VOLUMES: { any } = { -0.5, 4.5, "1" }

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio stream sources", function() end)
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

local function slice(whole: buffer, offset: number, length: number): buffer
	local part = buffer.create(length)

	buffer.copy(part, 0, whole, offset, length)

	return part
end

local function sineWav(frames: number, unknownSize: boolean?): buffer
	local dataBytes = frames * WAV_FRAME_BYTES
	local wav = buffer.create(WAV_HEADER_BYTES + dataBytes)
	local blockBytes = TONE_BLOCK_FRAMES * WAV_FRAME_BYTES

	buffer.writestring(wav, 0, "RIFF")
	buffer.writeu32(wav, 4, if unknownSize then 0xFFFFFFFF else WAV_HEADER_BYTES - 8 + dataBytes)
	buffer.writestring(wav, 8, "WAVE")
	buffer.writestring(wav, 12, "fmt ")
	buffer.writeu32(wav, 16, 16)
	buffer.writeu16(wav, 20, 1)
	buffer.writeu16(wav, 22, 2)
	buffer.writeu32(wav, 24, SAMPLE_RATE)
	buffer.writeu32(wav, 28, SAMPLE_RATE * WAV_FRAME_BYTES)
	buffer.writeu16(wav, 32, WAV_FRAME_BYTES)
	buffer.writeu16(wav, 34, 16)
	buffer.writestring(wav, 36, "data")
	buffer.writeu32(wav, 40, if unknownSize then 0xFFFFFFFF else dataBytes)

	for frame = 0, math.min(frames, TONE_BLOCK_FRAMES) - 1 do
		local sample = math.round(math.sin(frame * 440 * 2 * math.pi / SAMPLE_RATE) * TONE_AMPLITUDE)
		local offset = WAV_HEADER_BYTES + frame * WAV_FRAME_BYTES

		buffer.writei16(wav, offset, sample)
		buffer.writei16(wav, offset + 2, sample)
	end

	for blockOffset = blockBytes, dataBytes - 1, blockBytes do
		buffer.copy(
			wav,
			WAV_HEADER_BYTES + blockOffset,
			wav,
			WAV_HEADER_BYTES,
			math.min(blockBytes, dataBytes - blockOffset)
		)
	end

	return wav
end

local function wavPieces(frames: number, cutFrames: { number }, unknownSize: boolean?): { buffer }
	local wav = sineWav(frames, unknownSize)
	local pieces = {}
	local start = 0

	for _, cutFrame in cutFrames do
		local finish = WAV_HEADER_BYTES + cutFrame * WAV_FRAME_BYTES

		table.insert(pieces, slice(wav, start, finish - start))
		start = finish
	end

	table.insert(pieces, slice(wav, start, buffer.len(wav) - start))

	return pieces
end

local function scriptedReader(steps: { Step }): Reader
	local reader = { reads = 0, blocked = false } :: Reader
	local stepIndex = 1

	reader.read = function(): (buffer | string)?
		reader.reads += 1

		while steps[stepIndex] do
			local step = steps[stepIndex]

			stepIndex += 1

			if step.chunk then
				reader.firstChunkAt = reader.firstChunkAt or os.clock()

				return step.chunk
			end

			if step.raise then
				error(step.raise, 0)
			end

			reader.blocked = true

			if step.waitUntil then
				waitUntil(step.waitUntil, step.waitSeconds or GATE_SECONDS)
			else
				stdPolyfills.task.wait(step.waitSeconds or 0)
			end

			reader.blocked = false
		end

		reader.endedAt = reader.endedAt or os.clock()

		return
	end

	return reader
end

local function endlessReader(first: buffer | string, repeated: buffer | string): Reader
	local reader = { reads = 0, blocked = false } :: Reader

	reader.read = function(): (buffer | string)?
		reader.reads += 1

		if reader.reads > MAX_ENDLESS_READS then
			return
		end

		return if reader.reads == 1 then first else repeated
	end

	return reader
end

local function endlessWavReader(): Reader
	local block = sineWav(ENDLESS_CHUNK_FRAMES)

	return endlessReader(sineWav(0, true), slice(block, WAV_HEADER_BYTES, buffer.len(block) - WAV_HEADER_BYTES))
end

local function oggCrcTable(): { number }
	local crcTable = {}

	for index = 0, 255 do
		local value = bit32.lshift(index, 24)

		for _ = 1, 8 do
			value = if bit32.btest(value, 0x80000000)
				then bit32.bxor(bit32.lshift(value, 1), OGG_CRC_POLYNOMIAL)
				else bit32.lshift(value, 1)
		end

		crcTable[index] = value
	end

	return crcTable
end

local function oggCrc(crcTable: { number }, page: buffer, offset: number, length: number): number
	local crc = 0

	for index = offset, offset + length - 1 do
		crc = bit32.bxor(bit32.lshift(crc, 8), crcTable[bit32.bxor(bit32.rshift(crc, 24), buffer.readu8(page, index))])
	end

	return crc
end

local function opusWithInvalidPacket(): buffer
	local bytes = buffer.fromstring(stdPolyfills.fileSystem.readFile(`{FIXTURES}/tone.opus`))
	local crcTable = oggCrcTable()
	local offset = 0

	for _ = 1, OGG_FIRST_AUDIO_PAGE - 1 do
		local segments = buffer.readu8(bytes, offset + OGG_SEGMENT_COUNT_OFFSET)
		local bodyBytes = 0

		for segment = 0, segments - 1 do
			bodyBytes += buffer.readu8(bytes, offset + OGG_HEADER_BYTES + segment)
		end

		offset += OGG_HEADER_BYTES + segments + bodyBytes
	end

	local segments = buffer.readu8(bytes, offset + OGG_SEGMENT_COUNT_OFFSET)
	local body = offset + OGG_HEADER_BYTES + segments
	local pageBytes = OGG_HEADER_BYTES + segments

	for segment = 0, segments - 1 do
		pageBytes += buffer.readu8(bytes, offset + OGG_HEADER_BYTES + segment)
	end

	assert(buffer.readstring(bytes, offset, 4) == OGG_CAPTURE, "tone.opus does not have the expected page layout")
	buffer.writeu8(bytes, body, bit32.bor(buffer.readu8(bytes, body), 3))
	buffer.writeu8(bytes, body + 1, 0)
	buffer.writeu32(bytes, offset + OGG_CHECKSUM_OFFSET, 0)
	buffer.writeu32(bytes, offset + OGG_CHECKSUM_OFFSET, oggCrc(crcTable, bytes, offset, pageBytes))

	return bytes
end

local function openCount(): number
	return symphonia.load().symphonia_open_count()
end

local function workerCount(): number
	return symphonia.load().symphonia_worker_count()
end

local function captureLines(target: { logger: any }): { string }
	local lines = {}

	target.logger:setLogLevel("Debug")
	target.logger:setSink(function(line: string)
		table.insert(lines, line)
	end)

	return lines
end

local function countLines(lines: { string }, text: string): number
	local count = 0

	for _, line in lines do
		count += if string.find(line, text, 1, true) then 1 else 0
	end

	return count
end

local function raisedMessage(work: () -> ...any): string?
	local succeeded, failure = pcall(work)

	return if succeeded then nil else tostring(failure)
end

local function raises(work: () -> ...any, text: string): boolean
	local found = string.find(raisedMessage(work) or "", text, 1, true)

	return if found then true else false
end

local function pumpDead(source: audio.Source): boolean
	return waitUntil(function()
		local feed = source.feed
		local pump = if feed then feed.pump else nil

		return if pump then coroutine.status(pump) == "dead" else false
	end, GATE_SECONDS)
end

local function pollUntilReady(source: audio.Source): boolean
	return waitUntil(function()
		source:poll()

		return not source.starved
	end, GATE_SECONDS)
end

local function readPackets(source: audio.Source, count: number): { buffer }
	local packets = {}

	for _ = 1, count do
		local packet = source:read()

		if not packet then
			break
		end

		table.insert(packets, packet)
	end

	return packets
end

local function packetPeaks(packets: { buffer }): { number }
	local decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)
	local peaks = {}

	for _, packet in packets do
		local pcm = decoder:decode(packet)
		local peak = 0

		for offset = 0, buffer.len(pcm) - 2, 2 do
			peak = math.max(peak, math.abs(buffer.readi16(pcm, offset)))
		end

		table.insert(peaks, peak)
	end

	decoder:destroy()

	return peaks
end

local function decoderPackets(bytes: string): { buffer }
	local decoder = symphonia.decoder.fromBuffer(bytes)
	local packets = {}
	local packet = decoder:readPacket()

	while packet and #packets < MAX_PACKETS do
		table.insert(packets, packet)
		packet = decoder:readPacket()
	end

	decoder:destroy()

	return packets
end

local function packetsText(packets: { buffer }): string
	local texts = {}

	for _, packet in packets do
		table.insert(texts, buffer.tostring(packet))
	end

	return table.concat(texts, "|")
end

local function maxOf(values: { number }, first: number): number
	local result = 0

	for index = first, #values do
		result = math.max(result, values[index])
	end

	return result
end

local function longestQuietRun(packets: { buffer }): number
	local decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)
	local longest = 0
	local run = 0

	for packetIndex, packet in packets do
		local pcm = decoder:decode(packet)

		for offset = 0, buffer.len(pcm) - WAV_FRAME_BYTES, WAV_FRAME_BYTES do
			local quiet = math.abs(buffer.readi16(pcm, offset)) < QUIET_SAMPLE

			run = if quiet and packetIndex > 1 then run + 1 else 0
			longest = math.max(longest, run)
		end
	end

	decoder:destroy()

	return longest
end

local function instrumentStreams(work: (pushes: PushLog) -> ())
	local originalFromStream = symphonia.decoder.fromStream
	local pushes: PushLog = { sizes = {}, refused = 0 }
	local ran, failure = pcall(function()
		symphonia.decoder.fromStream = function(options: symphonia.DecoderOptions?): symphonia.Decoder
			local decoder = originalFromStream(options)
			local push = decoder.push

			decoder.push = function(self: symphonia.Decoder, chunk: buffer | string): boolean
				local accepted = push(self, chunk)

				table.insert(pushes.sizes, buffer.len(chunk :: buffer))
				pushes.refused += if accepted then 0 else 1

				return accepted
			end

			return decoder
		end

		work(pushes)
	end)

	symphonia.decoder.fromStream = originalFromStream

	assert(ran, failure)
end

local function withBrokenFinish(work: () -> ())
	local originalFromStream = symphonia.decoder.fromStream
	local ran, failure = pcall(function()
		symphonia.decoder.fromStream = function(options: symphonia.DecoderOptions?): symphonia.Decoder
			local decoder = originalFromStream(options)

			decoder.finish = function()
				error(FINISH_FAILURE, 0)
			end

			return decoder
		end

		work()
	end)

	symphonia.decoder.fromStream = originalFromStream

	assert(ran, failure)
end

local function withSlowOpen(delaySeconds: number, work: () -> ())
	local originalFromStream = symphonia.decoder.fromStream
	local ran, failure = pcall(function()
		symphonia.decoder.fromStream = function(options: symphonia.DecoderOptions?): symphonia.Decoder
			local decoder = originalFromStream(options)
			local originalRefresh = decoder.refresh
			local originalFinish = decoder.finish
			local finishedAt: number? = nil

			decoder.finish = function(self: symphonia.Decoder)
				finishedAt = os.clock()
				originalFinish(self)
			end

			decoder.refresh = function(self: symphonia.Decoder)
				local finishTime = finishedAt

				if finishTime and os.clock() - finishTime >= delaySeconds then
					originalRefresh(self)
				end
			end

			return decoder
		end

		work()
	end)

	symphonia.decoder.fromStream = originalFromStream

	assert(ran, failure)
end

local function drainWithin(source: audio.Source, seconds: number): (number, string?)
	local packets = 0
	local failure: string? = nil

	waitUntil(function()
		local read, packet = pcall(source.read, source)
		local ended = if read then not packet and not source.starved else true

		failure = if read then nil else tostring(packet)
		packets += if read and packet then 1 else 0

		if read and not packet then
			source:poll()
		end

		return ended
	end, seconds)

	return packets, failure
end

local function withLibraryLoad(openLibrary: () -> symphonia.Lib, work: () -> ())
	local sys = symphonia.sys
	local loaded = symphonia.load()
	local originalOpenLibrary = sys.openLibrary
	local ran, failure = pcall(function()
		sys.library = nil
		sys.openLibrary = openLibrary
		work()
	end)

	sys.openLibrary = originalOpenLibrary
	sys.library = loaded
	sys.loading = false
	sys.waitingThreads = {}

	assert(ran, failure)
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

local function bufferedOf(world: World): number
	local source = world.source
	local feed = if source then source.feed else nil

	return if feed then feed.bufferedSeconds else 0
end

local function recordEvents(world: World, connection: voice.Connection)
	local recorded = connection :: any
	local setSpeakingAsync = connection.setSpeakingAsync
	local sendOpusAsync = connection.sendOpusAsync

	recorded.setSpeakingAsync = function(self: voice.Connection, speakingFlags: number)
		table.insert(world.events, {
			kind = `speaking {speakingFlags}`,
			at = os.clock(),
			buffered = bufferedOf(world),
			lineCount = #world.lines,
		})

		return setSpeakingAsync(self, speakingFlags)
	end
	recorded.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer)
		table.insert(world.events, {
			kind = if buffer.tostring(audioFrame) == SILENCE then "silence" else "packet",
			at = os.clock(),
			buffered = bufferedOf(world),
			lineCount = #world.lines,
			payload = audioFrame,
		})

		return sendOpusAsync(self, audioFrame)
	end
end

local function onStub(scenario: (world: World, player: audio.Player) -> ())
	local stub = discordStub.new({ clock = "real", polyfills = stdPolyfills })
	local gateway = stub:createWebsocketServer()
	local world: World = { events = {}, lines = {} }

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

local function play(world: World, player: audio.Player, source: audio.Source): Playback
	local playback: Playback = { startedAt = os.clock() }

	world.source = source
	stdPolyfills.task.spawn(function()
		playback.result = player:playAsync(source):await()
		playback.endedAt = os.clock()
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

local function summary(events: { Event }): string
	local runs = {}
	local kind = ""
	local count = 0

	for _, event in events do
		if event.kind ~= kind and count > 0 then
			table.insert(runs, if count == 1 then kind else `{kind} x{count}`)
			count = 0
		end

		kind = event.kind
		count += 1
	end

	if count > 0 then
		table.insert(runs, if count == 1 then kind else `{kind} x{count}`)
	end

	return table.concat(runs, ", ")
end

local function shape(events: { Event }): string
	local counted = string.gsub(summary(events), "packet x%d+", "packets")
	local collapsed = string.gsub(counted, "packet,", "packets,")

	return collapsed
end

local function dryFramesIntoPacket(lines: { string }): number
	local frames = 0

	for _, line in lines do
		local found = string.match(line, "ran dry (%d+) frames into a packet")

		frames = math.max(frames, tonumber(found) or 0)
	end

	return frames
end

local function eventsOf(events: { Event }, kind: string): { Event }
	local matching = {}

	for _, event in events do
		if event.kind == kind then
			table.insert(matching, event)
		end
	end

	return matching
end

local function seen(world: World, kind: string, count: number): () -> boolean
	return function()
		return #eventsOf(world.events, kind) >= count
	end
end

local function payloads(events: { Event }): { buffer }
	local packets = {}

	for _, event in eventsOf(events, "packet") do
		table.insert(packets, event.payload :: buffer)
	end

	return packets
end

local function resetsAfterResume(world: World): number
	local resumed = eventsOf(world.events, "speaking 1")[2]
	local packetsAfter = {}

	for _, event in eventsOf(world.events, "packet") do
		if resumed and event.at >= resumed.at then
			table.insert(packetsAfter, event)
		end
	end

	assert(resumed and packetsAfter[2], "the playback did not resume for two packets")

	return countLines(table.move(world.lines, resumed.lineCount + 1, packetsAfter[2].lineCount, 1, {}), "resetting")
end

type Step = {
	chunk: (buffer | string)?,
	waitSeconds: number?,
	waitUntil: (() -> boolean)?,
	raise: string?,
}
type Reader = {
	read: () -> (buffer | string)?,
	reads: number,
	blocked: boolean,
	firstChunkAt: number?,
	endedAt: number?,
}
type Event = { kind: string, at: number, buffered: number, lineCount: number, payload: buffer? }
type World = {
	manager: websocket.Manager?,
	connection: voice.Connection?,
	source: audio.Source?,
	events: { Event },
	lines: { string },
}
type Playback = { result: any, startedAt: number, endedAt: number? }
type PushLog = { sizes: { number }, refused: number }

return function()
	test.suite("Audio stream sources", function()
		test.case("fromStream only checks and records its options: it never reads, opens or spawns", function()
			local before = openCount()
			local reader = scriptedReader({ { chunk = sineWav(SAMPLE_RATE) } })
			local source = audio.fromStream(reader.read, { volume = 2, bitrate = 96000, bufferSeconds = 0.5 })
			local defaults = audio.fromStream(reader.read)
			local feed = source.feed :: audio.StreamFeed

			check.equal(reader.reads, 0)
			check.equal(openCount(), before)
			check.equal(source.volume, 2)
			check.equal(source.bitrate, 96000)
			check.equal(source.bufferSeconds, 0.5)
			check.is_true(source.starved)
			check.equal(feed.decoder, nil)
			check.equal(feed.pump, nil)
			check.equal(defaults.volume, 1)
			check.equal(defaults.bitrate, 128000)
			check.equal(defaults.bufferSeconds, 1)

			source:destroy()
			defaults:destroy()

			check.equal(reader.reads, 0)
			check.equal(openCount(), before)
		end)

		test.case("fromStream raises at the call for a bad reader or option", function()
			local read = scriptedReader({}).read

			check.is_true(raises(function()
				audio.fromStream("bytes" :: any)
			end, "audio.fromStream takes a function that returns the next chunk of the file's bytes"))

			for _, bufferSeconds in BAD_BUFFER_SECONDS do
				check.equal(
					raisedMessage(function()
						audio.fromStream(read, { bufferSeconds = bufferSeconds })
					end),
					"bufferSeconds must be a number from 0.1 to 4"
				)
			end

			for _, volume in BAD_VOLUMES do
				check.equal(
					raisedMessage(function()
						audio.fromStream(read, { volume = volume })
					end),
					"volume must be a number from 0 to 4"
				)
			end

			check.is_true(raises(function()
				audio.fromStream(read, { bitrate = 100 })
			end, "bitrate"))
			check.is_true(raises(function()
				audio.fromStream(read, { logLevel = "Bogus" :: any })
			end, "Invalid log level: Bogus"))
		end)

		test.case("no Speaking goes out before bufferSeconds of audio is buffered", function()
			local steps: { Step } = {}

			for _, piece in wavPieces(SAMPLE_RATE * 2, { 9600, 19200, 28800, 38400, 48000, 57600, 67200, 76800, 86400 }) do
				table.insert(steps, { chunk = piece })
				table.insert(steps, { waitSeconds = 0.2 })
			end

			onStub(function(world, player)
				local reader = scriptedReader(steps)
				local source = audio.fromStream(reader.read, { bufferSeconds = 1 })
				local playback = play(world, player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")

				local speaking = world.events[1]

				check.equal(speaking.kind, "speaking 1")
				check.greater_eq(speaking.buffered, 1)
				check.greater_eq(speaking.at - (reader.firstChunkAt :: number), 0.75)
				check.equal(summary(world.events), "speaking 1, packet x100, silence x5, speaking 0")
			end)
		end)

		test.case("a read blocked 3 s after its first chunk does not hold the start back", function()
			local released = false
			local pieces = wavPieces(SAMPLE_RATE * 2, { SAMPLE_RATE * 3 // 2 })

			onStub(function(world, player)
				local reader = scriptedReader({
					{ chunk = pieces[1] },
					{
						waitUntil = function()
							return released
						end,
						waitSeconds = 3,
					},
					{ chunk = pieces[2] },
				})
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.5 })
				local playback = play(world, player, source)

				check.is_true(waitUntil(seen(world, "packet", 1), GATE_SECONDS))

				local firstPacket = eventsOf(world.events, "packet")[1]

				check.lesser_eq(firstPacket.at - (reader.firstChunkAt :: number), 0.5 + START_SLACK_SECONDS)
				check.is_true(reader.blocked)

				player:stop()
				released = true

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "stopped")
				check.is_true(pumpDead(source))
			end)
		end)

		test.case("a producer that blocks mid-song does not pause playback while the decoder has output", function()
			local pieces = wavPieces(SAMPLE_RATE * 17 // 2, { SAMPLE_RATE * 8 })

			onStub(function(world, player)
				local reader = scriptedReader({
					{ chunk = pieces[1] },
					{ waitUntil = seen(world, "packet", 350), waitSeconds = GATE_SECONDS },
					{ chunk = pieces[2] },
				})
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.5 })
				local playback = play(world, player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), "speaking 1, packet x425, silence x5, speaking 0")
			end)
		end)

		test.case("input that runs dry mid-frame plays complete, with no silence inserted", function()
			local pieces = wavPieces(51 * PACKET_FRAMES, { 24500 })

			onStub(function(world, player)
				local reader = scriptedReader({
					{ chunk = pieces[1] },
					{ waitUntil = seen(world, "speaking 0", 1), waitSeconds = GATE_SECONDS },
					{ chunk = pieces[2] },
				})
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.2 })
				local lines = captureLines(source)
				local playback = play(world, player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(shape(world.events), STALLED_SHAPE)
				check.equal(#eventsOf(world.events, "packet"), 51)
				check.greater(dryFramesIntoPacket(lines), 0)
				check.lesser(longestQuietRun(payloads(world.events)), LONGEST_QUIET_RUN)
			end)
		end)

		test.case("a dry decoder with an empty queue waits, then plays to the true end", function()
			local pieces = wavPieces(SAMPLE_RATE // 2, {}, true)

			onStub(function(world, player)
				local before = openCount()
				local midSong = scriptedReader({
					{ chunk = pieces[1] },
					{ waitUntil = seen(world, "speaking 0", 1), waitSeconds = GATE_SECONDS },
				})
				local midSongSource = audio.fromStream(midSong.read, { bufferSeconds = 0.2 })
				local lines = captureLines(midSongSource)
				local midSongPlayback = play(world, player, midSongSource)

				check.is_true(finished(midSongPlayback))
				check.equal(midSongPlayback.result:unwrapOk(), "finished")
				check.equal(shape(world.events), STALLED_SHAPE)
				check.equal(#eventsOf(world.events, "packet"), 25)
				check.greater(dryFramesIntoPacket(lines), 0)

				table.clear(world.events)

				local short = scriptedReader({ { chunk = pieces[1] }, { waitSeconds = 0.3 } })
				local shortPlayback = play(world, player, audio.fromStream(short.read, { bufferSeconds = 1 }))

				check.is_true(finished(shortPlayback))
				check.equal(shortPlayback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), "speaking 1, packet x25, silence x5, speaking 0")
				check.greater(world.events[1].at, short.endedAt :: number)
				check.equal(openCount(), before)
			end)
		end)

		test.case("a short lead below bufferSeconds never pauses while data keeps coming", function()
			local cuts = { SAMPLE_RATE }

			for tenth = 1, 19 do
				table.insert(cuts, SAMPLE_RATE + tenth * SAMPLE_RATE // 10)
			end

			local pieces = wavPieces(SAMPLE_RATE * 3, cuts)
			local steps: { Step } = { { chunk = pieces[1] } }

			for pieceIndex = 2, #pieces do
				table.insert(steps, { waitSeconds = 0.1 })
				table.insert(steps, { chunk = pieces[pieceIndex] })
			end

			onStub(function(world, player)
				local reader = scriptedReader(steps)
				local source = audio.fromStream(reader.read, { bufferSeconds = 1 })
				local playback = play(world, player, source)
				local lowestLead = math.huge

				check.is_true(finished(playback))

				for index, event in eventsOf(world.events, "packet") do
					lowestLead = if index > 10 then math.min(lowestLead, event.buffered) else lowestLead
				end

				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), "speaking 1, packet x150, silence x5, speaking 0")
				check.lesser(lowestLead, 1)
			end)
		end)

		test.case("a stall sends the silence tail and Speaking 0, then Speaking 1 on a fresh schedule", function()
			local pieces = wavPieces(SAMPLE_RATE, { SAMPLE_RATE // 2 })

			onStub(function(world, player)
				local before = openCount()
				local reader = scriptedReader({
					{ chunk = pieces[1] },
					{ waitUntil = seen(world, "speaking 0", 1), waitSeconds = GATE_SECONDS },
					{ waitSeconds = SETTLE_SECONDS },
					{ chunk = pieces[2] },
				})

				world.lines = captureLines(player)

				local playback = play(world, player, audio.fromStream(reader.read, { bufferSeconds = 0.2 }))

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(shape(world.events), STALLED_SHAPE)
				check.equal(#eventsOf(world.events, "packet"), 50)
				check.equal(countLines(world.lines, "the audio stream is buffering; paused"), 2)
				check.equal(resetsAfterResume(world), 0)
				check.equal(openCount(), before)
			end)
		end)

		test.case("stop while a stream is starved ends the playback within 250 ms", function()
			local pieces = wavPieces(SAMPLE_RATE, { SAMPLE_RATE // 2 })

			onStub(function(world, player)
				local released = false
				local midSong = scriptedReader({
					{ chunk = pieces[1] },
					{
						waitUntil = function()
							return released
						end,
					},
				})
				local midSongSource = audio.fromStream(midSong.read, { bufferSeconds = 0.2 })
				local midSongPlayback = play(world, player, midSongSource)

				check.is_true(waitUntil(seen(world, "speaking 0", 1), GATE_SECONDS))
				stdPolyfills.task.wait(SETTLE_SECONDS)

				local stoppedAt = os.clock()

				player:stop()

				check.is_true(finished(midSongPlayback))
				check.equal(midSongPlayback.result:unwrapOk(), "stopped")
				check.lesser(midSongPlayback.endedAt :: number - stoppedAt, STOP_SLACK_SECONDS)
				check.equal(shape(world.events), "speaking 1, packets, silence x5, speaking 0")

				released = true

				check.is_true(pumpDead(midSongSource))
				table.clear(world.events)

				local silent = scriptedReader({
					{
						waitUntil = function()
							return released and false
						end,
						waitSeconds = 1,
					},
				})
				local silentSource = audio.fromStream(silent.read)
				local silentPlayback = play(world, player, silentSource)

				check.is_true(waitUntil(function()
					return silent.blocked
				end, GATE_SECONDS))

				local silentStoppedAt = os.clock()

				player:stop()

				check.is_true(finished(silentPlayback))
				check.equal(silentPlayback.result:unwrapOk(), "stopped")
				check.lesser(silentPlayback.endedAt :: number - silentStoppedAt, STOP_SLACK_SECONDS)
				check.equal(#world.events, 0)
				check.is_true(pumpDead(silentSource))
			end)
		end)

		test.case("setVolume on a stream is heard within 3 packets, and options.volume from the start", function()
			local wav = sineWav(SAMPLE_RATE * 2)
			local loud = audio.fromStream(scriptedReader({ { chunk = wav } }).read, { bufferSeconds = 1 })

			check.is_true(pollUntilReady(loud))

			local firstPackets = readPackets(loud, 5)

			loud:setVolume(0)

			local laterPeaks = packetPeaks(readPackets(loud, 20))

			check.equal(#firstPackets, 5)
			check.equal(#laterPeaks, 20)
			check.equal(loud.volume, 0)
			check.greater(maxOf(packetPeaks(firstPackets), 1), PEAK_FLOOR)
			check.lesser(maxOf(laterPeaks, SETTLED_PACKETS_AFTER_CHANGE), SILENT_PEAK)
			check.equal(
				raisedMessage(function()
					loud:setVolume(9)
				end),
				"volume must be a number from 0 to 4"
			)
			check.equal(loud.volume, 0)

			loud:destroy()

			local quiet = audio.fromStream(scriptedReader({ { chunk = wav } }).read, { volume = 0 })

			check.is_true(pollUntilReady(quiet))
			check.lesser(maxOf(packetPeaks(readPackets(quiet, 20)), 1), SILENT_PEAK)

			quiet:destroy()
		end)

		test.case("an unexpected error in the pump plays the queued audio, then fails the playback", function()
			local wav = sineWav(SAMPLE_RATE // 2, true)

			onStub(function(world, player)
				withBrokenFinish(function()
					local source = audio.fromStream(scriptedReader({ { chunk = wav } }).read, { bufferSeconds = 0.2 })
					local playback = play(world, player, source)

					check.is_true(finished(playback))
					check.equal(failureOf(playback), `{FAILED_PREFIX}the audio stream's pump failed: {FINISH_FAILURE}`)
					check.equal(shape(world.events), "speaking 1, packets, silence x5, speaking 0")
					check.is_true(pumpDead(source))
				end)
			end)
		end)

		test.case("a read that fails before the session has probed its bytes plays them once it opens", function()
			local wav = sineWav(SAMPLE_RATE // 2, true)

			withSlowOpen(SLOW_OPEN_SECONDS, function()
				local reader = scriptedReader({ { chunk = wav }, { raise = READ_FAILURE } })
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.2 })
				local packets, failure = drainWithin(source, GATE_SECONDS)

				check.equal(packets, 25)
				check.equal(failure, `audio stream read failed: {READ_FAILURE}`)
				check.is_true(pumpDead(source))
			end)
		end)

		test.case("a starved stream stays starved while its open is undecided, even with its output closed", function()
			local wav = sineWav(SAMPLE_RATE // 2, true)

			withSlowOpen(math.huge, function()
				local source = audio.fromStream(scriptedReader({ { chunk = wav } }).read)
				local feed = source.feed :: audio.StreamFeed

				check.is_true(waitUntil(function()
					source:poll()

					return feed.streamBytes > 0
				end, GATE_SECONDS))
				check.equal(source:read(), nil)
				check.is_true(source.starved)

				feed.outputClosed = true
				source:poll()

				check.is_false(feed:openDecided())
				check.is_false(feed:hasEnded())
				check.is_true(source.starved)
				check.is_false(source.ended)

				source:destroy()

				check.is_true(pumpDead(source))
			end)
		end)

		test.case("a read that fails before a session that never decides fails 500 ms later", function()
			local wav = sineWav(SAMPLE_RATE // 2, true)

			withSlowOpen(math.huge, function()
				local reader = scriptedReader({ { chunk = wav }, { raise = READ_FAILURE } })
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.2 })
				local startedAt = os.clock()
				local packets, failure = drainWithin(source, GATE_SECONDS)
				local elapsed = os.clock() - startedAt

				check.equal(packets, 0)
				check.equal(failure, `audio stream read failed: {READ_FAILURE}`)
				check.greater_eq(elapsed, OPEN_DECISION_SECONDS)
				check.lesser(elapsed, OPEN_DECISION_SECONDS + START_SLACK_SECONDS)
			end)
		end)

		test.case("a raising read fails the playback with its error, before and during the song", function()
			local pieces = wavPieces(SAMPLE_RATE, { SAMPLE_RATE // 2 })

			onStub(function(world, player)
				local atOnce = scriptedReader({ { raise = READ_FAILURE } })
				local atOnceSource = audio.fromStream(atOnce.read)
				local atOncePlayback = play(world, player, atOnceSource)

				check.is_true(finished(atOncePlayback))
				check.equal(failureOf(atOncePlayback), `{FAILED_PREFIX}audio stream read failed: {READ_FAILURE}`)
				check.equal(#world.events, 0)
				check.is_true(pumpDead(atOnceSource))

				local midSong = scriptedReader({
					{ chunk = pieces[1] },
					{ waitUntil = seen(world, "packet", 10), waitSeconds = GATE_SECONDS },
					{ raise = READ_FAILURE },
				})
				local midSongSource = audio.fromStream(midSong.read, { bufferSeconds = 0.2 })
				local midSongPlayback = play(world, player, midSongSource)

				check.is_true(finished(midSongPlayback))
				check.equal(failureOf(midSongPlayback), `{FAILED_PREFIX}audio stream read failed: {READ_FAILURE}`)
				check.equal(summary(world.events), "speaking 1, packet x25, silence x5, speaking 0")
				check.is_true(pumpDead(midSongSource))
			end)
		end)

		test.case("a decode failure after the stream opened plays the queued audio, then fails", function()
			local opusFile = stdPolyfills.fileSystem.readFile(`{FIXTURES}/tone.opus`)

			onStub(function(world, player)
				local reader = scriptedReader({ { chunk = opusFile .. opusFile } })
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.2 })
				local playback = play(world, player, source)

				check.is_true(finished(playback))
				check.equal(failureOf(playback), `{FAILED_PREFIX}{CHAINED_FAILURE}`)
				check.equal(summary(world.events), "speaking 1, packet x26, silence x5, speaking 0")
				check.is_true(pumpDead(source))
			end)
		end)

		test.case("an Opus stream passes its packets through as stored, through a stall, to the end", function()
			local webm = stdPolyfills.fileSystem.readFile(`{FIXTURES}/tone.webm`)
			local cut = #webm * 2 // 3
			local expected = decoderPackets(webm)

			onStub(function(world, player)
				local reader = scriptedReader({
					{ chunk = string.sub(webm, 1, cut) },
					{ waitUntil = seen(world, "speaking 0", 1), waitSeconds = GATE_SECONDS },
					{ chunk = string.sub(webm, cut + 1) },
				})
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.2 })
				local playback = play(world, player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(source.format, "opus")
				check.equal(shape(world.events), STALLED_SHAPE)
				check.equal(#expected, 26)
				check.equal(packetsText(payloads(world.events)), packetsText(expected))
				check.is_true(pumpDead(source))
			end)
		end)

		test.case("destroy while a stream is starved or buffering ends the playback without speaking", function()
			local pieces = wavPieces(SAMPLE_RATE, { SAMPLE_RATE // 2 })

			onStub(function(world, player)
				local released = false
				local stalled = scriptedReader({
					{ chunk = pieces[1] },
					{
						waitUntil = function()
							return released
						end,
					},
				})
				local stalledSource = audio.fromStream(stalled.read, { bufferSeconds = 0.2 })
				local buffering = scriptedReader({
					{
						waitUntil = function()
							return released
						end,
					},
				})
				local bufferingSource = audio.fromStream(buffering.read)

				world.lines = captureLines(player)

				local stalledPlayback = play(world, player, stalledSource)

				check.is_true(waitUntil(seen(world, "speaking 0", 1), GATE_SECONDS))
				stdPolyfills.task.wait(SETTLE_SECONDS)
				stalledSource:destroy()

				check.is_true(finished(stalledPlayback))
				check.equal(stalledPlayback.result:unwrapOk(), "finished")
				check.equal(shape(world.events), "speaking 1, packets, silence x5, speaking 0")

				table.clear(world.events)

				local bufferingPlayback = play(world, player, bufferingSource)

				check.is_true(waitUntil(function()
					return buffering.blocked
				end, GATE_SECONDS))
				bufferingSource:destroy()

				check.is_true(finished(bufferingPlayback))
				check.equal(bufferingPlayback.result:unwrapOk(), "finished")
				check.equal(#world.events, 0)
				check.equal(countLines(world.lines, "ended before Speaking went out"), 2)

				released = true

				check.is_true(pumpDead(stalledSource))
				check.is_true(pumpDead(bufferingSource))
			end)
		end)

		test.case("destroy mid-read stops the pump without a warning and frees the session", function()
			local openBefore = openCount()
			local workersBefore = workerCount()
			local released = false
			local reader = scriptedReader({
				{ chunk = sineWav(SAMPLE_RATE // 2, true) },
				{
					waitUntil = function()
						return released
					end,
				},
				{ chunk = sineWav(SAMPLE_RATE // 2) },
			})
			local source = audio.fromStream(reader.read)
			local lines = captureLines(source)

			source:poll()

			check.is_true(waitUntil(function()
				return reader.blocked
			end, GATE_SECONDS))
			check.equal(openCount(), openBefore + 1)

			source:destroy()
			released = true

			check.is_true(pumpDead(source))
			check.equal(openCount(), openBefore)
			check.is_true(waitUntil(function()
				return workerCount() == workersBefore
			end, GATE_SECONDS))
			check.equal(countLines(lines, "WARN"), 0)
			check.greater(countLines(lines, "the pump stopped"), 0)
			check.equal(reader.reads, 2)

			source:destroy()

			check.equal(countLines(lines, "audio source already ended; nothing to free"), 1)
		end)

		test.case("destroy during the full-input wait stops the pump without a warning", function()
			instrumentStreams(function(pushes)
				local openBefore = openCount()
				local workersBefore = workerCount()
				local reader = endlessWavReader()
				local source = audio.fromStream(reader.read)
				local lines = captureLines(source)

				source:poll()

				check.is_true(waitUntil(function()
					return pushes.refused > 0
				end, GATE_SECONDS))

				local readsAtDestroy = reader.reads

				source:destroy()

				check.is_true(pumpDead(source))
				check.equal(reader.reads, readsAtDestroy)
				check.equal(openCount(), openBefore)
				check.is_true(waitUntil(function()
					return workerCount() == workersBefore
				end, GATE_SECONDS))
				check.equal(countLines(lines, "WARN"), 0)
				check.greater(countLines(lines, "the pump stopped"), 0)
				check.lesser(reader.reads, MAX_ENDLESS_READS)
			end)
		end)

		test.case("a 10 MiB chunk is pushed in slices of at most 64 KiB and starts at once", function()
			local wav = sineWav(10 * 1024 * 1024 // WAV_FRAME_BYTES)

			instrumentStreams(function(pushes)
				onStub(function(world, player)
					local reader = scriptedReader({ { chunk = wav } })
					local source = audio.fromStream(reader.read, { bufferSeconds = 0.5 })
					local playback = play(world, player, source)

					check.is_true(waitUntil(seen(world, "packet", 10), GATE_SECONDS))
					check.lesser_eq(
						eventsOf(world.events, "packet")[1].at - (reader.firstChunkAt :: number),
						0.5 + START_SLACK_SECONDS
					)

					player:stop()

					check.is_true(finished(playback))
					check.equal(playback.result:unwrapOk(), "stopped")
					check.is_true(pumpDead(source))
					check.greater(#pushes.sizes, 1)
					check.lesser_eq(maxOf(pushes.sizes, 1), MAX_PUSH_BYTES)
				end)
			end)
		end)

		test.case("a session that ends early stops reading and plays what it decoded", function()
			local wav = buffer.tostring(sineWav(SAMPLE_RATE))

			onStub(function(world, player)
				local reader = endlessReader(wav, JUNK)
				local source = audio.fromStream(reader.read, { bufferSeconds = 0.3 })
				local lines = captureLines(source)
				local playback = play(world, player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), "speaking 1, packet x50, silence x5, speaking 0")
				check.is_true(pumpDead(source))
				check.lesser(reader.reads, MAX_PACKETS)
				check.greater(countLines(lines, "the audio stream session ended"), 0)
			end)
		end)

		test.case("a second playAsync while the first poll loads the library is refused", function()
			local loaded = symphonia.load()

			onStub(function(world, player)
				local first = audio.fromStream(scriptedReader({ { chunk = sineWav(SAMPLE_RATE // 2) } }).read)
				local second = audio.fromStream(scriptedReader({ { chunk = sineWav(SAMPLE_RATE // 2) } }).read)

				withLibraryLoad(function(): symphonia.Lib
					stdPolyfills.task.wait(SLOW_LOAD_SECONDS)

					return loaded
				end, function()
					local playback = play(world, player, first)

					check.is_true(waitUntil(function()
						return symphonia.sys.loading
					end, GATE_SECONDS))
					check.equal(
						tostring(player:playAsync(second):await():unwrapErr()),
						"audio player is already playing; await the previous playAsync future first"
					)
					check.equal(
						tostring(
							audio.player.new(world.connection :: voice.Connection):playAsync(first):await():unwrapErr()
						),
						"another audio player is playing on this voice connection"
					)
					check.is_true(symphonia.sys.loading)
					check.is_true(finished(playback))
					check.equal(playback.result:unwrapOk(), "finished")
					check.equal(summary(world.events), "speaking 1, packet x25, silence x5, speaking 0")
					check.is_false(second.played)
				end)

				second:destroy()
			end)
		end)

		test.case("a stream session that cannot open fails the playback through read and sends no Speaking", function()
			onStub(function(world, player)
				local reader = scriptedReader({ { chunk = sineWav(SAMPLE_RATE // 2) } })
				local source = audio.fromStream(reader.read)

				withLibraryLoad(function(): symphonia.Lib
					error(LOAD_FAILURE, 0)
				end, function()
					local playback = play(world, player, source)

					check.is_true(finished(playback))
					check.equal(failureOf(playback), `{FAILED_PREFIX}{LOAD_FAILURE}`)
				end)

				check.equal(#world.events, 0)
				check.equal(reader.reads, 0)
				check.equal((source.feed :: audio.StreamFeed).pump, nil)
			end)
		end)

		test.case("a stream that is not audio fails at once and sends no Speaking", function()
			onStub(function(world, player)
				local reader = endlessReader(JUNK, JUNK)
				local source = audio.fromStream(reader.read)
				local playback = play(world, player, source)

				check.is_true(finished(playback))
				check.equal(failureOf(playback), `{OPEN_PREFIX}{NOT_AUDIO_REASON}`)
				check.equal(#world.events, 0)
				check.is_true(pumpDead(source))
				check.lesser(reader.reads, MAX_ENDLESS_READS)
			end)
		end)

		test.case("an invalid Opus packet in an Opus stream fails the playback", function()
			onStub(function(world, player)
				local source = audio.fromStream(scriptedReader({ { chunk = opusWithInvalidPacket() } }).read)
				local playback = play(world, player, source)

				check.is_true(finished(playback))

				check.equal(
					failureOf(playback),
					`{FAILED_PREFIX}invalid Opus packet from the audio source: invalid Opus packet: code 3 with 0 frames`
				)
				check.equal(source.format, "opus")
				check.equal(#world.events, 0)
			end)
		end)

		test.case("a stream that ends before any bytes fails with its own message", function()
			onStub(function(world, player)
				for _, steps in { {}, { { chunk = "" }, { chunk = buffer.create(0) } } } :: { { Step } } do
					local source = audio.fromStream(scriptedReader(steps).read)
					local playback = play(world, player, source)

					check.is_true(finished(playback))
					check.equal(failureOf(playback), `{OPEN_PREFIX}the stream ended before any audio`)
					check.equal(#world.events, 0)
					check.is_true(pumpDead(source))
				end
			end)
		end)
	end)
end
