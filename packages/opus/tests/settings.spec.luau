local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Opus = require("../src")

local SAMPLE_RATE = 48000
local CHANNELS = 2
local FRAME_SIZE = 960
local NOISE_FRAMES = 250
local TARGET_BITRATE = 128000
local FRAME_SECONDS = 0.02
local RANGE_MESSAGE = "bitrate must be a whole number from 500 to 510000 bits per second"
local SIGNAL_MESSAGE = 'signal must be "auto", "voice" or "music"'
local DESTROYED_MESSAGE = "Encoder has been destroyed"

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Encoder settings", function() end)
	end
end

local function makeNoiseFrames(count: number): { buffer }
	local frames: { buffer } = {}
	local state = 12345

	for frameIndex = 1, count do
		local frame = buffer.create(FRAME_SIZE * CHANNELS * 2)

		for sampleIndex = 0, FRAME_SIZE * CHANNELS - 1 do
			state = (state * 1103515245 + 12345) % 2147483648
			buffer.writei16(frame, sampleIndex * 2, (state // 65536) % 16000 - 8000)
		end

		frames[frameIndex] = frame
	end

	return frames
end

local function newEncoder(): Opus.Encoder
	return Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.audio)
end

local function raisesWith(work: () -> (), message: string): boolean
	local succeeded, failure = pcall(work :: () -> any)

	assert(not succeeded, "expected the call to raise")

	if string.find(tostring(failure), message, 1, true) then
		return true
	end

	return false
end

local function averageBitrate(encoder: Opus.Encoder): number
	local totalBytes = 0

	for _, frame in makeNoiseFrames(NOISE_FRAMES) do
		totalBytes += buffer.len(encoder:encode(frame))
	end

	return totalBytes * 8 / (NOISE_FRAMES * FRAME_SECONDS)
end

return function()
	test.suite("Encoder settings", function()
		test.case("a set bitrate reads back after a frame", function()
			local encoder = newEncoder()
			local frame = makeNoiseFrames(1)[1]

			encoder:setBitrate(128000)
			encoder:encode(frame)
			check.equal(encoder:getBitrate(), 128000)

			encoder:setBitrate(510000)
			encoder:encode(frame)
			check.equal(encoder:getBitrate(), 510000)

			encoder:destroy()
		end)

		test.case("a set signal reads back", function()
			local encoder = newEncoder()

			check.equal(encoder:getSignal(), "auto")

			encoder:setSignal("music")
			check.equal(encoder:getSignal(), "music")

			encoder:setSignal("voice")
			check.equal(encoder:getSignal(), "voice")

			encoder:setSignal("auto")
			check.equal(encoder:getSignal(), "auto")

			encoder:destroy()
		end)

		test.case("noise at 128000 averages within 10 percent of 128 kbps", function()
			local encoder = newEncoder()

			encoder:setBitrate(TARGET_BITRATE)

			local average = averageBitrate(encoder)

			check.is_true(average > TARGET_BITRATE * 0.9 and average < TARGET_BITRATE * 1.1)

			encoder:destroy()
		end)

		test.case("checkBitrate accepts the ends of the range", function()
			Opus.checkBitrate(500)
			Opus.checkBitrate(510000)
		end)

		test.case("checkBitrate and setBitrate raise outside 500 to 510000 or off a whole number", function()
			local encoder = newEncoder()

			for _, bitrate in { 499, 510001, 0, -1, 128000.5, 0 / 0, math.huge } do
				check.is_true(raisesWith(function()
					Opus.checkBitrate(bitrate)
				end, RANGE_MESSAGE))
				check.is_true(raisesWith(function()
					encoder:setBitrate(bitrate)
				end, RANGE_MESSAGE))
			end

			encoder:destroy()
		end)

		test.case("checkBitrate raises the range message for a value that is not a number", function()
			local notNumbers: { unknown } = { false, "128000", {} }

			for _, bitrate in notNumbers do
				check.is_true(raisesWith(function()
					Opus.checkBitrate(bitrate)
				end, RANGE_MESSAGE))
			end
		end)

		test.case("setSignal raises on an unknown signal", function()
			local encoder = newEncoder()

			check.is_true(raisesWith(function()
				encoder:setSignal("loud" :: any)
			end, SIGNAL_MESSAGE))

			encoder:destroy()
		end)

		test.case("a destroyed encoder raises on every setting", function()
			local encoder = newEncoder()

			encoder:destroy()

			local calls: { () -> () } = {
				function()
					encoder:setBitrate(128000)
				end,
				function()
					encoder:getBitrate()
				end,
				function()
					encoder:setSignal("music")
				end,
				function()
					encoder:getSignal()
				end,
			}

			for _, call in calls do
				check.is_true(raisesWith(call, DESTROYED_MESSAGE))
			end
		end)
	end)
end
