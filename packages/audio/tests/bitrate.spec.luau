local frktest = require("../../../luau_packages/frktest")
local opus = require("../luau_packages/opus")
local stdPolyfills = require("../luau_packages/std_polyfills")
local symphonia = require("../luau_packages/symphonia")

local audio = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local FRAME_BYTES = 3840
local SAMPLE_BYTES = 4
local FRAME_COUNT = 300
local FRAME_SECONDS = 0.02
local MAX_PACKETS = 1000
local DEFAULT_BITRATE = 128000
local CUSTOM_BITRATE = 64000
local TONE_HERTZ = 440
local TONE_AMPLITUDE = 6000
local NOISE_AMPLITUDE = 9000
local NOISE_SEED = 20261022
local LCG_MULTIPLIER = 1664525
local LCG_INCREMENT = 1013904223
local LCG_MODULUS = 4294967296
local BAD_BITRATE_MESSAGE = "bitrate must be a whole number from 500 to 510000 bits per second"
local BAD_BITRATES = { 499, 510001, 128000.5 }
local NAMED_SOURCES = {
	"fromMP3",
	"fromOgg",
	"fromWAV",
	"fromFLAC",
	"fromAAC",
	"fromM4A",
	"fromWebM",
	"fromMKV",
	"fromAIFF",
	"fromCAF",
}

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio encoder settings", function() end)
	end
end

local function noise(frameCount: number): buffer
	local sampleCount = frameCount * FRAME_BYTES // SAMPLE_BYTES
	local pcm = buffer.create(sampleCount * SAMPLE_BYTES)
	local state = NOISE_SEED

	for sampleIndex = 0, sampleCount - 1 do
		state = (state * LCG_MULTIPLIER + LCG_INCREMENT) % LCG_MODULUS

		local white = (state / LCG_MODULUS * 2 - 1) * NOISE_AMPLITUDE
		local phase = 2 * math.pi * TONE_HERTZ * sampleIndex / opus.DISCORD_SAMPLE_RATE
		local sample = math.floor(math.max(-32768, math.min(32767, white + math.sin(phase) * TONE_AMPLITUDE)))

		buffer.writei16(pcm, sampleIndex * SAMPLE_BYTES, sample)
		buffer.writei16(pcm, sampleIndex * SAMPLE_BYTES + 2, sample)
	end

	return pcm
end

local function silence(frameCount: number): buffer
	return buffer.create(frameCount * FRAME_BYTES)
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function raises(callback: () -> ...any, text: string): boolean
	local ran, failure = pcall(callback)
	local found = not ran and string.find(tostring(failure), text, 1, true)

	return if found then true else false
end

local function readBounded(source: audio.Source): { buffer }
	local packets = {}

	for _ = 1, MAX_PACKETS do
		local packet = source:read()

		if not packet then
			return packets
		end

		table.insert(packets, packet)
	end

	error(`the source gave more than {MAX_PACKETS} packets`)
end

return function()
	test.suite("Audio encoder settings", function()
		test.case("a noise fixture through fromPCM averages within 10% of 128 kbps", function()
			local packets = readBounded(audio.fromPCM(noise(FRAME_COUNT)))
			local totalBytes = 0

			for _, packet in packets do
				totalBytes += buffer.len(packet)
			end

			local bitsPerSecond = totalBytes * 8 / (#packets * FRAME_SECONDS)

			check.equal(#packets, FRAME_COUNT)
			check.is_true(bitsPerSecond > DEFAULT_BITRATE * 0.9)
			check.is_true(bitsPerSecond < DEFAULT_BITRATE * 1.1)
		end)

		test.case("options.bitrate reaches the encoder, and 128000 is the default", function()
			local custom = audio.fromPCM(silence(2), { bitrate = CUSTOM_BITRATE })
			local default = audio.fromPCM(silence(2))

			check.equal(custom.bitrate, CUSTOM_BITRATE)
			check.equal(default.bitrate, DEFAULT_BITRATE)
			check.falsy(custom.encoder)

			check.truthy(custom:read())
			check.truthy(default:read())
			check.equal((custom.encoder :: opus.Encoder):getBitrate(), CUSTOM_BITRATE)
			check.equal((default.encoder :: opus.Encoder):getBitrate(), DEFAULT_BITRATE)

			custom:destroy()
			default:destroy()
		end)

		test.case("the encoder is given the music signal", function()
			local source = audio.fromPCM(silence(2))

			check.truthy(source:read())
			check.equal((source.encoder :: opus.Encoder):getSignal(), "music")
			source:destroy()
		end)

		test.case("the file sources take options.bitrate and hold it", function()
			local wav = readFixture("tone.wav")
			local sources = {
				audio.fromEncoded(wav, { bitrate = CUSTOM_BITRATE }),
				audio.fromWAV(wav, { bitrate = CUSTOM_BITRATE }),
				audio.fromFile(`{FIXTURES}/tone.wav`, { bitrate = CUSTOM_BITRATE }),
			}

			for _, source in sources do
				check.equal(source.bitrate, CUSTOM_BITRATE)
				check.truthy(source:read())
				check.equal((source.encoder :: opus.Encoder):getBitrate(), CUSTOM_BITRATE)
				check.equal((source.encoder :: opus.Encoder):getSignal(), "music")
				source:destroy()
			end

			local defaulted = audio.fromEncoded(wav)

			check.equal(defaulted.bitrate, DEFAULT_BITRATE)
			defaulted:destroy()
		end)

		test.case("every named source forwards bitrate and logLevel", function()
			local wav = readFixture("tone.wav")

			for _, name in NAMED_SOURCES do
				local build = (audio :: any)[name]
				local source = build(wav, { bitrate = CUSTOM_BITRATE })

				check.equal(source.bitrate, CUSTOM_BITRATE)
				source:destroy()

				check.is_true(raises(function()
					build(wav, { bitrate = BAD_BITRATES[1] })
				end, BAD_BITRATE_MESSAGE))
				check.is_true(raises(function()
					build(wav, { logLevel = "NotALevel" })
				end, "Invalid log level: NotALevel"))
			end
		end)

		test.case("a bitrate of false is checked, not replaced by the default", function()
			local ran, failure = pcall(function()
				audio.fromPCM(silence(1), { bitrate = false :: any })
			end)

			check.is_false(ran)
			check.not_nil((string.find(tostring(failure), "bitrate must be a whole number", 1, true)))
		end)

		test.case("a bad bitrate raises before any decoder opens", function()
			local library = symphonia.load()
			local openCount = library.symphonia_open_count()
			local wav = readFixture("tone.wav")

			for _, bitrate in BAD_BITRATES do
				check.is_true(raises(function()
					audio.fromEncoded(wav, { bitrate = bitrate })
				end, BAD_BITRATE_MESSAGE))
				check.is_true(raises(function()
					audio.fromFile(`{FIXTURES}/tone.wav`, { bitrate = bitrate })
				end, BAD_BITRATE_MESSAGE))
			end

			check.equal(library.symphonia_open_count(), openCount)
		end)

		test.case("a setting that raises frees the encoder once and passes the error on", function()
			local probe = opus.encoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS, opus.application.audio)
			local prototype = (getmetatable(probe :: any) :: any).__index
			local originalDestroy = prototype.destroy
			local originalSettings = { setBitrate = prototype.setBitrate, setSignal = prototype.setSignal }

			probe:destroy()

			local destroyCount = 0

			local function patch(setting: string)
				prototype.destroy = function(...)
					destroyCount += 1

					return originalDestroy(...)
				end
				prototype[setting] = function()
					error("the setting broke", 0)
				end
			end

			local function restore(setting: string)
				prototype[setting] = originalSettings[setting]
				prototype.destroy = originalDestroy
			end

			local function readWithBrokenSetting(setting: string): (boolean, any, opus.Encoder?)
				local source = audio.fromPCM(silence(2))

				destroyCount = 0
				patch(setting)

				local ran, failure = pcall(source.read, source)

				restore(setting)

				return ran, failure, source.encoder
			end

			for _, setting in { "setBitrate", "setSignal" } do
				local ran, failure, encoder = readWithBrokenSetting(setting)

				check.is_false(ran)
				check.equal(failure, "the setting broke")
				check.equal(destroyCount, 1)
				check.falsy(encoder)
			end
		end)

		test.case("a bad bitrate raises at the source call with the opus message", function()
			local wav = readFixture("tone.wav")

			for _, bitrate in BAD_BITRATES do
				check.is_true(raises(function()
					audio.fromPCM(silence(1), { bitrate = bitrate })
				end, BAD_BITRATE_MESSAGE))
				check.is_true(raises(function()
					audio.fromEncoded(wav, { bitrate = bitrate })
				end, BAD_BITRATE_MESSAGE))
				check.is_true(raises(function()
					audio.fromWAV(wav, { bitrate = bitrate })
				end, BAD_BITRATE_MESSAGE))
				check.is_true(raises(function()
					audio.fromFile(`{FIXTURES}/tone.wav`, { bitrate = bitrate })
				end, BAD_BITRATE_MESSAGE))
			end
		end)
	end)
end
