local frktest = require("../../../luau_packages/frktest")
local Opus = require("../src")
local stdPolyfills = require("../luau_packages/std_polyfills")

local test = frktest.test
local check = frktest.assert.check

local hasFfi = stdPolyfills.runtime.capabilities().ffi

local SAMPLE_RATE = Opus.DISCORD_SAMPLE_RATE
local CHANNELS = Opus.DISCORD_CHANNELS
local FRAME_SIZE = Opus.DISCORD_FRAME_SIZE

local function makeSilenceFrame(): buffer
	local frame = buffer.create(FRAME_SIZE * CHANNELS * 2)
	buffer.fill(frame, 0, 0)
	return frame
end

local function makeFullScaleFrame(): buffer
	local frame = buffer.create(FRAME_SIZE * CHANNELS * 2)

	for index = 0, FRAME_SIZE * CHANNELS - 1 do
		buffer.writei16(frame, index * 2, 32767)
	end

	return frame
end

return function()
	test.suite("Stats", function()
		test.case("silence frame has zero peak and rms", function()
			local stats = Opus.stats(makeSilenceFrame(), SAMPLE_RATE, CHANNELS)

			check.equal(stats.peakAmplitude, 0)
			check.equal(stats.rms, 0)
		end)

		test.case("silence frame dBFS is -math.huge", function()
			local stats = Opus.stats(makeSilenceFrame(), SAMPLE_RATE, CHANNELS)

			check.equal(stats.dBFS, -math.huge)
		end)

		test.case("silence frame has no clipped samples", function()
			local stats = Opus.stats(makeSilenceFrame(), SAMPLE_RATE, CHANNELS)

			check.equal(stats.clippedSamples, 0)
		end)

		test.case("silence frame dc offset is zero", function()
			local stats = Opus.stats(makeSilenceFrame(), SAMPLE_RATE, CHANNELS)

			check.equal(stats.dcOffset, 0)
		end)

		test.case("full-scale frame peak amplitude is 1.0", function()
			local stats = Opus.stats(makeFullScaleFrame(), SAMPLE_RATE, CHANNELS)

			check.equal(stats.peakAmplitude, 32767 / 32768)
		end)

		test.case("full-scale frame has clipped samples", function()
			local stats = Opus.stats(makeFullScaleFrame(), SAMPLE_RATE, CHANNELS)

			check.is_true(stats.clippedSamples > 0)
		end)

		test.case("full-scale frame dBFS is close to 0", function()
			local stats = Opus.stats(makeFullScaleFrame(), SAMPLE_RATE, CHANNELS)

			check.is_true(stats.dBFS > -1 and stats.dBFS <= 0)
		end)

		test.case("sample count matches buffer length / 2", function()
			local frame = makeSilenceFrame()
			local stats = Opus.stats(frame, SAMPLE_RATE, CHANNELS)

			check.equal(stats.sampleCount, buffer.len(frame) // 2)
		end)

		test.case("duration matches frame size / sample rate in ms", function()
			local stats = Opus.stats(makeSilenceFrame(), SAMPLE_RATE, CHANNELS)
			local expectedMs = FRAME_SIZE / SAMPLE_RATE * 1000

			check.equal(stats.durationMs, expectedMs)
		end)
	end)

	if hasFfi then
		test.suite("Encoder", function()
			test.case("constructs with voip application", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)

				check.not_nil(encoder)

				encoder:destroy()
			end)

			test.case("constructs with audio application", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.audio)

				check.not_nil(encoder)

				encoder:destroy()
			end)

			test.case("stores construction parameters", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)

				check.equal(encoder.sampleRate, SAMPLE_RATE)
				check.equal(encoder.channels, CHANNELS)
				check.equal(encoder.application, Opus.application.voip)

				encoder:destroy()
			end)

			test.case("errors on an invalid sample rate", function()
				check.should_error(function()
					Opus.encoder.new(9999, CHANNELS, Opus.application.voip)

					return
				end)
			end)

			test.case("encodes a silence frame without error", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)

				local packet = encoder:encode(makeSilenceFrame())

				check.not_nil(packet)
				check.is_true(buffer.len(packet) > 0)

				encoder:destroy()
			end)

			test.case("encoded packet is smaller than the raw frame", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)

				local frame = makeSilenceFrame()
				local packet = encoder:encode(frame)

				check.is_true(buffer.len(packet) < buffer.len(frame))

				encoder:destroy()
			end)

			test.case("destroy is idempotent", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)

				check.should_not_error(function()
					encoder:destroy()
					encoder:destroy()

					return
				end)
			end)
		end)

		test.suite("Decoder", function()
			test.case("constructs without error", function()
				local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)

				check.not_nil(decoder)

				decoder:destroy()
			end)

			test.case("stores construction parameters", function()
				local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)

				check.equal(decoder.sampleRate, SAMPLE_RATE)
				check.equal(decoder.channels, CHANNELS)

				decoder:destroy()
			end)

			test.case("errors on empty input", function()
				local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)

				check.should_error(function()
					decoder:decode(buffer.create(0))

					return
				end)

				decoder:destroy()
			end)

			test.case("destroy is idempotent", function()
				local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)

				check.should_not_error(function()
					decoder:destroy()
					decoder:destroy()

					return
				end)
			end)
		end)

		test.suite("encode-decode round trip", function()
			test.case("decoded output has the expected PCM byte length", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
				local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)

				local packet = encoder:encode(makeSilenceFrame())
				local pcm = decoder:decode(packet)

				check.equal(buffer.len(pcm), FRAME_SIZE * CHANNELS * 2)

				encoder:destroy()
				decoder:destroy()
			end)

			test.case("decoded silence frame contains only zero samples", function()
				local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
				local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)

				local pcm = decoder:decode(encoder:encode(makeSilenceFrame()))
				local stats = Opus.stats(pcm, SAMPLE_RATE, CHANNELS)

				check.equal(stats.peakAmplitude, 0)

				encoder:destroy()
				decoder:destroy()
			end)

			test.case("decodePLC produces a buffer of the expected length", function()
				local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)
				local pcm = decoder:decodePLC()

				check.equal(buffer.len(pcm), FRAME_SIZE * CHANNELS * 2)

				decoder:destroy()
			end)
		end)
	end
end
