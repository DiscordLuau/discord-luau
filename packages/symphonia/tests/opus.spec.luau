local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local symphonia = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local MAX_PACKETS = 500
local MAX_PACKET_SIZE = 8000
local SILK_FRAME_SIZES = { 480, 960, 1920, 2880 }
local HYBRID_FRAME_SIZES = { 480, 960 }
local CELT_FRAME_SIZES = { 120, 240, 480, 960 }

local OPUS_FILES: { OpusCase } = {
	{ file = "tone.opus", packets = 26, samples = 24960, container = "ogg", channels = 2 },
	{ file = "tone-60ms.opus", packets = 9, samples = 25920, container = "ogg", channels = 1 },
	{ file = "tone.webm", packets = 26, samples = 24960, container = "matroska", channels = 2 },
}
local STATED_DURATIONS: { [string]: number } = {
	["tone.opus"] = 0.507,
	["tone-60ms.opus"] = 0.507,
}

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Symphonia Opus passthrough", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function readAllPackets(decoder: symphonia.Decoder): { buffer }
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

local function raisedMessage(work: () -> ...any): string?
	local succeeded, failure = pcall(work)

	return if succeeded then nil else tostring(failure)
end

local function checkOpusFile(opusFile: OpusCase)
	local decoder = symphonia.decoder.fromBuffer(readFixture(opusFile.file))
	local packets = readAllPackets(decoder)
	local samples = 0
	local largest = 0

	for _, packet in packets do
		samples += opusSamples(packet)
		largest = math.max(largest, buffer.len(packet))
	end

	check.equal(#packets, opusFile.packets)
	check.equal(samples, opusFile.samples)
	check.lesser_eq(largest, MAX_PACKET_SIZE)
	check.greater(buffer.len(packets[1]), 0)
	check.is_true(decoder.isOpus)
	check.is_true(decoder.ended)
	check.is_false(decoder.endedEarly)
	check.equal(decoder.codec, "opus")
	check.equal(decoder.container, opusFile.container)
	check.equal(decoder.sampleRate, 48000)
	check.equal(decoder.channels, opusFile.channels)
	check.equal(decoder.durationSeconds, STATED_DURATIONS[opusFile.file])
	check.equal(decoder.skippedPackets, 0)

	decoder:destroy()
end

type OpusCase = {
	file: string,
	packets: number,
	samples: number,
	container: string,
	channels: number,
}

return function()
	test.suite("Symphonia Opus passthrough", function()
		test.case("loads libsymphonia with ABI version 3", function()
			check.equal(symphonia.load().symphonia_abi_version(), 3)
		end)

		for _, opusFile in OPUS_FILES do
			test.case(`{opusFile.file} passes through every Opus packet ffmpeg wrote`, function()
				checkOpusFile(opusFile)
			end)
		end

		test.case("Ogg and WebM carry the same Opus packets", function()
			local fromOgg = symphonia.decoder.fromBuffer(readFixture("tone.opus"))
			local fromWebm = symphonia.decoder.fromBuffer(readFixture("tone.webm"))
			local oggPackets = readAllPackets(fromOgg)
			local webmPackets = readAllPackets(fromWebm)

			check.equal(#oggPackets, #webmPackets)

			for index, packet in oggPackets do
				check.equal(buffer.tostring(packet), buffer.tostring(webmPackets[index]))
			end

			fromOgg:destroy()
			fromWebm:destroy()
		end)

		test.case("a two-stream Opus file fails to open", function()
			local message = raisedMessage(function()
				symphonia.decoder.fromBuffer(readFixture("stereo-streams.opus"))
			end)

			check.equal(
				message,
				"could not open audio: this Opus stream has more than one stream and cannot be passed through"
			)
		end)

		test.case("read on Opus raises", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.opus"))
			local message = raisedMessage(function()
				decoder:read()
			end)

			check.equal(message, "this audio is Opus; read it with readPacket")

			decoder:destroy()
		end)

		test.case("readPacket on MP3 raises", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.mp3"))
			local message = raisedMessage(function()
				decoder:readPacket()
			end)

			check.equal(message, "this audio is not Opus; read it with read")

			decoder:destroy()
		end)

		test.case("readPacket after the end returns nil again", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone-60ms.opus"))

			readAllPackets(decoder)

			check.equal(decoder:readPacket(), nil)
			check.equal(decoder:readPacket(), nil)

			decoder:destroy()
		end)
	end)
end
