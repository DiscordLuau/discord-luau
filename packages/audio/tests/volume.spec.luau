local frktest = require("../../../luau_packages/frktest")
local opus = require("../luau_packages/opus")
local stdPolyfills = require("../luau_packages/std_polyfills")
local symphonia = require("../luau_packages/symphonia")

local audio = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local MAX_PACKETS = 500
local PEAK_FLOOR = 1000
local PACKETS_PER_READ = 5
local SETTLED_PACKETS_AFTER_CHANGE = 3
local SILENT_PEAK = 100
local HALF_LOW = 0.4
local HALF_HIGH = 0.6
local BAD_VOLUME_MESSAGE = "volume must be a number from 0 to 4"
local BAD_VOLUMES: { any } = { -0.5, 4.5, 0 / 0, "1", true }
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
		test.skip.suite("Audio file source volume", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function openCount(): number
	return symphonia.load().symphonia_open_count()
end

local function raisedMessage(work: () -> ...any): string?
	local succeeded, failure = pcall(work)

	return if succeeded then nil else tostring(failure)
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

local function readAll(source: audio.Source): { buffer }
	local packets = readPackets(source, MAX_PACKETS)

	if not source.ended then
		error(`the source did not end within {MAX_PACKETS} packets`)
	end

	return packets
end

local function maxOf(values: { number }, first: number?): number
	local result = 0

	for index = first or 1, #values do
		result = math.max(result, values[index] :: number)
	end

	return result
end

local function buildWithBrokenSetVolume(): (string?, number)
	local originalFromBuffer = symphonia.decoder.fromBuffer
	local destroyCount = 0
	local patchedFromBuffer = function(bytes: buffer | string, options: symphonia.DecoderOptions?)
		local decoder = originalFromBuffer(bytes, options)
		local originalDestroy = decoder.destroy

		decoder.setVolume = function()
			error("the volume broke", 0)
		end
		decoder.destroy = function(self)
			destroyCount += 1
			originalDestroy(self)
		end

		return decoder
	end
	local message = raisedMessage(function()
		symphonia.decoder.fromBuffer = patchedFromBuffer
		audio.fromEncoded(readFixture("tone.wav"), { volume = 0.5 })
	end)

	symphonia.decoder.fromBuffer = originalFromBuffer

	return message, destroyCount
end

return function()
	test.suite("Audio file source volume", function()
		test.case("a file source holds volume 1 by default and the option otherwise", function()
			local wav = readFixture("tone.wav")
			local defaultSource = audio.fromEncoded(wav)
			local quietSource = audio.fromEncoded(wav, { volume = 0.5 })
			local namedSource = audio.fromWAV(wav, { volume = 3 })

			check.equal(defaultSource.volume, 1)
			check.equal(quietSource.volume, 0.5)
			check.equal(namedSource.volume, 3)

			defaultSource:destroy()
			quietSource:destroy()
			namedSource:destroy()
		end)

		test.case("options.volume reaches the decoder: half the volume halves the level", function()
			local wav = readFixture("tone.wav")
			local fullSource = audio.fromEncoded(wav)
			local halfSource = audio.fromEncoded(wav, { volume = 0.5 })
			local fullPeak = maxOf(packetPeaks(readAll(fullSource)))
			local halfPeak = maxOf(packetPeaks(readAll(halfSource)))

			check.greater(fullPeak, PEAK_FLOOR)
			check.greater(halfPeak, fullPeak * HALF_LOW)
			check.lesser(halfPeak, fullPeak * HALF_HIGH)
		end)

		test.case("fromFile takes options.volume too", function()
			local source = audio.fromFile(`{FIXTURES}/tone.wav`, { volume = 0 })
			local peak = maxOf(packetPeaks(readAll(source)))

			check.equal(source.volume, 0)
			check.lesser(peak, SILENT_PEAK)
		end)

		test.case("a bad options.volume raises at the call and opens nothing", function()
			local wav = readFixture("tone.wav")
			local before = openCount()

			for _, volume in BAD_VOLUMES do
				check.equal(
					raisedMessage(function()
						audio.fromEncoded(wav, { volume = volume })
					end),
					BAD_VOLUME_MESSAGE
				)
				check.equal(
					raisedMessage(function()
						audio.fromFile(`{FIXTURES}/tone.wav`, { volume = volume })
					end),
					BAD_VOLUME_MESSAGE
				)
			end

			for _, name in NAMED_SOURCES do
				check.equal(
					raisedMessage(function()
						(audio :: any)[name](wav, { volume = 9 })
					end),
					BAD_VOLUME_MESSAGE
				)
			end

			check.equal(openCount(), before)
		end)

		test.case("source:setVolume mid-read changes the level at the next read", function()
			local source = audio.fromEncoded(readFixture("tone.wav"))
			local firstPackets = readPackets(source, PACKETS_PER_READ)

			source:setVolume(0)

			local laterPackets = readPackets(source, MAX_PACKETS)
			local firstPeak = maxOf(packetPeaks(firstPackets))
			local laterPeaks = packetPeaks(laterPackets)

			check.equal(source.volume, 0)
			check.greater(firstPeak, PEAK_FLOOR)
			check.lesser(maxOf(laterPeaks, SETTLED_PACKETS_AFTER_CHANGE), SILENT_PEAK)

			source:destroy()
		end)

		test.case("a setVolume failing at construction destroys the decoder and raises its error", function()
			local before = openCount()
			local message, destroyCount = buildWithBrokenSetVolume()

			check.equal(message, "the volume broke")
			check.equal(destroyCount, 1)
			check.equal(openCount(), before)
		end)

		test.case("source:setVolume raises outside 0 to 4 and keeps the old value", function()
			local source = audio.fromEncoded(readFixture("tone.wav"), { volume = 2 })

			for _, volume in BAD_VOLUMES do
				check.equal(
					raisedMessage(function()
						source:setVolume(volume)
					end),
					BAD_VOLUME_MESSAGE
				)
			end

			check.equal(source.volume, 2)

			source:destroy()
		end)

		test.case("source:setVolume on an Opus file source keeps the value", function()
			local source = audio.fromEncoded(readFixture("tone.opus"), { volume = 0.5 })

			check.equal(source.format, "opus")
			check.equal(source.volume, 0.5)

			source:setVolume(2)

			check.equal(source.volume, 2)

			source:destroy()
		end)

		test.case("source:setVolume raises after the source ended and on a source without a file", function()
			local fileSource = audio.fromEncoded(readFixture("tone.wav"))

			readAll(fileSource)

			check.equal(
				raisedMessage(function()
					fileSource:setVolume(0.5)
				end),
				"audio source has ended"
			)

			local pcmSource = audio.fromPCM(buffer.create(3840))

			check.equal(
				raisedMessage(function()
					pcmSource:setVolume(0.5)
				end),
				"audio source has no file decoder; volume applies to file sources"
			)
			check.equal(pcmSource.volume, 1)
		end)
	end)
end
