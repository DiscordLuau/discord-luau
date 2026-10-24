local frktest = require("../../../luau_packages/frktest")
local logger = require("../luau_packages/logger")
local stdPolyfills = require("../luau_packages/std_polyfills")

local symphonia = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local SONG_PATH = "packages/example/song.mp3"
local PCM_FIXTURES = {
	"tone.wav",
	"tone-mono.wav",
	"tone-adpcm.wav",
	"tone.mp3",
	"tone.mp2",
	"tone.flac",
	"layout-51.flac",
	"tone.ogg",
	"tone.aac",
	"tone.m4a",
	"tone-alac.m4a",
	"tone.aiff",
	"tone.caf",
	"tone-vorbis.webm",
}
local FLOAT_BYTES = 4
local SAMPLE_BYTES = 2
local PCM_BYTES_PER_FRAME = 4
local FLOAT_BYTES_PER_FRAME = 8
local FULL_SCALE = 32768
local SAMPLE_MAX = 32767
local SAMPLE_MIN = -32768
local SAMPLE_RATE = 48000
local LOOKAHEAD_FRAMES = 240
local READ_FRAMES = 4800
local MAX_READS = 200
local MAX_SONG_READS = 36000
local MINIMUM_OVERS_PEAK = 20000
local MINIMUM_OVERS_FLOAT_PEAK = 1.9
local GENERATED_SECONDS = 225
local GENERATED_BLOCK_FRAMES = 4800
local GENERATED_AMPLITUDE = 16384
local WAV_HEADER_BYTES = 44
local WAV_PCM_FORMAT = 1
local MINIMUM_SPEED_FACTOR = 20
local SHORT_FRAMES = 100
local TONE_FRAMES = 24000
local AFTER_END_LINE = "was read after its end"

local test = frktest.test
local check = frktest.assert.check
local specLogger = logger.new("LimitedReadsSpec", "Info")

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Symphonia limited reads", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function readChunks(nextChunk: () -> buffer?, maxReads: number): { buffer }
	local chunks = {}
	local chunk = nextChunk()

	while chunk do
		if #chunks >= maxReads then
			error(`the decoder did not end within {maxReads} reads`)
		end

		table.insert(chunks, chunk)
		chunk = nextChunk()
	end

	return chunks
end

local function joinChunks(chunks: { buffer }): buffer
	local length = 0

	for _, chunk in chunks do
		length += buffer.len(chunk)
	end

	local whole = buffer.create(length)
	local offset = 0

	for _, chunk in chunks do
		buffer.copy(whole, offset, chunk)
		offset += buffer.len(chunk)
	end

	return whole
end

local function irregularReads(chunks: { buffer }): number
	local count = 0

	for index, chunk in chunks do
		local frames = buffer.len(chunk) // PCM_BYTES_PER_FRAME
		local expected = if index == #chunks then LOOKAHEAD_FRAMES elseif index < #chunks - 1 then READ_FRAMES else nil

		count += if frames > 0 and (not expected or frames == expected) then 0 else 1
	end

	return count
end

local function plainConversion(floats: buffer): buffer
	local pcm = buffer.create(buffer.len(floats) // FLOAT_BYTES * SAMPLE_BYTES)

	for offset = 0, buffer.len(floats) - FLOAT_BYTES, FLOAT_BYTES do
		local sample = math.clamp(math.round(buffer.readf32(floats, offset) * FULL_SCALE), SAMPLE_MIN, SAMPLE_MAX)

		buffer.writei16(pcm, offset // FLOAT_BYTES * SAMPLE_BYTES, sample)
	end

	return pcm
end

local function peakOf(pcm: buffer): number
	local peak = 0

	for offset = 0, buffer.len(pcm) - SAMPLE_BYTES, SAMPLE_BYTES do
		peak = math.max(peak, math.abs(buffer.readi16(pcm, offset)))
	end

	return peak
end

local function floatPeakOf(floats: buffer): number
	local peak = 0

	for offset = 0, buffer.len(floats) - FLOAT_BYTES, FLOAT_BYTES do
		peak = math.max(peak, math.abs(buffer.readf32(floats, offset)))
	end

	return peak
end

local function longestFullScaleRun(pcm: buffer): number
	local longest = 0

	for channel = 0, 1 do
		local run = 0

		for offset = channel * SAMPLE_BYTES, buffer.len(pcm) - SAMPLE_BYTES, PCM_BYTES_PER_FRAME do
			local sample = buffer.readi16(pcm, offset)

			run = if sample >= SAMPLE_MAX or sample <= SAMPLE_MIN then run + 1 else 0
			longest = math.max(longest, run)
		end
	end

	return longest
end

local function toneWav(frames: number): buffer
	local dataBytes = frames * PCM_BYTES_PER_FRAME
	local wav = buffer.create(WAV_HEADER_BYTES + dataBytes)
	local toneFrames = math.min(frames, GENERATED_BLOCK_FRAMES)
	local blockBytes = GENERATED_BLOCK_FRAMES * PCM_BYTES_PER_FRAME

	buffer.writestring(wav, 0, "RIFF")
	buffer.writeu32(wav, 4, WAV_HEADER_BYTES - 8 + dataBytes)
	buffer.writestring(wav, 8, "WAVE")
	buffer.writestring(wav, 12, "fmt ")
	buffer.writeu32(wav, 16, 16)
	buffer.writeu16(wav, 20, WAV_PCM_FORMAT)
	buffer.writeu16(wav, 22, 2)
	buffer.writeu32(wav, 24, SAMPLE_RATE)
	buffer.writeu32(wav, 28, SAMPLE_RATE * PCM_BYTES_PER_FRAME)
	buffer.writeu16(wav, 32, PCM_BYTES_PER_FRAME)
	buffer.writeu16(wav, 34, 16)
	buffer.writestring(wav, 36, "data")
	buffer.writeu32(wav, 40, dataBytes)

	for frame = 0, toneFrames - 1 do
		local sample = math.round(math.sin(frame * 440 * 2 * math.pi / SAMPLE_RATE) * GENERATED_AMPLITUDE)
		local offset = WAV_HEADER_BYTES + frame * PCM_BYTES_PER_FRAME

		buffer.writei16(wav, offset, sample)
		buffer.writei16(wav, offset + SAMPLE_BYTES, -sample)
	end

	for blockOffset = blockBytes, dataBytes - blockBytes, blockBytes do
		buffer.copy(wav, WAV_HEADER_BYTES + blockOffset, wav, WAV_HEADER_BYTES, blockBytes)
	end

	return wav
end

local function captureLogs(decoder: symphonia.Decoder): { string }
	local lines = {}

	decoder.logger:setLogLevel("Debug")
	decoder.logger:setSink(function(message: string)
		table.insert(lines, message)
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

local function stubOneDryRead(decoder: symphonia.Decoder)
	local stubbed = decoder :: any
	local originalReadNext = decoder.readNext
	local dryReadsLeft = 1

	stubbed.readNext = function(self: symphonia.Decoder, readsOpus: boolean, floatFrames: number): buffer?
		dryReadsLeft -= 1

		return if dryReadsLeft == 0 then nil else originalReadNext(self, readsOpus, floatFrames)
	end
end

local function openSong(): (symphonia.Decoder, string)
	local hasSong = stdPolyfills.fileSystem.isFile(SONG_PATH)
	local decoder = if hasSong
		then symphonia.decoder.fromFile(SONG_PATH)
		else symphonia.decoder.fromBuffer(toneWav(GENERATED_SECONDS * SAMPLE_RATE))
	local description = if hasSong then SONG_PATH else `a generated {GENERATED_SECONDS} s WAV`

	return decoder, description
end

return function()
	test.suite("Symphonia limited reads", function()
		test.case("read is bit for bit below full scale, keeps every frame and returns 100 ms a read", function()
			for _, name in PCM_FIXTURES do
				local floatDecoder = symphonia.decoder.fromBuffer(readFixture(name))
				local pcmDecoder = symphonia.decoder.fromBuffer(readFixture(name))
				local limiter = pcmDecoder.limiter :: symphonia.Limiter
				local floatChunks = readChunks(function()
					return floatDecoder:readFloat()
				end, MAX_READS)
				local pcmChunks = readChunks(function()
					return pcmDecoder:read()
				end, MAX_READS)
				local floats = joinChunks(floatChunks)
				local pcm = joinChunks(pcmChunks)

				floatDecoder:destroy()
				pcmDecoder:destroy()

				check.is_true(buffer.tostring(pcm) == buffer.tostring(plainConversion(floats)))
				check.equal(
					`{name}: {buffer.len(pcm) // PCM_BYTES_PER_FRAME} frames`,
					`{name}: {buffer.len(floats) // FLOAT_BYTES_PER_FRAME} frames`
				)
				check.equal(`{name}: {irregularReads(pcmChunks)} irregular reads`, `{name}: 0 irregular reads`)
				check.equal(limiter.clampCount, 0)
			end
		end)

		test.case("decode limits audio past full scale exactly as read does", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("overs.wav"))
			local read = joinChunks(readChunks(function()
				return decoder:read()
			end, MAX_READS))
			local decoded = symphonia.decode(readFixture("overs.wav"))

			decoder:destroy()

			check.is_true(buffer.tostring(decoded) == buffer.tostring(read))
			check.greater(peakOf(decoded), MINIMUM_OVERS_PEAK)
			check.lesser(longestFullScaleRun(decoded), 2)
		end)

		test.case("a file shorter than the look-ahead comes out in one read, never an empty one", function()
			local decoder = symphonia.decoder.fromBuffer(toneWav(SHORT_FRAMES))
			local first = decoder:read()
			local second = decoder:read()

			decoder:destroy()

			check.equal(if first then buffer.len(first) // PCM_BYTES_PER_FRAME else -1, SHORT_FRAMES)
			check.is_true(not second)
		end)

		test.case("a read that returns nil before the end leaves the limiter running", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local limiter = decoder.limiter :: symphonia.Limiter
			local first = decoder:read() :: buffer

			stubOneDryRead(decoder)

			local dry = decoder:read()
			local wasFlushed = limiter.flushed
			local wasEnded = decoder.ended
			local succeeded, rest = pcall(readChunks, function()
				return decoder:read()
			end, MAX_READS)
			local restFrames = if succeeded then buffer.len(joinChunks(rest)) // PCM_BYTES_PER_FRAME else -1

			decoder:destroy()

			check.is_true(not dry)
			check.is_false(wasFlushed)
			check.is_false(wasEnded)
			check.equal(if succeeded then "read on" else tostring(rest), "read on")
			check.equal(buffer.len(first) // PCM_BYTES_PER_FRAME + restFrames, TONE_FRAMES)
		end)

		test.case("only a read after the nil that ends the audio logs a read after the end", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local lines = captureLogs(decoder)
			local chunks = readChunks(function()
				return decoder:read()
			end, MAX_READS)
			local linesAtEnd = countLines(lines, AFTER_END_LINE)
			local extra = decoder:read()

			decoder:destroy()

			check.equal(buffer.len(joinChunks(chunks)) // PCM_BYTES_PER_FRAME, TONE_FRAMES)
			check.equal(linesAtEnd, 0)
			check.is_true(not extra)
			check.equal(countLines(lines, AFTER_END_LINE), 1)
		end)

		test.case("destroy releases the limiter, and read raises after it", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local hadLimiter = if decoder.limiter then true else false

			decoder:read()
			decoder:destroy()

			local succeeded, failure = pcall(decoder.read, decoder)

			check.is_true(hadLimiter)
			check.is_true(not decoder.limiter)
			check.is_false(succeeded)
			check.equal(tostring(failure), "decoder has been destroyed")
		end)

		test.case("readFloat is untouched by the volume and the limiter", function()
			local plain = symphonia.decoder.fromBuffer(readFixture("overs.wav"))
			local quieter = symphonia.decoder.fromBuffer(readFixture("overs.wav"))

			quieter:setVolume(0.25)

			local plainFloats = joinChunks(readChunks(function()
				return plain:readFloat()
			end, MAX_READS))
			local quieterFloats = joinChunks(readChunks(function()
				return quieter:readFloat()
			end, MAX_READS))

			plain:destroy()
			quieter:destroy()

			check.is_true(buffer.tostring(quieterFloats) == buffer.tostring(plainFloats))
			check.greater(floatPeakOf(quieterFloats), MINIMUM_OVERS_FLOAT_PEAK)
		end)

		test.case("a 225 s song is read through the limiter at least 20x faster than real time", function()
			local decoder, description = openSong()
			local limiter = decoder.limiter :: symphonia.Limiter
			local frames = 0
			local reads = 0
			local startedAt = os.clock()
			local chunk = decoder:read()

			while chunk and reads < MAX_SONG_READS do
				frames += buffer.len(chunk) // PCM_BYTES_PER_FRAME
				reads += 1
				chunk = decoder:read()
			end

			local elapsedSeconds = os.clock() - startedAt
			local audioSeconds = frames / SAMPLE_RATE
			local factor = audioSeconds / elapsedSeconds

			decoder:destroy()
			specLogger:info(
				`read {description}, {string.format("%.1f", audioSeconds)} s of audio, in {string.format(
					"%.3f",
					elapsedSeconds
				)} s through the limiter: {string.format("%.1f", factor)}x real time`
			)

			check.is_true(not chunk)
			check.greater(audioSeconds, 200)
			check.equal(limiter.clampCount, 0)
			check.greater_eq(factor, MINIMUM_SPEED_FACTOR)
		end)
	end)
end
