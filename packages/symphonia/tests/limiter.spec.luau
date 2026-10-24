local frktest = require("../../../luau_packages/frktest")
local logger = require("../luau_packages/logger")

local Limiter = require("../src/limiter")

local FLOAT_BYTES = 4
local SAMPLE_BYTES = 2
local FLOAT_BYTES_PER_FRAME = 8
local PCM_BYTES_PER_FRAME = 4
local SAMPLE_RATE = 48000
local FULL_SCALE = 32768
local SAMPLE_MAX = 32767
local SAMPLE_MIN = -32768
local POSITIVE_CEILING = 32767 / 32768
local NEGATIVE_CEILING = -1
local MINUS_0_2_DBFS = 0.9772372
local LOOKAHEAD_FRAMES = 240
local RAMP_FRAMES = 960
local RELEASE_FRAMES = 2400
local TRANSPARENT_BEFORE_FRAMES = LOOKAHEAD_FRAMES + RELEASE_FRAMES + LOOKAHEAD_FRAMES
local BLOCK_SIZES = { 1, 7, 240, 241, 4800 }
local LENGTHS = { 0, 1, 2, 5, 100, 239, 240, 241, 480, 4800 }
local GAIN_TOLERANCE = 1e-12
local PEAK_FRAME = 3000
local PEAKED_FRAMES = 6000
local MINIMUM_LIMITED_PEAK = 32000
local RANDOM_SIGNALS_PER_LEVEL = 150
local RANDOM_MAX_FRAMES = 4000
local RANDOM_SPIKE_LEVELS = { 16, 1e3, 1e6, 1e9, 1e12, 1e15 }
local SWEEP_SPACING_FRAMES = 300
local SWEEP_SPIKES = 160
local SWEEP_LARGEST = 1e15
local RAMP_LEFT = 1000
local RAMP_RIGHT = 2000
local RAMP_BLOCK_FRAMES = 240
local RAMP_TOTAL_FRAMES = 5040
local MAX_LEFT_STEP = 3
local MAX_RIGHT_STEP = 5
local SPEED_SECONDS = 225
local SPEED_BLOCK_FRAMES = 4800
local MINIMUM_SPEED_FACTOR = 20
local BAD_VOLUME_MESSAGE = "volume must be a number from 0 to 4"
local CEILING_PEAKS = 600
local NEGATIVE_PEAK_EVERY = 5
local TIGHT_TOLERANCE = 1e-9
local GUARD_FRAMES = 480
local BAD_VOLUMES = { -0.01, 4.01, 5, 0 / 0, math.huge, -math.huge }

local test = frktest.test
local check = frktest.assert.check
local specLogger = logger.new("LimiterSpec", "Info")

local function randomGenerator(seed: number): () -> number
	local state = seed

	return function(): number
		state = bit32.bxor(state, bit32.lshift(state, 13))
		state = bit32.bxor(state, bit32.rshift(state, 17))
		state = bit32.bxor(state, bit32.lshift(state, 5))

		return state / 4294967296
	end
end

local function logUniform(random: () -> number, low: number, high: number): number
	return math.exp(math.log(low) + (math.log(high) - math.log(low)) * random())
end

local function randomSign(random: () -> number): number
	return if random() < 0.5 then 1 else -1
end

local function frameCount(floats: buffer): number
	return buffer.len(floats) // FLOAT_BYTES_PER_FRAME
end

local function setFrame(floats: buffer, frame: number, left: number, right: number)
	buffer.writef32(floats, frame * FLOAT_BYTES_PER_FRAME, left)
	buffer.writef32(floats, frame * FLOAT_BYTES_PER_FRAME + FLOAT_BYTES, right)
end

local function floatsFrom(frames: number, frameAt: (frame: number) -> (number, number)): buffer
	local floats = buffer.create(frames * FLOAT_BYTES_PER_FRAME)

	for frame = 0, frames - 1 do
		setFrame(floats, frame, frameAt(frame))
	end

	return floats
end

local function sine(frames: number, frequency: number, amplitude: number): buffer
	return floatsFrom(frames, function(frame: number)
		local sample = math.sin(frame * frequency * 2 * math.pi / SAMPLE_RATE) * amplitude

		return sample, sample
	end)
end

local function noise(random: () -> number, frames: number, low: number, high: number): buffer
	return floatsFrom(frames, function()
		return low + (high - low) * random(), low + (high - low) * random()
	end)
end

local function concatenate(chunks: { buffer }): buffer
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

local function block(floats: buffer, firstFrame: number, frames: number): buffer
	local slice = buffer.create(frames * FLOAT_BYTES_PER_FRAME)

	buffer.copy(slice, 0, floats, firstFrame * FLOAT_BYTES_PER_FRAME, frames * FLOAT_BYTES_PER_FRAME)

	return slice
end

local function processInBlocks(limiter: Limiter.Limiter, floats: buffer, blockFrames: number): { buffer }
	local frames = frameCount(floats)
	local chunks = {}

	for firstFrame = 0, frames - 1, blockFrames do
		local count = math.min(blockFrames, frames - firstFrame)

		table.insert(chunks, limiter:process(block(floats, firstFrame, count), count))
	end

	return chunks
end

local function limitInBlocks(limiter: Limiter.Limiter, floats: buffer, blockFrames: number): buffer
	local chunks = processInBlocks(limiter, floats, blockFrames)

	table.insert(chunks, limiter:flush())

	return concatenate(chunks)
end

local function plainSample(floats: buffer, sampleIndex: number): number
	local sample = buffer.readf32(floats, sampleIndex * FLOAT_BYTES)
	local finite = if sample == sample and math.abs(sample) ~= math.huge then sample else 0

	return math.round(finite * FULL_SCALE)
end

local function mismatch(pcm: buffer, floats: buffer): string?
	local sampleCount = buffer.len(floats) // FLOAT_BYTES
	local found = if buffer.len(pcm) ~= sampleCount * SAMPLE_BYTES
		then `{buffer.len(pcm) // SAMPLE_BYTES} samples came out, not {sampleCount}`
		else nil

	if not found then
		for sampleIndex = 0, sampleCount - 1 do
			local expected = plainSample(floats, sampleIndex)
			local actual = buffer.readi16(pcm, sampleIndex * SAMPLE_BYTES)

			if actual ~= expected then
				found = `sample {sampleIndex} is {actual}, not {expected}`

				break
			end
		end
	end

	return found
end

local function peakOf(pcm: buffer): number
	local peak = 0

	for offset = 0, buffer.len(pcm) - SAMPLE_BYTES, SAMPLE_BYTES do
		peak = math.max(peak, math.abs(buffer.readi16(pcm, offset)))
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

local function outputFrames(pcm: buffer): number
	return buffer.len(pcm) // PCM_BYTES_PER_FRAME
end

local function isOver(sample: number): boolean
	return sample > POSITIVE_CEILING or sample < NEGATIVE_CEILING
end

local function raisedMessage(work: () -> ...any): string?
	local succeeded, failure = pcall(work)

	return if succeeded then nil else tostring(failure)
end

local function withinTheCeiling(random: () -> number): buffer
	local floats = noise(random, 5000, NEGATIVE_CEILING, POSITIVE_CEILING)

	for frame = 1000, 2999 do
		local sample = math.sin(frame * 440 * 2 * math.pi / SAMPLE_RATE) * MINUS_0_2_DBFS

		setFrame(floats, frame, sample, -sample)
	end

	for frame = 3000, 4989 do
		setFrame(floats, frame, (random() - 0.5) * 0.02, (random() - 0.5) * 0.02)
	end

	for _, edge in { 10, 4990 } do
		setFrame(floats, edge, NEGATIVE_CEILING, POSITIVE_CEILING)
		setFrame(floats, edge + 1, POSITIVE_CEILING, NEGATIVE_CEILING)
		setFrame(floats, edge + 2, NEGATIVE_CEILING, NEGATIVE_CEILING)
		setFrame(floats, edge + 3, POSITIVE_CEILING, POSITIVE_CEILING)
		setFrame(floats, edge + 4, MINUS_0_2_DBFS, -MINUS_0_2_DBFS)
		setFrame(floats, edge + 5, NEGATIVE_CEILING, NEGATIVE_CEILING)
	end

	return floats
end

local function spikeSweep(random: () -> number): buffer
	local frames = SWEEP_SPIKES * SWEEP_SPACING_FRAMES
	local floats = noise(random, frames, -0.3, 0.3)

	for spike = 0, SWEEP_SPIKES - 1 do
		local magnitude = 1.0001 * (SWEEP_LARGEST / 1.0001) ^ (spike / (SWEEP_SPIKES - 1))
		local value = if spike % 2 == 0 then magnitude else -magnitude
		local frame = if spike == 0 then 0 elseif spike == 1 then 7 else spike * SWEEP_SPACING_FRAMES
		local side = spike % 3

		if spike == SWEEP_SPIKES - 1 then
			frame = frames - 3
		end

		if side == 0 then
			buffer.writef32(floats, frame * FLOAT_BYTES_PER_FRAME, value)
		elseif side == 1 then
			buffer.writef32(floats, frame * FLOAT_BYTES_PER_FRAME + FLOAT_BYTES, value)
		else
			setFrame(floats, frame, value, -value * 0.7)
		end
	end

	return floats
end

local function randomSignal(random: () -> number, largestSpike: number): buffer
	local frames = math.floor(random() * RANDOM_MAX_FRAMES)
	local level = logUniform(random, 0.001, 1)
	local floats = floatsFrom(frames, function()
		return randomSign(random) * random() * level, randomSign(random) * random() * level
	end)
	local spikeRuns = if frames > 0 then math.floor(random() * 8) else 0

	for _ = 1, spikeRuns do
		local edge = math.min(frames, LOOKAHEAD_FRAMES + 1)
		local placement = math.floor(random() * 4)
		local position = if placement == 0
			then math.floor(random() * edge)
			elseif placement == 1 then frames - 1 - math.floor(random() * edge)
			else math.floor(random() * frames)
		local side = math.floor(random() * 3)
		local value = randomSign(random) * logUniform(random, 0.9, largestSpike)
		local runFrames = 1 + math.floor(random() * 60)

		for frame = position, math.min(position + runFrames, frames) - 1 do
			if side == 0 then
				buffer.writef32(floats, frame * FLOAT_BYTES_PER_FRAME, value)
			elseif side == 1 then
				buffer.writef32(floats, frame * FLOAT_BYTES_PER_FRAME + FLOAT_BYTES, value)
			else
				setFrame(floats, frame, value, -value * 0.7)
			end
		end
	end

	return floats
end

local function checkRandomSignals(random: () -> number, largestSpike: number): { [string]: number }
	local tally = { clamps = 0, lengthBreaks = 0, transparencyBreaks = 0, tailBreaks = 0 }

	for _ = 1, RANDOM_SIGNALS_PER_LEVEL do
		local floats = randomSignal(random, largestSpike)
		local frames = frameCount(floats)
		local blockFrames = BLOCK_SIZES[1 + math.floor(random() * #BLOCK_SIZES)]
		local limiter = Limiter.new()
		local pcm = limitInBlocks(limiter, floats, blockFrames)
		local oversBefore = table.create(frames + 1, 0)
		local lastOver = -math.huge

		tally.clamps += limiter.clampCount

		for frame = 0, frames - 1 do
			local over = isOver(buffer.readf32(floats, frame * FLOAT_BYTES_PER_FRAME))
				or isOver(buffer.readf32(floats, frame * FLOAT_BYTES_PER_FRAME + FLOAT_BYTES))

			oversBefore[frame + 2] = oversBefore[frame + 1] + (if over then 1 else 0)
			lastOver = if over then frame else lastOver
		end

		if outputFrames(pcm) ~= frames then
			tally.lengthBreaks += 1
		else
			for frame = 0, frames - 1 do
				local low = math.max(frame - TRANSPARENT_BEFORE_FRAMES, 0)
				local high = math.min(frame + LOOKAHEAD_FRAMES + 1, frames)
				local exact = buffer.readi16(pcm, frame * PCM_BYTES_PER_FRAME) == plainSample(floats, frame * 2)
					and buffer.readi16(pcm, frame * PCM_BYTES_PER_FRAME + SAMPLE_BYTES)
						== plainSample(floats, frame * 2 + 1)

				if oversBefore[high + 1] == oversBefore[low + 1] and not exact then
					tally.transparencyBreaks += 1
				end

				if frame >= lastOver + LOOKAHEAD_FRAMES + RELEASE_FRAMES and not exact then
					tally.tailBreaks += 1
				end
			end
		end
	end

	return tally
end

local function limitPeaked(): (buffer, buffer, { number }, Limiter.Limiter)
	local floats = floatsFrom(PEAKED_FRAMES, function()
		return 0.25, 0.25
	end)
	local limiter = Limiter.new()
	local gains = table.create(PEAKED_FRAMES, -1)
	local pcmChunks = {}

	setFrame(floats, PEAK_FRAME, 2, 0.25)

	for frame = 0, PEAKED_FRAMES - 1 do
		local pcm = limiter:process(block(floats, frame, 1), 1)

		if outputFrames(pcm) == 1 then
			gains[frame - LOOKAHEAD_FRAMES + 1] = limiter.gain
		end

		table.insert(pcmChunks, pcm)
	end

	table.insert(pcmChunks, limiter:flush())

	return floats, concatenate(pcmChunks), gains, limiter
end

local function rampGainAt(frame: number): number
	return if frame < 960
		then 1
		elseif frame < 1920 then 1 + (frame - 959) / RAMP_FRAMES
		elseif frame < 2400 then 2
		elseif frame < 2880 then 2 + 2 * (frame - 2399) / RAMP_FRAMES
		elseif frame < 3840 then 3 - 2 * (frame - 2879) / RAMP_FRAMES
		else 1
end

return function()
	test.suite("Symphonia limiter", function()
		test.case("audio within the per-sign ceiling comes out bit for bit, in blocks of any size", function()
			local floats = withinTheCeiling(randomGenerator(0x2545F491))

			for _, blockFrames in { 1, 7, 240, 241, 4800, 5000 } do
				local limiter = Limiter.new()
				local pcm = limitInBlocks(limiter, floats, blockFrames)

				check.equal(mismatch(pcm, floats), nil)
				check.equal(limiter.clampCount, 0)
			end
		end)

		test.case("full scale is pulled to the ceiling of its sign, and -1.0 is left as -32768", function()
			local positive = floatsFrom(3000, function()
				return 0.25, -0.25
			end)
			local negative = floatsFrom(3000, function()
				return 0.25, -0.25
			end)

			setFrame(positive, 1000, 1, -1)
			setFrame(negative, 1000, -1, -1)

			local positiveLimiter = Limiter.new()
			local positivePcm = limitInBlocks(positiveLimiter, positive, 240)
			local negativeLimiter = Limiter.new()
			local negativePcm = limitInBlocks(negativeLimiter, negative, 240)

			check.equal(outputFrames(positivePcm), 3000)
			check.equal(buffer.readi16(positivePcm, 1000 * PCM_BYTES_PER_FRAME), SAMPLE_MAX)
			check.equal(buffer.readi16(positivePcm, 1000 * PCM_BYTES_PER_FRAME + SAMPLE_BYTES), -SAMPLE_MAX)
			check.equal(positiveLimiter.clampCount, 0)
			check.equal(mismatch(negativePcm, negative), nil)
			check.equal(negativeLimiter.clampCount, 0)
		end)

		test.case("a +6 dBFS 440 Hz sine never reaches the clamp and never holds full scale for 2 samples", function()
			local floats = sine(48000, 440, 2)
			local wholePcm = limitInBlocks(Limiter.new(), floats, 48000)

			for _, blockFrames in BLOCK_SIZES do
				local limiter = Limiter.new()
				local pcm = limitInBlocks(limiter, floats, blockFrames)

				check.equal(outputFrames(pcm), 48000)
				check.equal(limiter.clampCount, 0)
				check.greater(peakOf(pcm), MINIMUM_LIMITED_PEAK)
				check.lesser(longestFullScaleRun(pcm), 2)
				check.is_true(buffer.tostring(pcm) == buffer.tostring(wholePcm))
			end

			local raised = Limiter.new()

			raised:setVolume(4)

			local raisedPcm = limitInBlocks(raised, sine(48000, 440, 0.5), 960)

			check.equal(outputFrames(raisedPcm), 48000)
			check.equal(raised.clampCount, 0)
			check.greater(peakOf(raisedPcm), MINIMUM_LIMITED_PEAK)
			check.lesser(longestFullScaleRun(raisedPcm), 2)
		end)

		test.case("a 40 Hz sine at +12 dBFS, a full-scale 4 kHz sine and 4x noise never reach the clamp", function()
			local signals = {
				sine(48000, 40, 4),
				sine(48000, 4000, 1),
				noise(randomGenerator(0x27D4EB2F), 48000, -4, 4),
			}

			for _, floats in signals do
				local limiter = Limiter.new()
				local pcm = limitInBlocks(limiter, floats, 4800)

				check.equal(outputFrames(pcm), 48000)
				check.equal(limiter.clampCount, 0)
			end
		end)

		test.case("a sweep of spikes up to 1e15 never reaches the clamp and never holds full scale", function()
			local floats = spikeSweep(randomGenerator(0x9E3779B9))

			for _, blockFrames in { 240, 4800 } do
				local limiter = Limiter.new()
				local pcm = limitInBlocks(limiter, floats, blockFrames)

				check.equal(outputFrames(pcm), frameCount(floats))
				check.equal(limiter.clampCount, 0)
				check.greater(peakOf(pcm), MINIMUM_LIMITED_PEAK)
				check.lesser(longestFullScaleRun(pcm), 2)
			end
		end)

		test.case("random signals with runs of spikes up to 1e15 stay within the ceiling and transparent", function()
			local random = randomGenerator(0x7F4A7C15)

			for _, largestSpike in RANDOM_SPIKE_LEVELS do
				local tally = checkRandomSignals(random, largestSpike)

				check.equal(`{largestSpike}: {tally.clamps} clamps`, `{largestSpike}: 0 clamps`)
				check.equal(`{largestSpike}: {tally.lengthBreaks} lengths`, `{largestSpike}: 0 lengths`)
				check.equal(
					`{largestSpike}: {tally.transparencyBreaks} transparency breaks`,
					`{largestSpike}: 0 transparency breaks`
				)
				check.equal(`{largestSpike}: {tally.tailBreaks} tail breaks`, `{largestSpike}: 0 tail breaks`)
			end
		end)

		test.case("Inf and NaN become 0", function()
			local floats = floatsFrom(600, function()
				return 0.5, -0.5
			end)

			setFrame(floats, 100, math.huge, 0.5)
			setFrame(floats, 200, -math.huge, 0 / 0)
			setFrame(floats, 300, 0 / 0, -math.huge)
			setFrame(floats, 400, math.huge, math.huge)

			local limiter = Limiter.new()
			local pcm = limitInBlocks(limiter, floats, 240)

			check.equal(mismatch(pcm, floats), nil)
			check.equal(buffer.readi16(pcm, 400 * PCM_BYTES_PER_FRAME), 0)
			check.equal(buffer.readi16(pcm, 300 * PCM_BYTES_PER_FRAME + SAMPLE_BYTES), 0)
			check.equal(limiter.clampCount, 0)
		end)

		test.case("frame counts never change, including under 240 frames", function()
			local random = randomGenerator(0x1B873593)

			for _, frames in LENGTHS do
				for _, amplitude in { 0.5, 4 } do
					local floats = noise(random, frames, -amplitude, amplitude)

					for _, blockFrames in BLOCK_SIZES do
						local limiter = Limiter.new()
						local pcm = limitInBlocks(limiter, floats, blockFrames)

						check.equal(
							`{frames} frames at {amplitude} in blocks of {blockFrames}: {outputFrames(pcm)} out, {limiter.clampCount} clamps`,
							`{frames} frames at {amplitude} in blocks of {blockFrames}: {frames} out, 0 clamps`
						)
					end
				end
			end
		end)

		test.case("output is late by the look-ahead, and flush gives only the frames that entered", function()
			local random = randomGenerator(0x85EBCA6B)
			local floats = noise(random, 245, -0.5, 0.5)
			local limiter = Limiter.new()

			check.equal(outputFrames(limiter:process(block(floats, 0, 240), 240)), 0)
			check.equal(outputFrames(limiter:process(block(floats, 240, 5), 5)), 5)
			check.equal(outputFrames(limiter:flush()), 240)

			local filling = Limiter.new()
			local firstNeeded = filling:framesNeeded(4800)
			local firstOut = outputFrames(filling:process(noise(random, firstNeeded, -0.5, 0.5), firstNeeded))

			check.equal(firstNeeded, 4800 + LOOKAHEAD_FRAMES)
			check.equal(firstOut, 4800)
			check.equal(filling:framesNeeded(4800), 4800)
			check.equal(Limiter.LOOKAHEAD_FRAMES, LOOKAHEAD_FRAMES)

			local short = noise(random, 5, -0.5, 0.5)
			local shortLimiter = Limiter.new()

			check.equal(outputFrames(shortLimiter:process(short, 5)), 0)
			check.equal(mismatch(shortLimiter:flush(), short), nil)
			check.equal(outputFrames(shortLimiter:flush()), 0)
		end)

		test.case("process raises for a frame count the buffer does not hold, and changes nothing", function()
			local floats = sine(GUARD_FRAMES, 440, 2)
			local expected = limitInBlocks(Limiter.new(), floats, GUARD_FRAMES)
			local limiter = Limiter.new()
			local message = `frames must be a whole number from 0 to {GUARD_FRAMES}, the frames the buffer holds`

			for _, frames in { GUARD_FRAMES + 1, -1, 1.5 } do
				check.equal(
					raisedMessage(function()
						limiter:process(floats, frames)
					end),
					message
				)
			end

			check.is_true(buffer.tostring(limitInBlocks(limiter, floats, GUARD_FRAMES)) == buffer.tostring(expected))
		end)

		test.case("process after flush raises", function()
			local limiter = Limiter.new()

			limiter:process(sine(300, 440, 0.5), 300)
			limiter:flush()

			check.equal(
				raisedMessage(function()
					limiter:process(sine(10, 440, 0.5), 10)
				end),
				"limiter has been flushed"
			)
		end)

		test.case("a peak ramps in linearly over the look-ahead, and both sides take one gain", function()
			local _, pcm, gains, limiter = limitPeaked()
			local bottom = gains[PEAK_FRAME + 1]
			local attackErrors = 0
			local unlinked = 0

			for step = 0, LOOKAHEAD_FRAMES - 1 do
				local frame = PEAK_FRAME - LOOKAHEAD_FRAMES + step
				local expected = 1 - (1 - bottom) * (step + 1) / LOOKAHEAD_FRAMES
				local gain = gains[frame + 1]
				local sample = math.round(0.25 * gain * FULL_SCALE)
				local left = buffer.readi16(pcm, frame * PCM_BYTES_PER_FRAME)
				local right = buffer.readi16(pcm, frame * PCM_BYTES_PER_FRAME + SAMPLE_BYTES)

				attackErrors += if math.abs(gain - expected) <= GAIN_TOLERANCE then 0 else 1
				unlinked += if left == sample and right == sample then 0 else 1
			end

			check.equal(gains[PEAK_FRAME - LOOKAHEAD_FRAMES], 1)
			check.equal(attackErrors, 0)
			check.equal(unlinked, 0)
			check.equal(buffer.readi16(pcm, PEAK_FRAME * PCM_BYTES_PER_FRAME), math.round(2 * bottom * FULL_SCALE))
			check.equal(buffer.readi16(pcm, PEAK_FRAME * PCM_BYTES_PER_FRAME), SAMPLE_MAX)
			check.equal(
				buffer.readi16(pcm, PEAK_FRAME * PCM_BYTES_PER_FRAME + SAMPLE_BYTES),
				math.round(0.25 * bottom * FULL_SCALE)
			)
			check.equal(limiter.clampCount, 0)
		end)

		test.case("a peak leaves at a gain that keeps it exactly within the ceiling of its sign", function()
			local random = randomGenerator(0x68E31DA4)
			local floats = buffer.create((LOOKAHEAD_FRAMES + 1) * FLOAT_BYTES_PER_FRAME)
			local beyond = 0
			local loose = 0
			local unheld = 0

			for peakIndex = 1, CEILING_PEAKS do
				local sign = if peakIndex % NEGATIVE_PEAK_EVERY == 0 then -1 else 1
				local ceiling = if sign > 0 then POSITIVE_CEILING else NEGATIVE_CEILING
				local limiter = Limiter.new()

				setFrame(floats, 0, sign * logUniform(random, 1.000001, 16), 0)

				local pcm = limiter:process(floats, LOOKAHEAD_FRAMES + 1)
				local landed = buffer.readf32(floats, 0) * limiter.gain
				local sample = buffer.readi16(pcm, 0)

				beyond += if (sign > 0 and landed > ceiling) or (sign < 0 and landed < ceiling) then 1 else 0
				loose += if math.abs(landed - ceiling) <= TIGHT_TOLERANCE then 0 else 1
				unheld += if sample == math.round(ceiling * FULL_SCALE) and limiter.clampCount == 0 then 0 else 1
			end

			check.equal(beyond, 0)
			check.equal(loose, 0)
			check.equal(unheld, 0)
		end)

		test.case("the release is linear over 50 ms and ends at exactly 1", function()
			local floats, pcm, gains, limiter = limitPeaked()
			local bottom = gains[PEAK_FRAME + 1]
			local releaseEnd = PEAK_FRAME + RELEASE_FRAMES
			local releaseErrors = 0
			local endedEarly = 0
			local tail = buffer.create((PEAKED_FRAMES - releaseEnd) * FLOAT_BYTES_PER_FRAME)
			local tailPcm = buffer.create((PEAKED_FRAMES - releaseEnd) * PCM_BYTES_PER_FRAME)

			for step = 1, RELEASE_FRAMES - 1 do
				local expected = bottom + (1 - bottom) * step / RELEASE_FRAMES
				local gain = gains[PEAK_FRAME + step + 1]

				releaseErrors += if math.abs(gain - expected) <= GAIN_TOLERANCE then 0 else 1
				endedEarly += if gain < 1 then 0 else 1
			end

			buffer.copy(tail, 0, floats, releaseEnd * FLOAT_BYTES_PER_FRAME)
			buffer.copy(tailPcm, 0, pcm, releaseEnd * PCM_BYTES_PER_FRAME)

			check.lesser_eq(math.abs(bottom - POSITIVE_CEILING / 2), GAIN_TOLERANCE)
			check.equal(gains[PEAK_FRAME - LOOKAHEAD_FRAMES], 1)
			check.lesser(gains[PEAK_FRAME - LOOKAHEAD_FRAMES + 1], 1)
			check.equal(releaseErrors, 0)
			check.equal(endedEarly, 0)
			check.equal(gains[releaseEnd + 1], 1)
			check.equal(mismatch(tailPcm, tail), nil)
			check.equal(limiter.clampCount, 0)
		end)

		test.case("a volume set before the first frame applies at once", function()
			local floats = floatsFrom(480, function()
				return RAMP_LEFT / FULL_SCALE, RAMP_RIGHT / FULL_SCALE
			end)
			local limiter = Limiter.new()

			limiter:setVolume(0.5)

			local pcm = limitInBlocks(limiter, floats, 240)

			check.equal(limiter.volume, 0.5)
			check.equal(outputFrames(pcm), 480)
			check.equal(buffer.readi16(pcm, 0), RAMP_LEFT / 2)
			check.equal(buffer.readi16(pcm, SAMPLE_BYTES), RAMP_RIGHT / 2)
			check.equal(peakOf(pcm), RAMP_RIGHT / 2)
		end)

		test.case("the 20 ms ramp carries across 240-frame blocks and turns mid-ramp without a jump", function()
			local floats = floatsFrom(RAMP_TOTAL_FRAMES, function()
				return RAMP_LEFT / FULL_SCALE, RAMP_RIGHT / FULL_SCALE
			end)
			local volumeAt = { [960] = 2, [2400] = 4, [2880] = 1 }
			local limiter = Limiter.new()
			local chunks = {}

			for firstFrame = 0, RAMP_TOTAL_FRAMES - 1, RAMP_BLOCK_FRAMES do
				local volume = volumeAt[firstFrame]

				if volume then
					limiter:setVolume(volume)
				end

				table.insert(chunks, limiter:process(block(floats, firstFrame, RAMP_BLOCK_FRAMES), RAMP_BLOCK_FRAMES))
			end

			table.insert(chunks, limiter:flush())

			local pcm = concatenate(chunks)
			local offLine = 0
			local inexact = 0
			local largestLeftStep = 0
			local largestRightStep = 0

			check.equal(outputFrames(pcm), RAMP_TOTAL_FRAMES)

			for frame = 0, math.min(outputFrames(pcm), RAMP_TOTAL_FRAMES) - 1 do
				local gain = rampGainAt(frame)
				local left = buffer.readi16(pcm, frame * PCM_BYTES_PER_FRAME)
				local right = buffer.readi16(pcm, frame * PCM_BYTES_PER_FRAME + SAMPLE_BYTES)
				local settled = gain == 1 or gain == 2

				offLine += if math.abs(left - RAMP_LEFT * gain) <= 1
						and math.abs(right - RAMP_RIGHT * gain) <= 1
					then 0
					else 1
				inexact += if not settled or (left == RAMP_LEFT * gain and right == RAMP_RIGHT * gain) then 0 else 1

				if frame > 0 then
					largestLeftStep = math.max(
						largestLeftStep,
						math.abs(left - buffer.readi16(pcm, (frame - 1) * PCM_BYTES_PER_FRAME))
					)
					largestRightStep = math.max(
						largestRightStep,
						math.abs(right - buffer.readi16(pcm, (frame - 1) * PCM_BYTES_PER_FRAME + SAMPLE_BYTES))
					)
				end
			end

			check.equal(offLine, 0)
			check.equal(inexact, 0)
			check.lesser_eq(largestLeftStep, MAX_LEFT_STEP)
			check.lesser_eq(largestRightStep, MAX_RIGHT_STEP)
			check.greater_eq(peakOf(pcm), RAMP_RIGHT * 3 - 1)
		end)

		test.case("setVolume and checkVolume take 0 to 4 and raise otherwise, keeping the old value", function()
			local limiter = Limiter.new()

			check.equal(limiter.volume, 1)

			for _, volume in { 0, 0.5, 1, 2.5, 4 } do
				limiter:setVolume(volume)

				check.equal(limiter.volume, volume)
				check.equal(
					raisedMessage(function()
						Limiter.checkVolume(volume)
					end),
					nil
				)
			end

			limiter:setVolume(2)

			for _, volume in BAD_VOLUMES do
				check.equal(
					raisedMessage(function()
						limiter:setVolume(volume)
					end),
					BAD_VOLUME_MESSAGE
				)
				check.equal(
					raisedMessage(function()
						Limiter.checkVolume(volume)
					end),
					BAD_VOLUME_MESSAGE
				)
				check.equal(limiter.volume, 2)
			end
		end)

		test.case("225 s of stereo audio is limited at least 20x faster than real time", function()
			local floats = sine(SPEED_BLOCK_FRAMES, 440, 2)
			local blocks = SPEED_SECONDS * SAMPLE_RATE // SPEED_BLOCK_FRAMES
			local limiter = Limiter.new()
			local framesOut = 0
			local startedAt = os.clock()

			for _ = 1, blocks do
				framesOut += outputFrames(limiter:process(floats, SPEED_BLOCK_FRAMES))
			end

			local flushedFrames = outputFrames(limiter:flush())
			local elapsedSeconds = os.clock() - startedAt
			local factor = SPEED_SECONDS / elapsedSeconds

			specLogger:info(
				`limited {SPEED_SECONDS} s of stereo audio in {string.format("%.3f", elapsedSeconds)} s, {string.format(
					"%.1f",
					factor
				)}x real time`
			)

			check.equal(framesOut + flushedFrames, blocks * SPEED_BLOCK_FRAMES)
			check.equal(limiter.clampCount, 0)
			check.greater_eq(factor, MINIMUM_SPEED_FACTOR)
		end)
	end)
end
