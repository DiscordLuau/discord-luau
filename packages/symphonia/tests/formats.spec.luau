local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local symphonia = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local BYTES_PER_FRAME = 4
local FLOAT_BYTES_PER_FRAME = 8
local OUTPUT_SAMPLE_RATE = 48000
local FRAME_TOLERANCE = 48
local DURATION_TOLERANCE_SECONDS = 0.01
local MEASURED_SPAN_FRAMES = 14400
local FREQUENCY_TOLERANCE = 3
local MINIMUM_PEAK = 1000
local MAX_READS = 200
local MAX_DECODE_SECONDS = 10
local WAV_HEADER_BYTES = 44
local WAV_FLOAT_FORMAT = 3
local WAV_CHANNELS = 2
local FLOAT_BYTES = 4

local FORMATS: { FormatCase } = {
	{ file = "tone.wav", frames = 24000, codec = "pcm_s16le", container = "wave", sampleRate = 22050, channels = 2 },
	{
		file = "tone-mono.wav",
		frames = 24000,
		codec = "pcm_s16le",
		container = "wave",
		sampleRate = 8000,
		channels = 1,
	},
	{
		file = "tone-adpcm.wav",
		frames = 24000,
		codec = "adpcm_ima_wav",
		container = "wave",
		sampleRate = 22050,
		channels = 1,
	},
	{ file = "tone.mp3", frames = 24000, codec = "mp3", container = "mp3", sampleRate = 44100, channels = 2 },
	{ file = "tone.mp2", frames = 25078, codec = "mp2", container = "mp2", sampleRate = 44100, channels = 2 },
	{ file = "tone.flac", frames = 24000, codec = "flac", container = "flac", sampleRate = 32000, channels = 2 },
	{ file = "tone.ogg", frames = 24000, codec = "vorbis", container = "ogg", sampleRate = 44100, channels = 2 },
	{ file = "tone.aac", frames = 25635, codec = "aac", container = "aac", sampleRate = 44100, channels = 2 },
	{ file = "tone.m4a", frames = 25115, codec = "aac", container = "isomp4", sampleRate = 44100, channels = 2 },
	{ file = "tone-alac.m4a", frames = 24000, codec = "alac", container = "isomp4", sampleRate = 44100, channels = 2 },
	{ file = "tone.aiff", frames = 24003, codec = "pcm_s16be", container = "aiff", sampleRate = 11025, channels = 1 },
	{ file = "tone.caf", frames = 24000, codec = "pcm_s16le", container = "caf", sampleRate = 16000, channels = 1 },
	{
		file = "tone-vorbis.webm",
		frames = 24033,
		codec = "vorbis",
		container = "matroska",
		sampleRate = 44100,
		channels = 2,
	},
}

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Symphonia formats", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function joinChunks(chunks: { buffer }, byteCount: number): buffer
	local joined = buffer.create(byteCount)
	local offset = 0

	for _, chunk in chunks do
		buffer.copy(joined, offset, chunk)
		offset += buffer.len(chunk)
	end

	return joined
end

local function readAllWith(nextChunk: () -> buffer?): buffer
	local chunks = {}
	local byteCount = 0
	local readCount = 1
	local chunk = nextChunk()

	while chunk do
		if readCount >= MAX_READS then
			error(`the decoder did not end within {MAX_READS} reads`)
		end

		table.insert(chunks, chunk)
		byteCount += buffer.len(chunk)
		chunk = nextChunk()
		readCount += 1
	end

	return joinChunks(chunks, byteCount)
end

local function readAll(decoder: symphonia.Decoder): buffer
	return readAllWith(function()
		return decoder:read()
	end)
end

local function readAllFloats(decoder: symphonia.Decoder): buffer
	return readAllWith(function()
		return decoder:readFloat()
	end)
end

local function peakFloatOf(floats: buffer): number
	local peak = 0

	for offset = 0, buffer.len(floats) - 4, 4 do
		peak = math.max(peak, math.abs(buffer.readf32(floats, offset)))
	end

	return peak
end

local function floatWav(samples: { number }): buffer
	local dataBytes = #samples * FLOAT_BYTES
	local wav = buffer.create(WAV_HEADER_BYTES + dataBytes)

	buffer.writestring(wav, 0, "RIFF")
	buffer.writeu32(wav, 4, WAV_HEADER_BYTES - 8 + dataBytes)
	buffer.writestring(wav, 8, "WAVE")
	buffer.writestring(wav, 12, "fmt ")
	buffer.writeu32(wav, 16, 16)
	buffer.writeu16(wav, 20, WAV_FLOAT_FORMAT)
	buffer.writeu16(wav, 22, WAV_CHANNELS)
	buffer.writeu32(wav, 24, OUTPUT_SAMPLE_RATE)
	buffer.writeu32(wav, 28, OUTPUT_SAMPLE_RATE * FLOAT_BYTES_PER_FRAME)
	buffer.writeu16(wav, 32, FLOAT_BYTES_PER_FRAME)
	buffer.writeu16(wav, 34, FLOAT_BYTES * 8)
	buffer.writestring(wav, 36, "data")
	buffer.writeu32(wav, 40, dataBytes)

	for index, sample in samples do
		buffer.writef32(wav, WAV_HEADER_BYTES + (index - 1) * FLOAT_BYTES, sample)
	end

	return wav
end

local function isFinite(sample: number): boolean
	return sample == sample and math.abs(sample) ~= math.huge
end

local function plainConversion(floats: buffer): buffer
	local pcm = buffer.create(buffer.len(floats) // 2)

	for offset = 0, buffer.len(floats) - 4, 4 do
		local sample = math.clamp(math.round(buffer.readf32(floats, offset) * 32768), -32768, 32767)

		buffer.writei16(pcm, offset // 2, sample)
	end

	return pcm
end

local function frequencyOf(pcm: buffer, channel: number): number
	local frameCount = buffer.len(pcm) // BYTES_PER_FRAME
	local firstFrame = (frameCount - MEASURED_SPAN_FRAMES) // 2
	local crossings = 0
	local wasNegative = buffer.readi16(pcm, firstFrame * BYTES_PER_FRAME + channel * 2) < 0

	for frame = firstFrame + 1, firstFrame + MEASURED_SPAN_FRAMES - 1 do
		local isNegative = buffer.readi16(pcm, frame * BYTES_PER_FRAME + channel * 2) < 0

		if isNegative ~= wasNegative then
			crossings += 1
		end

		wasNegative = isNegative
	end

	return crossings / 2 / (MEASURED_SPAN_FRAMES / OUTPUT_SAMPLE_RATE)
end

local function peakOf(pcm: buffer, channel: number): number
	local peak = 0

	for frame = 0, buffer.len(pcm) // BYTES_PER_FRAME - 1 do
		peak = math.max(peak, math.abs(buffer.readi16(pcm, frame * BYTES_PER_FRAME + channel * 2)))
	end

	return peak
end

local function raisedMessage(work: () -> ...any): string?
	local succeeded, failure = pcall(work)

	return if succeeded then nil else tostring(failure)
end

local function openCount(): number
	return symphonia.load().symphonia_open_count()
end

local function checkTone(pcm: buffer, channel: number, frequency: number)
	check.lesser_eq(math.abs(frequencyOf(pcm, channel) - frequency), FREQUENCY_TOLERANCE)
	check.greater(peakOf(pcm, channel), MINIMUM_PEAK)
end

local function checkFormat(format: FormatCase)
	local decoder = symphonia.decoder.fromBuffer(readFixture(format.file))
	local pcm = readAll(decoder)
	local frameCount = buffer.len(pcm) / BYTES_PER_FRAME
	local durationSeconds = decoder.durationSeconds

	check.equal(buffer.len(pcm) % BYTES_PER_FRAME, 0)
	check.lesser_eq(math.abs(frameCount - format.frames), FRAME_TOLERANCE)
	checkTone(pcm, 0, 440)
	checkTone(pcm, 1, 440)
	check.equal(decoder.codec, format.codec)
	check.equal(decoder.container, format.container)
	check.equal(decoder.sampleRate, format.sampleRate)
	check.equal(decoder.channels, format.channels)
	check.is_false(decoder.isOpus)
	check.is_true(decoder.ended)
	check.is_false(decoder.endedEarly)

	if durationSeconds then
		check.lesser_eq(math.abs(durationSeconds - frameCount / OUTPUT_SAMPLE_RATE), DURATION_TOLERANCE_SECONDS)
	end

	decoder:destroy()
end

type FormatCase = {
	file: string,
	frames: number,
	codec: string,
	container: string,
	sampleRate: number,
	channels: number,
}

return function()
	test.suite("Symphonia formats", function()
		test.case("loads libsymphonia with ABI version 2", function()
			check.equal(symphonia.load().symphonia_abi_version(), 2)
		end)

		for _, format in FORMATS do
			test.case(`{format.file} decodes 0.5 s of 440 Hz to 48 kHz stereo`, function()
				checkFormat(format)
			end)
		end

		test.case("layout-51.flac keeps front left on the left and back right on the right", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("layout-51.flac"))
			local pcm = readAll(decoder)

			check.lesser_eq(math.abs(buffer.len(pcm) / BYTES_PER_FRAME - 24000), FRAME_TOLERANCE)
			checkTone(pcm, 0, 440)
			checkTone(pcm, 1, 660)
			check.equal(decoder.channels, 6)
			check.is_false(decoder.endedEarly)

			decoder:destroy()
		end)

		test.case("a matroska file states no duration", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone-vorbis.webm"))

			check.equal(decoder.durationSeconds, nil)

			decoder:destroy()
		end)

		test.case("fromFile decodes the same audio as fromBuffer", function()
			local fromFile = symphonia.decoder.fromFile(`{FIXTURES}/tone.flac`)
			local fromBuffer = symphonia.decoder.fromBuffer(readFixture("tone.flac"))

			check.equal(buffer.tostring(readAll(fromFile)), buffer.tostring(readAll(fromBuffer)))
			check.equal(fromFile.codec, "flac")

			fromFile:destroy()
			fromBuffer:destroy()
		end)

		test.case("a string input decodes the same audio as a buffer input", function()
			local bytes = readFixture("tone.mp3")
			local fromString = symphonia.decoder.fromBuffer(bytes)
			local fromBuffer = symphonia.decoder.fromBuffer(buffer.fromstring(bytes))

			check.equal(buffer.tostring(readAll(fromString)), buffer.tostring(readAll(fromBuffer)))

			fromString:destroy()
			fromBuffer:destroy()
		end)

		test.case("an extension hint naming another format changes nothing", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.flac"), { extension = "mp3" })

			check.equal(decoder.codec, "flac")
			check.equal(buffer.len(readAll(decoder)), 24000 * BYTES_PER_FRAME)

			decoder:destroy()
		end)

		test.case("decode returns the whole file as one buffer and frees its decoder", function()
			local bytes = readFixture("tone.ogg")
			local countBefore = openCount()
			local decoded = symphonia.decode(bytes, { maxSeconds = MAX_DECODE_SECONDS })
			local decoder = symphonia.decoder.fromBuffer(bytes)

			check.equal(openCount(), countBefore + 1)
			check.equal(buffer.tostring(decoded), buffer.tostring(readAll(decoder)))

			decoder:destroy()

			check.equal(openCount(), countBefore)
		end)

		test.case("decode raises past maxSeconds and frees its decoder", function()
			local countBefore = openCount()
			local message = raisedMessage(function()
				symphonia.decode(readFixture("tone.wav"), { maxSeconds = 0.25 })
			end)

			check.equal(message, "the decoded audio is longer than 0.25 s; read it with a Decoder instead")
			check.equal(openCount(), countBefore)
		end)

		test.case("decode raises on Opus and frees its decoder", function()
			local countBefore = openCount()
			local message = raisedMessage(function()
				symphonia.decode(readFixture("tone.opus"), { maxSeconds = MAX_DECODE_SECONDS })
			end)

			check.equal(message, "this audio is Opus; read it with readPacket")
			check.equal(openCount(), countBefore)
		end)

		test.case("readFloat returns the floats read converts, past full scale and at any volume", function()
			local floatDecoder = symphonia.decoder.fromBuffer(readFixture("tone.mp3"))
			local pcmDecoder = symphonia.decoder.fromBuffer(readFixture("tone.mp3"))
			local floats = readAllFloats(floatDecoder)

			check.equal(buffer.len(floats), 24000 * FLOAT_BYTES_PER_FRAME)
			check.equal(buffer.tostring(plainConversion(floats)), buffer.tostring(readAll(pcmDecoder)))
			check.is_true(floatDecoder.ended)
			check.equal(floatDecoder:readFloat(), nil)

			floatDecoder:destroy()
			pcmDecoder:destroy()

			local overs = symphonia.decoder.fromBuffer(readFixture("overs.wav"))

			overs:setVolume(0.25)

			check.greater(peakFloatOf(readAllFloats(overs)), 1.5)

			overs:destroy()
		end)

		test.case("read turns Inf and NaN into 0", function()
			local samples = { math.huge, -math.huge, 0 / 0, 0 / 0, 0.5, -0.5 }
			local floatDecoder = symphonia.decoder.fromBuffer(floatWav(samples))
			local pcmDecoder = symphonia.decoder.fromBuffer(floatWav(samples))
			local floats = readAllFloats(floatDecoder)
			local pcm = readAll(pcmDecoder)

			check.equal(buffer.len(pcm), #samples * 2)

			for sampleIndex = 0, 3 do
				check.is_false(isFinite(buffer.readf32(floats, sampleIndex * FLOAT_BYTES)))
				check.equal(buffer.readi16(pcm, sampleIndex * 2), 0)
			end

			check.equal(buffer.readi16(pcm, 8), 16384)
			check.equal(buffer.readi16(pcm, 10), -16384)

			floatDecoder:destroy()
			pcmDecoder:destroy()
		end)

		test.case("readFloat raises on Opus and after destroy", function()
			local opusDecoder = symphonia.decoder.fromBuffer(readFixture("tone.opus"))

			check.equal(
				raisedMessage(function()
					opusDecoder:readFloat()
				end),
				"this audio is Opus; read it with readPacket"
			)

			opusDecoder:destroy()

			check.equal(
				raisedMessage(function()
					opusDecoder:readFloat()
				end),
				"decoder has been destroyed"
			)
		end)

		test.case("the output constants describe 48 kHz stereo", function()
			check.equal(symphonia.OUTPUT_SAMPLE_RATE, 48000)
			check.equal(symphonia.OUTPUT_CHANNELS, 2)
		end)
	end)
end
