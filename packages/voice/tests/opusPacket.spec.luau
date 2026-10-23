local frktest = require("../../../luau_packages/frktest")

local opusPacket = require("../src/opusPacket")

local test = frktest.test
local check = frktest.assert.check

local function samplesOf(bytes: { number }): number
	local packet = buffer.create(#bytes)

	for index, byte in bytes do
		buffer.writeu8(packet, index - 1, byte)
	end

	return opusPacket.opusSamples(packet)
end

local function failureOf(bytes: { number }): string
	local counted, failure = pcall(samplesOf, bytes)

	return if counted then "no error" else tostring(failure)
end

return function()
	test.suite("Voice Opus packets", function()
		test.case("one frame takes its duration from the TOC config", function()
			check.equal(samplesOf({ 0x00 }), 480)
			check.equal(samplesOf({ 0x98 }), 960)
			check.equal(samplesOf({ 0x18 }), 2880)
			check.equal(samplesOf({ 0x68 }), 960)
		end)

		test.case("the Opus silence frame is 20 ms", function()
			check.equal(samplesOf({ 0xF8, 0xFF, 0xFE }), 960)
		end)

		test.case("code 1 carries two frames and code 3 counts its frames in the second byte", function()
			check.equal(samplesOf({ 0x09, 0x00 }), 1920)
			check.equal(samplesOf({ 0x93, 0xC3 }), 1440)
		end)

		test.case("malformed packets raise their exact message, with no file position", function()
			check.equal(failureOf({}), "invalid Opus packet: it is empty")
			check.equal(failureOf({ 0x93 }), "invalid Opus packet: code 3 without its frame count byte")
			check.equal(failureOf({ 0x93, 0x00 }), "invalid Opus packet: code 3 with 0 frames")
			check.equal(failureOf({ 0x1B, 0x03 }), "invalid Opus packet: 8640 samples is longer than 120 ms")
		end)
	end)
end
