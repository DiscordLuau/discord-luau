local frktest = require("../../../luau_packages/frktest")
local opus = require("../luau_packages/opus")
local stdPolyfills = require("../luau_packages/std_polyfills")
local voice = require("../luau_packages/voice")

local audio = require("../src")

local FRAME_BYTES = 3840
local SAMPLE_BYTES = 4
local TONE_HERTZ = 440
local TONE_AMPLITUDE = 3000
local REFERENCE_BITRATE = 128000

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio sources", function() end)
	end
end

local function tone(byteCount: number): buffer
	local pcm = buffer.create(byteCount)

	for sampleIndex = 0, byteCount // SAMPLE_BYTES - 1 do
		local phase = 2 * math.pi * TONE_HERTZ * sampleIndex / opus.DISCORD_SAMPLE_RATE
		local sample = math.floor(math.sin(phase) * TONE_AMPLITUDE)

		buffer.writei16(pcm, sampleIndex * SAMPLE_BYTES, sample)
		buffer.writei16(pcm, sampleIndex * SAMPLE_BYTES + 2, sample)
	end

	return pcm
end

local function slice(source: buffer, offset: number, length: number): buffer
	local part = buffer.create(length)

	buffer.copy(part, 0, source, offset, length)

	return part
end

local function readAll(source: audio.Source): { buffer }
	local packets = {}
	local packet = source:read()

	while packet do
		table.insert(packets, packet)
		packet = source:read()
	end

	return packets
end

local function referencePackets(frames: { buffer }): { buffer }
	local encoder = opus.encoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS, opus.application.audio)
	local packets = {}

	encoder:setBitrate(REFERENCE_BITRATE)
	encoder:setSignal("music")

	for _, frame in frames do
		table.insert(packets, encoder:encode(frame))
	end

	encoder:destroy()

	return packets
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

local function countDestroys(source: audio.Source): () -> number
	local encoder = source.encoder :: any
	local destroy = encoder.destroy
	local count = 0

	encoder.destroy = function(...)
		count += 1

		return destroy(...)
	end

	return function()
		return count
	end
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

local function iterate(items: { any }): () -> any
	local index = 0

	return function()
		index += 1

		return items[index]
	end
end

return function()
	test.suite("Audio sources", function()
		test.case("fromOpus reads an array or a function in order, then nil, then nil with a debug line", function()
			local packets = { buffer.fromstring("\248\0\0"), buffer.fromstring("\248\1\1") }

			for _, source in { audio.fromOpus(packets), audio.fromOpus(iterate(packets)) } do
				local lines = captureLines(source)

				check.equal(source:read(), packets[1])
				check.equal(source:read(), packets[2])
				check.falsy(source:read())
				check.falsy(source:read())
				check.is_true(hasLine(lines, "read after the audio source ended"))
			end
		end)

		test.case("fromPCM cuts one buffer into 20 ms Opus packets and frees its encoder at the end", function()
			local source = audio.fromPCM(tone(3 * FRAME_BYTES))
			local packets = readAll(source)
			local decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)

			check.equal(#packets, 3)

			for _, packet in packets do
				check.equal(voice.opusSamples(packet), 960)
				check.equal(buffer.len(decoder:decode(packet)), FRAME_BYTES)
			end

			decoder:destroy()
			check.falsy(source.encoder)
		end)

		test.case("an array or a function of uneven buffers gives the same packets as one buffer", function()
			local pcm = tone(3 * FRAME_BYTES)
			local parts = { slice(pcm, 0, 1000), slice(pcm, 1000, 5000), slice(pcm, 6000, 5520) }
			local expected = readAll(audio.fromPCM(pcm))

			checkSamePackets(readAll(audio.fromPCM(parts)), expected)
			checkSamePackets(readAll(audio.fromPCM(iterate(parts))), expected)
		end)

		test.case("the last partial frame is zero-padded", function()
			local pcm = tone(FRAME_BYTES + 1000)
			local padded = buffer.create(FRAME_BYTES)

			buffer.copy(padded, 0, pcm, FRAME_BYTES, 1000)

			checkSamePackets(readAll(audio.fromPCM(pcm)), referencePackets({ slice(pcm, 0, FRAME_BYTES), padded }))
		end)

		test.case("empty buffers are skipped, and empty input ends at the first read without an encoder", function()
			local frame = tone(FRAME_BYTES)

			checkSamePackets(
				readAll(audio.fromPCM({ buffer.create(0), frame, buffer.create(0) })),
				referencePackets({ frame })
			)

			for _, source in
				{
					audio.fromPCM(buffer.create(0)),
					audio.fromPCM({}),
					audio.fromPCM(function(): buffer?
						return
					end),
				}
			do
				check.falsy(source:read())
				check.falsy(source.encoder)
				check.is_true(source.ended)
			end
		end)

		test.case("a function input is read only as the frames need it", function()
			local calls = 0
			local source = audio.fromPCM(function(): buffer?
				calls += 1

				return if calls <= 20 then buffer.create(1000) else nil
			end)

			source:read()
			check.equal(calls, 4)
			source:read()
			check.equal(calls, 8)
		end)

		test.case("a PCM total that is not a whole number of samples raises where it is first known", function()
			local parts = { tone(FRAME_BYTES), buffer.create(2) }
			local source = audio.fromPCM(iterate(parts))
			local message =
				"PCM input is 3842 bytes, which is not a whole number of samples (4 bytes each: 16-bit stereo)"

			check.is_true(raises(function()
				audio.fromPCM(buffer.create(3842))
			end, message))
			check.not_nil(source:read())
			check.is_true(raises(function()
				source:read()
			end, message))
		end)

		test.case("an item that is not a buffer and an input of the wrong kind raise", function()
			local source = audio.fromOpus({ buffer.create(3), "not a buffer" :: any })

			source:read()

			check.is_true(raises(function()
				source:read()
			end, "audio source item 2 is a string, not a buffer"))
			check.is_true(
				raises(
					function()
						audio.fromPCM(5 :: any)
					end,
					"audio.fromPCM takes a buffer of PCM, an array of buffers or a function that returns the next buffer"
				)
			)
			check.is_true(raises(function()
				audio.fromOpus(buffer.create(3) :: any)
			end, "audio.fromOpus takes an array of Opus packets or a function that returns the next one"))
		end)

		test.case("an iterator that raises ends the source, frees the encoder once and is not called again", function()
			local calls = 0
			local source = audio.fromPCM(function(): buffer?
				calls += 1

				if calls == 2 then
					error("iterator failed", 0)
				end

				return tone(FRAME_BYTES)
			end)

			check.not_nil(source:read())

			local destroyCount = countDestroys(source)

			check.is_true(raises(function()
				source:read()
			end, "iterator failed"))
			check.equal(destroyCount(), 1)
			check.is_true(source.ended)
			check.falsy(source.encoder)
			check.falsy(source:read())
			check.equal(calls, 2)
			check.equal(destroyCount(), 1)
		end)

		test.case("a destroy that raises does not replace the iterator's error, and is warned", function()
			local calls = 0
			local source = audio.fromPCM(function(): buffer?
				calls += 1

				if calls == 2 then
					error("iterator failed", 0)
				end

				return tone(FRAME_BYTES)
			end)

			check.not_nil(source:read())

			local lines = captureLines(source)
			local failing = source :: any
			local ran, failure = pcall(function()
				failing.destroy = function()
					error("destroy failed", 0)
				end

				source:read()
			end)

			check.falsy(ran)
			check.equal(failure, "iterator failed")
			check.is_true(hasLine(lines, "destroying the audio source failed: destroy failed"))

			failing.destroy = nil
			source:destroy()
			check.falsy(source.encoder)
		end)

		test.case("a misaligned PCM array frees the encoder once when read raises", function()
			local source = audio.fromPCM({ tone(FRAME_BYTES), buffer.create(2) })

			check.not_nil(source:read())

			local destroyCount = countDestroys(source)
			local lines = captureLines(source)

			check.is_true(raises(function()
				source:read()
			end, "PCM input is 3842 bytes, which is not a whole number of samples"))
			check.equal(destroyCount(), 1)
			check.is_true(source.ended)
			check.falsy(source.encoder)
			check.falsy(source:read())
			check.is_true(hasLine(lines, "read after the audio source ended"))
			check.equal(destroyCount(), 1)
		end)

		test.case("a source is claimed once, and a second destroy logs at debug", function()
			local source = audio.fromOpus({})
			local lines = captureLines(source)

			source:claim()

			check.is_true(raises(function()
				source:claim()
			end, "audio source has already been played"))

			source:destroy()
			source:destroy()

			check.is_true(hasLine(lines, "audio source already ended; nothing to free"))
		end)
	end)
end
