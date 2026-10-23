local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local symphonia = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local BYTES_PER_FRAME = 4
local MAX_READS = 200
local RAMP_AND_LOOK_AHEAD_FRAMES = 960 + 240
local FULL_SCALE_POSITIVE = 32767
local FULL_SCALE_NEGATIVE = -32768
local MEASURED_FULL_SCALE_SAMPLES = 277258
local MAX_FULL_SCALE_SHARE = 0.01
local MINIMUM_OVERS_PEAK = 20000
local PEAK_ROUNDING = 1
local BAD_VOLUME_MESSAGE = "volume must be a number from 0 to 4"
local OPUS_VOLUME_WARNING = "volume has no effect on Opus passed through as stored"
local BAD_VOLUMES: { any } = { -0.01, 4.01, 5, 0 / 0, math.huge, -math.huge, "1", true, {} }

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Symphonia volume", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function readAll(decoder: symphonia.Decoder): { buffer }
	local chunks = {}
	local chunk = decoder:read()

	while chunk do
		if #chunks >= MAX_READS then
			error(`the decoder did not end within {MAX_READS} reads`)
		end

		table.insert(chunks, chunk)
		chunk = decoder:read()
	end

	return chunks
end

local function peakOf(chunks: { buffer }): number
	local peak = 0

	for _, chunk in chunks do
		for offset = 0, buffer.len(chunk) - 2, 2 do
			peak = math.max(peak, math.abs(buffer.readi16(chunk, offset)))
		end
	end

	return peak
end

local function isFullScale(sample: number): boolean
	return sample >= FULL_SCALE_POSITIVE or sample <= FULL_SCALE_NEGATIVE
end

local function fullScaleStatistics(chunks: { buffer }): (number, number)
	local fullScaleCount = 0
	local longestRun = 0

	for channel = 0, 1 do
		local run = 0

		for _, chunk in chunks do
			for offset = channel * 2, buffer.len(chunk) - 2, BYTES_PER_FRAME do
				if isFullScale(buffer.readi16(chunk, offset)) then
					fullScaleCount += 1
					run += 1
					longestRun = math.max(longestRun, run)
				else
					run = 0
				end
			end
		end
	end

	return fullScaleCount, longestRun
end

local function raisedMessage(work: () -> ...any): string?
	local succeeded, failure = pcall(work)

	return if succeeded then nil else tostring(failure)
end

local function captureLogs(decoder: symphonia.Decoder): { string }
	local lines = {}

	decoder.logger:setLogLevel("Debug")
	decoder.logger:setSink(function(message: string)
		table.insert(lines, message)
	end)

	return lines
end

local function countLines(lines: { string }, level: string, text: string): number
	local count = 0

	for _, line in lines do
		if string.find(line, `[{level}]`, 1, true) and string.find(line, text, 1, true) then
			count += 1
		end
	end

	return count
end

local function peakAtVolume(volume: number?): number
	local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))

	if volume then
		decoder:setVolume(volume)
	end

	local peak = peakOf(readAll(decoder))

	decoder:destroy()

	return peak
end

return function()
	test.suite("Symphonia volume", function()
		test.case("the overs fixture decodes without clipping", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("overs.wav"))
			local limiter = decoder.limiter :: symphonia.Limiter
			local chunks = readAll(decoder)
			local fullScaleCount, longestRun = fullScaleStatistics(chunks)

			decoder:destroy()

			check.equal(limiter.clampCount, 0)
			check.greater(peakOf(chunks), MINIMUM_OVERS_PEAK)
			check.lesser(longestRun, 2)
			check.lesser(fullScaleCount, MEASURED_FULL_SCALE_SAMPLES * MAX_FULL_SCALE_SHARE)
		end)

		test.case("a decoder starts at volume 1", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))

			check.equal(decoder.volume, 1)

			decoder:destroy()
		end)

		test.case("setVolume takes 0 to 4 and holds the value", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))

			for _, volume in { 0, 0.5, 1, 2.5, 4 } do
				decoder:setVolume(volume)

				check.equal(decoder.volume, volume)
			end

			decoder:destroy()
		end)

		test.case("setVolume raises outside 0 to 4 and keeps the old value", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))

			decoder:setVolume(2)

			for _, volume in BAD_VOLUMES do
				check.equal(
					raisedMessage(function()
						decoder:setVolume(volume)
					end),
					BAD_VOLUME_MESSAGE
				)
				check.equal(decoder.volume, 2)
			end

			decoder:destroy()
		end)

		test.case("setVolume raises on a destroyed decoder", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))

			decoder:destroy()

			check.equal(
				raisedMessage(function()
					decoder:setVolume(0.5)
				end),
				"decoder has been destroyed"
			)
		end)

		test.case("volume reaches the decoder: half the volume halves the peak", function()
			local fullPeak = peakAtVolume(nil)
			local halfPeak = peakAtVolume(0.5)

			check.greater(fullPeak, 1000)
			check.lesser_eq(math.abs(halfPeak - fullPeak / 2), PEAK_ROUNDING)
		end)

		test.case("setVolume mid-read lowers the level of the next read", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local firstChunk = decoder:read() :: buffer

			decoder:setVolume(0)

			local nextChunk = decoder:read() :: buffer
			local settledFrames = buffer.len(nextChunk) / BYTES_PER_FRAME - RAMP_AND_LOOK_AHEAD_FRAMES
			local settled = buffer.create(settledFrames * BYTES_PER_FRAME)

			buffer.copy(
				settled,
				0,
				nextChunk,
				RAMP_AND_LOOK_AHEAD_FRAMES * BYTES_PER_FRAME,
				settledFrames * BYTES_PER_FRAME
			)

			check.greater(peakOf({ firstChunk }), 1000)
			check.greater(peakOf({ nextChunk }), 0)
			check.equal(peakOf({ settled }), 0)

			decoder:destroy()
		end)

		test.case("volume 0 decodes to silence and volume 2 doubles the peak", function()
			local fullPeak = peakAtVolume(nil)

			check.equal(peakAtVolume(0), 0)
			check.lesser_eq(math.abs(peakAtVolume(2) - fullPeak * 2), PEAK_ROUNDING)
		end)

		test.case("an Opus decoder warns once that volume has no effect, and keeps the value", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.opus"))
			local lines = captureLogs(decoder)

			decoder:setVolume(0.5)
			decoder:setVolume(0.25)
			decoder:setVolume(3)

			check.equal(decoder.volume, 3)
			check.equal(countLines(lines, "WARN", OPUS_VOLUME_WARNING), 1)

			decoder:destroy()
		end)

		test.case("an Opus decoder still rejects a bad volume", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.opus"))

			check.equal(
				raisedMessage(function()
					decoder:setVolume(5)
				end),
				BAD_VOLUME_MESSAGE
			)
			check.equal(decoder.volume, 1)

			decoder:destroy()
		end)

		test.case("a PCM decoder never logs the Opus warning", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local lines = captureLogs(decoder)

			decoder:setVolume(0.5)
			decoder:setVolume(0.25)

			check.equal(countLines(lines, "WARN", ""), 0)

			decoder:destroy()
		end)
	end)
end
