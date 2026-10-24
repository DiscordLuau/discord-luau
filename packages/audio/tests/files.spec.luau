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
local MAX_PACKETS = 500
local PEAK_FLOOR = 1000
local WAIT_SECONDS = 1200
local PLAY_WAIT_SECONDS = 30
local PATH_HINT = "takes the file's bytes as a buffer or string; for a path use audio.fromFile"
local OPUS_FILE_HINT =
	"audio.fromOpus takes an array of Opus packets or a function that returns the next one; for an .opus file use audio.fromOgg or audio.fromFile"
local DECODE_FAILURE = "could not decode audio: the file broke partway"
local SILK_FRAME_SIZES = { 480, 960, 1920, 2880 }
local HYBRID_FRAME_SIZES = { 480, 960 }
local CELT_FRAME_SIZES = { 120, 240, 480, 960 }

local NAMED_SOURCES: { NamedCase } = {
	{ name = "fromMP3", build = audio.fromMP3, file = "tone.mp3", format = "pcm", packets = 25, samples = 24000 },
	{ name = "fromMP3", build = audio.fromMP3, file = "tone.mp2", format = "pcm", packets = 27, samples = 25920 },
	{ name = "fromOgg", build = audio.fromOgg, file = "tone.ogg", format = "pcm", packets = 25, samples = 24000 },
	{ name = "fromOgg", build = audio.fromOgg, file = "tone.opus", format = "opus", packets = 26, samples = 24960 },
	{
		name = "fromOgg",
		build = audio.fromOgg,
		file = "tone-60ms.opus",
		format = "opus",
		packets = 9,
		samples = 25920,
	},
	{ name = "fromWAV", build = audio.fromWAV, file = "tone.wav", format = "pcm", packets = 25, samples = 24000 },
	{ name = "fromWAV", build = audio.fromWAV, file = "tone-mono.wav", format = "pcm", packets = 25, samples = 24000 },
	{ name = "fromWAV", build = audio.fromWAV, file = "tone-adpcm.wav", format = "pcm", packets = 25, samples = 24000 },
	{ name = "fromFLAC", build = audio.fromFLAC, file = "tone.flac", format = "pcm", packets = 25, samples = 24000 },
	{
		name = "fromFLAC",
		build = audio.fromFLAC,
		file = "layout-51.flac",
		format = "pcm",
		packets = 25,
		samples = 24000,
	},
	{ name = "fromAAC", build = audio.fromAAC, file = "tone.aac", format = "pcm", packets = 27, samples = 25920 },
	{ name = "fromM4A", build = audio.fromM4A, file = "tone.m4a", format = "pcm", packets = 27, samples = 25920 },
	{ name = "fromM4A", build = audio.fromM4A, file = "tone-alac.m4a", format = "pcm", packets = 25, samples = 24000 },
	{ name = "fromWebM", build = audio.fromWebM, file = "tone.webm", format = "opus", packets = 26, samples = 24960 },
	{
		name = "fromWebM",
		build = audio.fromWebM,
		file = "tone-vorbis.webm",
		format = "pcm",
		packets = 26,
		samples = 24960,
	},
	{
		name = "fromMKV",
		build = audio.fromMKV,
		file = "tone-vorbis.webm",
		format = "pcm",
		packets = 26,
		samples = 24960,
	},
	{ name = "fromAIFF", build = audio.fromAIFF, file = "tone.aiff", format = "pcm", packets = 26, samples = 24960 },
	{ name = "fromCAF", build = audio.fromCAF, file = "tone.caf", format = "pcm", packets = 25, samples = 24000 },
}

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio file sources", function() end)
	end
end

local function fixturePath(name: string): string
	return `{FIXTURES}/{name}`
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(fixturePath(name))
end

local function openCount(): number
	return symphonia.load().symphonia_open_count()
end

local function readAll(source: audio.Source): { buffer }
	local packets = {}
	local packet = source:read()

	while packet do
		if #packets >= MAX_PACKETS then
			error(`the source did not end within {MAX_PACKETS} packets`)
		end

		table.insert(packets, packet)
		packet = source:read()
	end

	return packets
end

local function readAllDecoderPackets(decoder: symphonia.Decoder): { buffer }
	local packets = {}
	local packet = decoder:readPacket()

	while packet do
		if #packets >= MAX_PACKETS then
			error(`the decoder did not end within {MAX_PACKETS} packets`)
		end

		table.insert(packets, packet)
		packet = decoder:readPacket()
	end

	return packets
end

local function opusSamples(packet: buffer): number
	local tableOfContents = buffer.readu8(packet, 0)
	local configuration = bit32.rshift(tableOfContents, 3)
	local frameCountCode = bit32.band(tableOfContents, 3)
	local frameSize = if configuration < 12
		then SILK_FRAME_SIZES[configuration % 4 + 1]
		elseif configuration < 16 then HYBRID_FRAME_SIZES[configuration % 2 + 1]
		else CELT_FRAME_SIZES[configuration % 4 + 1]
	local frameCount = if frameCountCode == 0
		then 1
		elseif frameCountCode == 3 then bit32.band(buffer.readu8(packet, 1), 0x3f)
		else 2

	return frameSize * frameCount
end

local function totalSamples(packets: { buffer }): number
	local samples = 0

	for _, packet in packets do
		samples += opusSamples(packet)
	end

	return samples
end

local function peakOf(packets: { buffer }): number
	local decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)
	local peak = 0

	for _, packet in packets do
		local pcm = decoder:decode(packet)

		for offset = 0, buffer.len(pcm) - 2, 2 do
			peak = math.max(peak, math.abs(buffer.readi16(pcm, offset)))
		end
	end

	decoder:destroy()

	return peak
end

local function checkSamePackets(actual: { buffer }, expected: { buffer })
	check.equal(#actual, #expected)

	for index, packet in expected do
		check.equal(buffer.tostring(actual[index] or buffer.create(0)), buffer.tostring(packet))
	end
end

local function captureLines(source: audio.Source): { string }
	local lines = {}

	source.logger:setLogLevel("Debug")
	source.logger:setSink(function(line: string)
		table.insert(lines, line)
	end)

	return lines
end

local function hasLine(lines: { string }, text: string): boolean
	for _, line in lines do
		if string.find(line, text, 1, true) then
			return true
		end
	end

	return false
end

local function raises(callback: () -> ...any, text: string): boolean
	local ran, failure = pcall(callback)
	local found = not ran and string.find(tostring(failure), text, 1, true)

	return if found then true else false
end

local function failingAfter(source: audio.Source, goodReads: number): audio.Source
	local iterator = source.iterator :: () -> buffer?
	local reads = 0

	source.iterator = function(): buffer?
		reads += 1

		if reads > goodReads then
			error(DECODE_FAILURE, 0)
		end

		return iterator()
	end

	return source
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

local function joinedConnection(stub: discordStub.DiscordStub, gateway: any, world: World): voice.Connection
	world.manager = connectManager(stub, gateway.url)
	world.connection = voice.connection.new({
		shard = (world.manager :: websocket.Manager).shards[1],
		guildId = GUILD_ID,
		channelId = CHANNEL_ID,
		userId = USER_ID,
		logLevel = "Error",
	})

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

local function startPlayback(player: audio.Player, source: audio.Source): Playback
	local playback: Playback = {}

	stdPolyfills.task.spawn(function()
		playback.result = player:playAsync(source):await()
	end)

	return playback
end

local function playOnStub(
	build: () -> audio.Source,
	onPlayed: (player: audio.Player, playback: Playback, before: number) -> ()
)
	local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
	local gateway = stub:createWebsocketServer()
	local world: World = {}

	stub:createVoiceServer()

	check.equal(
		stub:runScenario(function()
			local player = audio.player.new(joinedConnection(stub, gateway, world))
			local before = openCount()
			local source = build()

			captureLines(source)
			check.equal(openCount(), before + 1)

			local playback = startPlayback(player, source)

			check.is_true(stub.clock:waitFor(function()
				return playback.result
			end, PLAY_WAIT_SECONDS))

			onPlayed(player, playback, before)
		end, function()
			teardown(world)
		end),
		nil
	)
end

type NamedCase = {
	name: string,
	build: (bytes: buffer | string) -> audio.Source,
	file: string,
	format: string,
	packets: number,
	samples: number,
}
type World = { manager: websocket.Manager?, connection: voice.Connection? }
type Playback = { result: any }

return function()
	test.suite("Audio file sources", function()
		test.case("loads libsymphonia with ABI version 3", function()
			check.equal(symphonia.load().symphonia_abi_version(), 3)
		end)

		test.case("loadFileDecoder loads the library, so the next file source does not load it again", function()
			local sys = symphonia.sys
			local loaded = symphonia.load()
			local originalOpenLibrary = sys.openLibrary
			local loads = 0
			local warmedLibrary: symphonia.Lib? = nil
			local succeeded, failure = pcall(function()
				sys.library = nil
				sys.openLibrary = function(): symphonia.Lib
					loads += 1

					return loaded
				end

				audio.loadFileDecoder()
				warmedLibrary = sys.library
				audio.fromEncoded(readFixture("tone.wav")):destroy()
			end)

			sys.openLibrary = originalOpenLibrary
			sys.library = loaded
			sys.loading = false
			sys.waitingThreads = {}

			assert(succeeded, failure)
			check.equal(warmedLibrary, loaded)
			check.equal(loads, 1)
		end)

		for _, namedCase in NAMED_SOURCES do
			test.case(`{namedCase.name} plays {namedCase.file} as {namedCase.format}`, function()
				local before = openCount()
				local source = namedCase.build(readFixture(namedCase.file))
				local packets = readAll(source)

				check.equal(source.format, namedCase.format)
				check.equal(#packets, namedCase.packets)
				check.equal(totalSamples(packets), namedCase.samples)
				check.greater(peakOf(packets), PEAK_FLOOR)

				source:destroy()

				check.equal(openCount(), before)
			end)
		end

		test.case("any supported file plays through any named source, since the content decides the format", function()
			local flac = readFixture("tone.flac")
			local opusFile = readFixture("tone.opus")
			local before = openCount()
			local sources = {
				audio.fromMP3(flac),
				audio.fromFLAC(flac),
				audio.fromCAF(opusFile),
				audio.fromOgg(opusFile),
			}

			checkSamePackets(readAll(sources[1]), readAll(sources[2]))
			checkSamePackets(readAll(sources[3]), readAll(sources[4]))
			check.equal(sources[3].format, "opus")

			for _, source in sources do
				source:destroy()
			end

			check.equal(openCount(), before)
		end)

		test.case("fromFile gives the same packets as fromEncoded, for PCM and for Opus", function()
			local before = openCount()

			for _, file in { "tone.flac", "tone.opus" } do
				local fromFile = audio.fromFile(fixturePath(file))
				local fromEncoded = audio.fromEncoded(readFixture(file))

				checkSamePackets(readAll(fromFile), readAll(fromEncoded))
				fromFile:destroy()
				fromEncoded:destroy()
			end

			check.equal(openCount(), before)
		end)

		test.case("Ogg Opus passes through as exactly the decoder's packets", function()
			local bytes = readFixture("tone.opus")
			local decoder = symphonia.decoder.fromBuffer(bytes)
			local expected = readAllDecoderPackets(decoder)
			local source = audio.fromOgg(bytes)

			decoder:destroy()

			check.equal(#expected, 26)
			checkSamePackets(readAll(source), expected)

			source:destroy()
		end)

		test.case("an Opus file played to the end through fromOgg releases its decoder", function()
			playOnStub(function()
				return audio.fromOgg(readFixture("tone.opus"))
			end, function(player, playback, before)
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(player.packetsSent, 26)
				check.equal(openCount(), before)
			end)
		end)

		test.case("a FLAC file played to the end through fromFLAC releases its decoder", function()
			playOnStub(function()
				return audio.fromFLAC(readFixture("tone.flac"))
			end, function(player, playback, before)
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(player.packetsSent, 25)
				check.equal(openCount(), before)
			end)
		end)

		test.case("a file that fails mid-play fails the playback with its decode error and releases it", function()
			playOnStub(function()
				return failingAfter(audio.fromWAV(readFixture("tone.wav")), 2)
			end, function(player, playback, before)
				check.equal(playback.result:unwrapErr(), `audio source failed: {DECODE_FAILURE}`)
				check.greater(player.packetsSent, 0)
				check.equal(openCount(), before)
			end)
		end)

		test.case("destroy releases an unplayed fromFile source once, for PCM and for Opus", function()
			for _, file in { "tone.flac", "tone.opus" } do
				local before = openCount()
				local source = audio.fromFile(fixturePath(file))
				local lines = captureLines(source)

				check.equal(openCount(), before + 1)

				source:destroy()

				check.equal(openCount(), before)

				source:destroy()

				check.is_true(hasLine(lines, "audio source already ended; nothing to free"))
				check.falsy(source:read())
			end
		end)

		test.case("a source destroyed mid-read releases its decoder and reads nil afterwards", function()
			for _, file in { "tone.flac", "tone.opus" } do
				local before = openCount()
				local source = audio.fromFile(fixturePath(file))

				check.not_nil(source:read())
				check.not_nil(source:read())

				source:destroy()

				check.equal(openCount(), before)
				check.falsy(source:read())
			end
		end)

		test.case("a decode failure raises its own error and releases, and a raising release is only warned", function()
			for _, file in { "tone.wav", "tone.opus" } do
				local before = openCount()
				local source = failingAfter(audio.fromEncoded(readFixture(file)), 2)
				local lines = captureLines(source)
				local release = source.release :: () -> ()
				local failure: string? = nil

				source.release = function()
					release()
					error("release broke", 0)
				end

				for _ = 1, MAX_PACKETS do
					local read, packet = pcall(source.read, source)

					if not read then
						failure = tostring(packet)

						break
					end

					if not packet then
						break
					end
				end

				check.equal(failure, DECODE_FAILURE)
				check.is_true(hasLine(lines, "releasing the audio source failed: release broke"))
				check.equal(openCount(), before)
				check.falsy(source:read())
			end
		end)

		test.case("open failures raise at the call and leave nothing open", function()
			local before = openCount()

			check.is_true(raises(function()
				audio.fromEncoded("this is not an audio file")
			end, "could not open audio: "))
			check.is_true(raises(function()
				audio.fromMP3(buffer.create(0))
			end, "could not open audio: "))
			check.is_true(raises(function()
				audio.fromFile(fixturePath("missing.flac"))
			end, "could not open audio: "))
			check.equal(openCount(), before)
		end)

		test.case("fromEncoded and fromFile hand their options to the decoder", function()
			local before = openCount()

			check.is_true(raises(function()
				audio.fromEncoded(readFixture("tone.wav"), { logLevel = "Bogus" :: any })
			end, "Invalid log level: Bogus"))
			check.is_true(raises(function()
				audio.fromFile(fixturePath("tone.wav"), { logLevel = "Bogus" :: any })
			end, "Invalid log level: Bogus"))
			check.equal(openCount(), before)
		end)

		test.case("a string input gives the same packets as a buffer", function()
			local wav = readFixture("tone.wav")

			checkSamePackets(readAll(audio.fromWAV(wav)), readAll(audio.fromWAV(buffer.fromstring(wav))))
		end)

		test.case("fromEncoded and the named sources raise the path hint for anything but bytes", function()
			check.is_true(raises(function()
				audio.fromEncoded(5 :: any)
			end, `audio.fromEncoded {PATH_HINT}`))
			check.is_true(raises(function()
				audio.fromMP3({} :: any)
			end, `audio.fromMP3 {PATH_HINT}`))
			check.is_true(raises(function()
				audio.fromFile(buffer.create(4) :: any)
			end, "audio.fromFile takes the file's path as a string; for the file's bytes use audio.fromEncoded"))
		end)

		test.case("fromOpus given a file's bytes points at fromOgg and fromFile", function()
			for _, bytes in { buffer.create(3), "OggS" } :: { any } do
				check.is_true(raises(function()
					audio.fromOpus(bytes)
				end, OPUS_FILE_HINT))
			end
		end)
	end)
end
