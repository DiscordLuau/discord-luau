local frktest = require("../../../luau_packages/frktest")
local logger = require("../luau_packages/logger")
local opus = require("../luau_packages/opus")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Jitter = require("../src/jitter")

local FRAME_SECONDS = 0.02
local IDLE_STOP_TICKS = 5
local PACKET_POOL_SIZE = 50
local WAIT_UNTIL_SECONDS = 2

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Jitter buffer", function() end)
	end
end

local encoder = opus.encoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS, opus.application.voip)
local packetPool: { buffer } = {}

for poolIndex = 1, PACKET_POOL_SIZE do
	local frame = buffer.create(opus.DISCORD_FRAME_SIZE * opus.DISCORD_CHANNELS * 2)

	for sampleIndex = 0, opus.DISCORD_FRAME_SIZE - 1 do
		local value = math.floor(8000 * math.sin(2 * math.pi * 440 * (poolIndex * 960 + sampleIndex) / 48000))

		buffer.writei16(frame, sampleIndex * 4, value)
		buffer.writei16(frame, sampleIndex * 4 + 2, value)
	end

	packetPool[poolIndex] = encoder:encode(frame)
end

local function packetFor(sequence: number): buffer
	return packetPool[(sequence % PACKET_POOL_SIZE) + 1]
end

local function steadyStream(firstSequence: number, count: number, startAt: number): { Delivery }
	local deliveries = {}

	for offset = 0, count - 1 do
		table.insert(deliveries, { at = startAt + offset * FRAME_SECONDS, sequence = (firstSequence + offset) % 65536 })
	end

	return deliveries
end

local function waitUntil(condition: () -> boolean)
	local deadline = os.clock() + WAIT_UNTIL_SECONDS

	while not condition() and os.clock() < deadline do
		stdPolyfills.task.wait(FRAME_SECONDS)
	end
end

local function runJitter(
	firstSequence: number,
	deliveries: { Delivery },
	settled: (outcome: Outcome) -> boolean
): Outcome
	local warnings: { string } = {}
	local jitterLogger = logger.new("JitterSpec")
	local jitter = Jitter.new(firstSequence, jitterLogger)
	local started = os.clock()
	local outcome: Outcome = {
		played = {},
		pcmTimes = {},
		warnings = warnings,
		isRunning = function()
			return jitter.running
		end,
	}

	jitterLogger:setSink(function(message: string)
		if string.find(message, "[WARN]", 1, true) or string.find(message, "[ERROR]", 1, true) then
			table.insert(warnings, message)
		end
	end)

	jitter:start(function(sequence: number)
		table.insert(outcome.played, sequence)
	end, function()
		table.insert(outcome.pcmTimes, os.clock() - started)
	end)

	table.sort(deliveries, function(first, second)
		return first.at < second.at
	end)

	for _, delivery in deliveries do
		local waitSeconds = started + delivery.at - os.clock()

		if waitSeconds > 0 then
			stdPolyfills.task.wait(waitSeconds)
		end

		jitter:push(delivery.sequence, packetFor(delivery.sequence))
	end

	waitUntil(function()
		return settled(outcome)
	end)

	jitter:destroy()

	return outcome
end

local function countLines(lines: { string }, text: string): number
	local count = 0

	for _, line in lines do
		if string.find(line, text, 1, true) then
			count += 1
		end
	end

	return count
end

local function countingDecoder(wrapped: opus.Decoder): any
	local decoder: any = { calls = 0, destroys = 0 }

	local function count(): buffer
		decoder.calls += 1

		return buffer.create(0)
	end

	decoder.decode = count
	decoder.decodeFec = count
	decoder.decodePLC = count

	function decoder.destroy()
		decoder.destroys += 1
		wrapped:destroy()
	end

	return decoder
end

local function playedAtLeast(count: number): (outcome: Outcome) -> boolean
	return function(outcome: Outcome): boolean
		return #outcome.played >= count
	end
end

type Delivery = { at: number, sequence: number }
type Outcome = {
	played: { number },
	pcmTimes: { number },
	warnings: { string },
	isRunning: () -> boolean,
}

return function()
	test.suite("Jitter buffer", function()
		test.case("plays every packet of a steady stream in order", function()
			local outcome = runJitter(1000, steadyStream(1000, 25, 0), playedAtLeast(25))

			check.equal(#outcome.played, 25)
			check.equal(outcome.played[1], 1000)
			check.equal(outcome.played[25], 1024)
			check.equal(#outcome.warnings, 0)
		end)

		test.case("plays every packet after the sender pauses", function()
			local deliveries = steadyStream(2000, 10, 0)

			for _, delivery in steadyStream(2010, 20, 0.2 + 0.12) do
				table.insert(deliveries, delivery)
			end

			local outcome = runJitter(2000, deliveries, playedAtLeast(30))

			check.equal(#outcome.played, 30)
		end)

		test.case("a late duplicate never rewinds playback", function()
			local deliveries = steadyStream(3000, 30, 0)

			table.insert(deliveries, { at = 0.5, sequence = 3005 })

			local outcome = runJitter(3000, deliveries, playedAtLeast(30))
			local repeated = false

			for index = 2, #outcome.played do
				if outcome.played[index] <= outcome.played[index - 1] then
					repeated = true
				end
			end

			check.equal(#outcome.played, 30)
			check.is_false(repeated)
		end)

		test.case("stops producing frames once the speaker goes quiet", function()
			local stoppedByItself = false
			local outcome = runJitter(4000, steadyStream(4000, 5, 0), function(current: Outcome): boolean
				stoppedByItself = #current.played >= 5 and not current.isRunning()

				return stoppedByItself
			end)

			check.equal(#outcome.played, 5)
			check.is_true(stoppedByItself)
			check.lesser_eq(#outcome.pcmTimes, 5 + IDLE_STOP_TICKS)
		end)

		test.case("resyncs after silence even when the sequence jumped far ahead", function()
			local deliveries = steadyStream(5000, 10, 0)

			for _, delivery in steadyStream(25000, 10, 0.5) do
				table.insert(deliveries, delivery)
			end

			local outcome = runJitter(5000, deliveries, playedAtLeast(20))

			check.equal(#outcome.played, 20)
			check.equal(outcome.played[11], 25000)
		end)

		test.case("can be destroyed from inside its own frame callback", function()
			local warnings: { string } = {}
			local jitterLogger = logger.new("JitterSpec")
			local jitter = Jitter.new(6000, jitterLogger)
			local played = 0
			local destroyError: string? = nil

			jitterLogger:setSink(function(message: string)
				if string.find(message, "[WARN]", 1, true) or string.find(message, "[ERROR]", 1, true) then
					table.insert(warnings, message)
				end
			end)

			jitter:start(function()
				local destroyed, errorMessage = xpcall(jitter.destroy :: (...any) -> ...any, debug.traceback, jitter)

				played += 1

				if not destroyed then
					destroyError = errorMessage
				end
			end, function() end)

			for offset = 0, 9 do
				jitter:push(6000 + offset, packetFor(6000 + offset))
			end

			stdPolyfills.task.wait(0.4)

			check.equal(destroyError, nil)
			check.equal(played, 1)
			check.equal(#warnings, 0)
		end)

		test.case("skips decoding while shouldDecode is false, then decodes with a new decoder", function()
			local lines: { string } = {}
			local jitterLogger = logger.new("JitterSpec")
			local jitter = Jitter.new(7000, jitterLogger)
			local standIn = countingDecoder(jitter.decoder)
			local decoding = false
			local rawFrames = 0
			local pcmFrames = 0

			jitterLogger:setSink(function(line: string)
				table.insert(lines, line)
			end)
			jitter.decoder = standIn
			jitter:start(function()
				rawFrames += 1
			end, function()
				pcmFrames += 1
			end, function()
				return decoding
			end)

			for offset = 0, 9 do
				jitter:push(7000 + offset, packetFor(7000 + offset))
				stdPolyfills.task.wait(FRAME_SECONDS)
			end

			waitUntil(function()
				return rawFrames > 0 and countLines(lines, "jitter decoding paused") == 1
			end)

			local pausedRawFrames = rawFrames
			local pausedPcmFrames = pcmFrames

			decoding = true

			for offset = 10, 19 do
				jitter:push(7000 + offset, packetFor(7000 + offset))
				stdPolyfills.task.wait(FRAME_SECONDS)
			end

			waitUntil(function()
				return standIn.destroys == 1 and pcmFrames > 0
			end)

			local renewedDecoder = jitter.decoder
			local destroysBeforeEnd = standIn.destroys

			jitter:destroy()

			check.is_true(pausedRawFrames > 0)
			check.equal(pausedPcmFrames, 0)
			check.equal(standIn.calls, 0)
			check.equal(destroysBeforeEnd, 1)
			check.equal(standIn.destroys, 1)
			check.is_true(renewedDecoder ~= standIn)
			check.is_true(pcmFrames > 0)
			check.equal(countLines(lines, "jitter decoding paused"), 1)
			check.equal(countLines(lines, "jitter decoding resumed"), 1)
		end)

		test.case("a shouldDecode that destroys the jitter leaves no decoder undestroyed or used", function()
			local jitterLogger = logger.new("JitterSpec")
			local jitter = Jitter.new(8000, jitterLogger)
			local standIn = countingDecoder(jitter.decoder)
			local asks = 0

			jitterLogger:setSink(function() end)
			jitter.decoder = standIn
			jitter:start(function() end, function() end, function()
				asks += 1

				if asks == 3 then
					jitter:destroy()
				end

				return asks >= 3
			end)

			for offset = 0, 9 do
				jitter:push(8000 + offset, packetFor(8000 + offset))
				stdPolyfills.task.wait(FRAME_SECONDS)
			end

			waitUntil(function()
				return asks >= 3
			end)

			local decoderAfterDestroy = jitter.decoder

			check.is_true(asks >= 3)
			check.is_true(decoderAfterDestroy == standIn)
			check.equal(standIn.destroys, 1)
			check.equal(standIn.calls, 0)
		end)

		test.case("a shouldDecode that destroys the jitter and then raises still has its error logged", function()
			local lines: { string } = {}
			local jitterLogger = logger.new("JitterSpec")
			local jitter = Jitter.new(8500, jitterLogger)
			local standIn = countingDecoder(jitter.decoder)
			local asked = false

			jitterLogger:setSink(function(line: string)
				table.insert(lines, line)
			end)
			jitter.decoder = standIn
			jitter:start(function() end, function() end, function(): boolean
				asked = true
				jitter:destroy()
				error("predicate exploded")
			end)

			for offset = 0, 9 do
				jitter:push(8500 + offset, packetFor(8500 + offset))
				stdPolyfills.task.wait(FRAME_SECONDS)
			end

			waitUntil(function()
				return asked and countLines(lines, "predicate exploded") > 0
			end)

			check.is_true(asked)
			check.is_true(countLines(lines, "predicate exploded") > 0)
			check.is_true(jitter.decoder == standIn)
			check.equal(standIn.destroys, 1)
			check.equal(standIn.calls, 0)
		end)

		test.case("a shouldDecode that yields is closed, warned about, and the slot decodes", function()
			local lines: { string } = {}
			local jitterLogger = logger.new("JitterSpec")
			local jitter = Jitter.new(9000, jitterLogger)
			local rawFrames = 0
			local pcmFrames = 0

			jitterLogger:setSink(function(line: string)
				table.insert(lines, line)
			end)
			jitter:start(function()
				rawFrames += 1
			end, function()
				pcmFrames += 1
			end, function(): boolean
				coroutine.yield()

				return false
			end)

			for offset = 0, 9 do
				jitter:push(9000 + offset, packetFor(9000 + offset))
				stdPolyfills.task.wait(FRAME_SECONDS)
			end

			waitUntil(function()
				return rawFrames >= 3 and pcmFrames > 0
			end)
			jitter:destroy()

			check.is_true(rawFrames >= 3)
			check.is_true(pcmFrames > 0)
			check.is_true(countLines(lines, "shouldDecode yielded") > 0)
		end)
	end)
end
