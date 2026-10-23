--[=[
	@class Symphonia.Limiter
	@__index Prototype

	Turns 48 kHz interleaved stereo 32-bit float audio into 16-bit PCM at a volume, through a look-ahead peak limiter,
	so audio that would pass full scale is turned down smoothly instead of clipped.

	- A non-finite sample (Inf or NaN) becomes 0 before anything else.
	- The volume, from 0 to 4, multiplies each sample. A change ramps linearly over 20 ms (960 frames), carried across
	calls of any size; a volume set before the first frame applies at once.
	- The limiter links both channels and looks 5 ms (240 frames) ahead. It keeps every sample within a per-sign
	ceiling, +32767/32768 for positive samples and -1.0 for negative ones, the values that scale to exactly 32767 and
	-32768. A reduction ramps in over the look-ahead, no frame's gain is ever above the gain that frame needs, and the
	gain rises back along a straight line over 50 ms to exactly 1.
	- Each sample is then scaled by 32768 and rounded. A clamp to the 16-bit range backs that up; it never engages,
	and `clampCount` counts it for tests.

	Audio that never passes the ceiling after the volume comes out bit for bit as a plain conversion would give it,
	only 240 frames late. `process` holds those frames back, so it returns fewer frames than it takes until the
	look-ahead is full, and `flush` returns them at the end, so as many frames leave as entered.
]=]

--[=[
	@prop volume number
	@within Symphonia.Limiter

	The volume `setVolume` last set, from 0 to 4; 1 until then.
]=]

--[=[
	@prop gain number
	@within Symphonia.Limiter

	The limiter's gain on the last frame that left, from 0 to 1: exactly 1 while nothing is reduced.
]=]

--[=[
	@prop clampCount number
	@within Symphonia.Limiter

	How many samples the backstop clamp has changed; for tests, since the limiter keeps it at 0.
]=]

--[=[
	@prop flushed boolean
	@within Symphonia.Limiter

	Whether `flush` has run, after which `process` raises.
]=]

--[=[
	@prop heldFrames number
	@within Symphonia.Limiter

	The frames that entered and have not left yet, up to the 240-frame look-ahead.
]=]

--[=[
	@prop LOOKAHEAD_FRAMES number
	@within Symphonia.Limiter

	The look-ahead in frames, 240 (5 ms at 48 kHz), on the module: output is late by exactly this much.
]=]

--[=[
	@prop heard boolean
	@within Symphonia.Limiter
	@private

	Whether a frame has been taken at some volume. Until one has, a new volume applies at once.
]=]

--[=[
	@prop rampFrom number
	@within Symphonia.Limiter
	@private

	The volume gain the current ramp started from.
]=]

--[=[
	@prop rampTo number
	@within Symphonia.Limiter
	@private

	The volume the current ramp ends at.
]=]

--[=[
	@prop rampPosition number
	@within Symphonia.Limiter
	@private

	The frames of the current ramp taken so far, up to 960, where the gain is exactly `rampTo`.
]=]

--[=[
	@prop delayLeft { number }
	@within Symphonia.Limiter
	@private

	The left samples of the held frames, after the volume, in a ring of 240 slots.
]=]

--[=[
	@prop delayRight { number }
	@within Symphonia.Limiter
	@private

	The right samples of the held frames, after the volume, in a ring of 240 slots.
]=]

--[=[
	@prop delayRequired { number }
	@within Symphonia.Limiter
	@private

	The gain each held frame needs to stay within the ceiling, in a ring of 240 slots.
]=]

--[=[
	@prop delayIndex number
	@within Symphonia.Limiter
	@private

	The slot the next frame enters: once 240 frames are held, the slot of the frame that leaves.
]=]

--[=[
	@prop enteredFrames number
	@within Symphonia.Limiter
	@private

	The frames taken in so far, counting the silence `flush` adds; the next frame's number.
]=]

--[=[
	@prop minimumFrames { number }
	@within Symphonia.Limiter
	@private

	The frame numbers of the candidates for the lowest required gain among the last 241 frames, in a ring of 241 slots,
	oldest first.
]=]

--[=[
	@prop minimumGains { number }
	@within Symphonia.Limiter
	@private

	The required gains of those candidates, strictly rising, so the first is the lowest.
]=]

--[=[
	@prop minimumFirst number
	@within Symphonia.Limiter
	@private

	The slot of the first candidate.
]=]

--[=[
	@prop minimumCount number
	@within Symphonia.Limiter
	@private

	How many candidates the ring holds.
]=]

--[=[
	@prop window { number }
	@within Symphonia.Limiter
	@private

	The lowest required gain in each of the last 240 windows of 241 frames, one window ending at each frame taken, in a
	ring of 240 slots. It starts full of 1s, for the windows that end before the audio.
]=]

--[=[
	@prop windowIndex number
	@within Symphonia.Limiter
	@private

	The slot of the oldest entry in `window`, which the next one replaces.
]=]

--[=[
	@prop windowSum number
	@within Symphonia.Limiter
	@private

	The running sum of `window`.
]=]

--[=[
	@prop windowReduced number
	@within Symphonia.Limiter
	@private

	How many entries of `window` are below 1. While none are, the sum is exactly 240 and the attack gain exactly 1.
]=]

--[=[
	@prop releaseFrom number
	@within Symphonia.Limiter
	@private

	The gain the current release rises from.
]=]

--[=[
	@prop releasePosition number
	@within Symphonia.Limiter
	@private

	The frames into the current release, up to 2400, where the release line reaches exactly 1.
]=]

local Sys = require("./sys")

local LOOKAHEAD_FRAMES = 240
local MINIMUM_SLOTS = LOOKAHEAD_FRAMES + 1
local RAMP_FRAMES = 960
local RELEASE_FRAMES = 2400
local POSITIVE_CEILING = 32767 / 32768
local NEGATIVE_CEILING = -1
local ONE_STEP_DOWN = 1 - 2 ^ -53
local FULL_SCALE = 32768
local SAMPLE_MIN = -32768
local SAMPLE_MAX = 32767
local FLOAT_BYTES = 4
local SAMPLE_BYTES = 2
local SILENCE = buffer.create(LOOKAHEAD_FRAMES * Sys.FLOAT_BYTES_PER_FRAME)

local Limiter = {}

Limiter.Interface = {
	LOOKAHEAD_FRAMES = LOOKAHEAD_FRAMES,
}
Limiter.Prototype = {}

local function finiteOrZero(sample: number): number
	return if sample == sample and math.abs(sample) ~= math.huge then sample else 0
end

-- The quotient rounds to the nearest double, so the sample times it can land one ulp beyond the ceiling; one step
-- down brings it back, and any lower gain stays within too, because rounding is monotone.
local function sampleGain(sample: number): number
	local gain = 1

	if sample > POSITIVE_CEILING or sample < NEGATIVE_CEILING then
		local ceiling = if sample > 0 then POSITIVE_CEILING else NEGATIVE_CEILING
		local quotient = ceiling / sample

		gain = if math.abs(sample * quotient) > math.abs(ceiling) then quotient * ONE_STEP_DOWN else quotient
	end

	return gain
end

local function rampGain(from: number, to: number, position: number): number
	return if position >= RAMP_FRAMES then to else from + (to - from) * position / RAMP_FRAMES
end

--[=[
	@within Symphonia.Limiter

	Sets the volume, a number from 0 to 4, where 1 leaves the audio as it is. A change ramps linearly over the next
	20 ms of frames taken; a volume set before the first frame applies at once.

	Raises `volume must be a number from 0 to 4` for a number outside that range, through `checkVolume`, keeping the old
	volume. Callers that take a volume from users check its type first, as `Decoder.checkVolume` does.
]=]
function Limiter.Prototype.setVolume(self: Limiter, volume: number)
	Limiter.Interface.checkVolume(volume)

	self.volume = volume
end

--[=[
	@within Symphonia.Limiter

	Takes `frames` frames of 48 kHz interleaved stereo 32-bit float samples from `floats` and returns the frames that
	leave, as interleaved stereo 16-bit little-endian PCM. The limiter holds the last 240 frames back, so the result is
	shorter than the input until that many have entered; blocks of any size give the same audio.

	Raises `limiter has been flushed` after `flush`, and `frames must be a whole number from 0 to <count>, the frames
	the buffer holds` when `frames` is negative, fractional or more than the buffer holds; a raise changes nothing.
]=]
function Limiter.Prototype.process(self: Limiter, floats: buffer, frames: number): buffer
	local bufferFrames = buffer.len(floats) // Sys.FLOAT_BYTES_PER_FRAME
	local leavingFrames = math.max(self.heldFrames + frames - LOOKAHEAD_FRAMES, 0)

	if self.flushed then
		error("limiter has been flushed", 0)
	end

	if not (frames >= 0 and frames <= bufferFrames and frames == math.floor(frames)) then
		error(`frames must be a whole number from 0 to {bufferFrames}, the frames the buffer holds`, 0)
	end

	local output = buffer.create(leavingFrames * Sys.BYTES_PER_FRAME)

	if frames > 0 then
		self:aimRamp()
	end

	self:limit(floats, frames, output)

	return output
end

--[=[
	@within Symphonia.Limiter

	The frames `process` must take to return `outputFrames`: that many, plus the part of the look-ahead not yet held,
	so the first call takes 240 more than it returns.
]=]
function Limiter.Prototype.framesNeeded(self: Limiter, outputFrames: number): number
	return outputFrames + LOOKAHEAD_FRAMES - self.heldFrames
end

--[=[
	@within Symphonia.Limiter

	Returns the frames still held, as 16-bit PCM, at the end of the audio, and only those: as many frames leave in all
	as entered, however few that is. They leave as if the audio had gone on in silence. A second call returns an empty
	buffer.
]=]
function Limiter.Prototype.flush(self: Limiter): buffer
	local output = buffer.create(self.heldFrames * Sys.BYTES_PER_FRAME)

	self:limit(SILENCE, LOOKAHEAD_FRAMES, output)
	self.heldFrames = 0
	self.flushed = true

	return output
end

--[=[
	@within Symphonia.Limiter
	@private

	Aims the volume ramp at `volume`, the value `setVolume` last set, before frames are taken. Until a frame has been
	taken, the volume applies at once. After that, a new volume starts a ramp from the gain the last frame took, so a
	change halfway through a ramp turns it without a jump.
]=]
function Limiter.Prototype.aimRamp(self: Limiter)
	if not self.heard then
		self.rampTo = self.volume
		self.heard = true
	elseif self.volume ~= self.rampTo then
		self.rampFrom = rampGain(self.rampFrom, self.rampTo, self.rampPosition)
		self.rampTo = self.volume
		self.rampPosition = 0
	end
end

--[=[
	@within Symphonia.Limiter
	@private

	Takes `frames` frames from `floats` through the volume ramp and the limiter, and writes each frame that leaves into
	`output` as 16-bit PCM.

	Each frame needs the largest gain that keeps both of its samples within the ceiling of their sign, or exactly 1.
	The gain on a leaving frame is the average of the lowest requirement in 240 windows of 241 frames, one ending at
	each frame of its look-ahead. Every one of those windows covers the leaving frame, so the average never exceeds
	what it needs, and a reduction ramps in linearly. The average is a running sum, which loses precision once
	requirements fall far below the sum's own rounding, so each frame's gain is also capped at its own requirement,
	which holds for any input. When that capped average allows more than the last frame's gain, the gain rises along
	the release line instead, never above the capped average.
]=]
function Limiter.Prototype.limit(self: Limiter, floats: buffer, frames: number, output: buffer)
	local delayLeft = self.delayLeft
	local delayRight = self.delayRight
	local delayRequired = self.delayRequired
	local minimumFrames = self.minimumFrames
	local minimumGains = self.minimumGains
	local window = self.window
	local rampFrom = self.rampFrom
	local rampTo = self.rampTo
	local rampPosition = self.rampPosition
	local heldFrames = self.heldFrames
	local delayIndex = self.delayIndex
	local enteredFrames = self.enteredFrames
	local minimumFirst = self.minimumFirst
	local minimumCount = self.minimumCount
	local windowIndex = self.windowIndex
	local windowSum = self.windowSum
	local windowReduced = self.windowReduced
	local gain = self.gain
	local releaseFrom = self.releaseFrom
	local releasePosition = self.releasePosition
	local clampCount = self.clampCount
	local written = 0

	for frame = 0, frames - 1 do
		local offset = frame * Sys.FLOAT_BYTES_PER_FRAME
		local rampStep = math.min(rampPosition + 1, RAMP_FRAMES)
		local volumeGain = rampGain(rampFrom, rampTo, rampStep)
		local left = finiteOrZero(buffer.readf32(floats, offset)) * volumeGain
		local right = finiteOrZero(buffer.readf32(floats, offset + FLOAT_BYTES)) * volumeGain
		local required = math.min(sampleGain(left), sampleGain(right))
		local leaving = heldFrames == LOOKAHEAD_FRAMES
		local leavingLeft = delayLeft[delayIndex]
		local leavingRight = delayRight[delayIndex]
		local leavingRequired = delayRequired[delayIndex]
		local oldest = window[windowIndex]

		rampPosition = rampStep
		delayLeft[delayIndex] = left
		delayRight[delayIndex] = right
		delayRequired[delayIndex] = required
		delayIndex = delayIndex % LOOKAHEAD_FRAMES + 1

		while minimumCount > 0 and minimumFrames[minimumFirst] + LOOKAHEAD_FRAMES < enteredFrames do
			minimumFirst = minimumFirst % MINIMUM_SLOTS + 1
			minimumCount -= 1
		end

		while minimumCount > 0 and minimumGains[(minimumFirst + minimumCount - 2) % MINIMUM_SLOTS + 1] >= required do
			minimumCount -= 1
		end

		local newest = (minimumFirst + minimumCount - 1) % MINIMUM_SLOTS + 1

		minimumFrames[newest] = enteredFrames
		minimumGains[newest] = required
		minimumCount += 1
		enteredFrames += 1

		local lowest = minimumGains[minimumFirst]

		window[windowIndex] = lowest
		windowIndex = windowIndex % LOOKAHEAD_FRAMES + 1
		windowReduced += (if lowest < 1 then 1 else 0) - (if oldest < 1 then 1 else 0)
		windowSum = if windowReduced == 0 then LOOKAHEAD_FRAMES else windowSum - oldest + lowest

		local attack = if windowReduced == 0 then 1 else math.min(windowSum / LOOKAHEAD_FRAMES, 1)

		if leaving then
			local capped = math.min(math.max(attack, 0), leavingRequired)
			local falling = capped <= gain
			local releaseStep = math.min(releasePosition + 1, RELEASE_FRAMES)
			local releaseLine = if releaseStep == RELEASE_FRAMES
				then 1
				else releaseFrom + (1 - releaseFrom) * releaseStep / RELEASE_FRAMES
			local frameGain = if falling then capped else math.min(releaseLine, capped)
			local scaledLeft = math.round(leavingLeft * frameGain * FULL_SCALE)
			local scaledRight = math.round(leavingRight * frameGain * FULL_SCALE)
			local sampleLeft = math.clamp(scaledLeft, SAMPLE_MIN, SAMPLE_MAX)
			local sampleRight = math.clamp(scaledRight, SAMPLE_MIN, SAMPLE_MAX)

			gain = frameGain
			releaseFrom = if falling then capped else releaseFrom
			releasePosition = if falling then 0 else releaseStep
			clampCount += (if sampleLeft == scaledLeft then 0 else 1) + (if sampleRight == scaledRight then 0 else 1)
			buffer.writei16(output, written * Sys.BYTES_PER_FRAME, sampleLeft)
			buffer.writei16(output, written * Sys.BYTES_PER_FRAME + SAMPLE_BYTES, sampleRight)
			written += 1
		else
			heldFrames += 1
		end
	end

	self.rampPosition = rampPosition
	self.heldFrames = heldFrames
	self.delayIndex = delayIndex
	self.enteredFrames = enteredFrames
	self.minimumFirst = minimumFirst
	self.minimumCount = minimumCount
	self.windowIndex = windowIndex
	self.windowSum = windowSum
	self.windowReduced = windowReduced
	self.gain = gain
	self.releaseFrom = releaseFrom
	self.releasePosition = releasePosition
	self.clampCount = clampCount
end

--[=[
	@within Symphonia.Limiter

	Raises `volume must be a number from 0 to 4` unless `volume` is in that range; NaN and Inf fail too. It owns the
	range and the message: `setVolume` uses it, and so does `Decoder.checkVolume`, which checks the type of a volume
	that users hand in before it gets here.
]=]
function Limiter.Interface.checkVolume(volume: number)
	if not (volume >= 0 and volume <= Sys.MAX_VOLUME) then
		error("volume must be a number from 0 to 4", 0)
	end
end

--[=[
	@within Symphonia.Limiter

	Creates a limiter at volume 1 that has taken nothing yet.
]=]
function Limiter.Interface.new(): Limiter
	return setmetatable(
		{
			volume = 1,
			gain = 1,
			clampCount = 0,
			flushed = false,
			heldFrames = 0,
			heard = false,
			rampFrom = 1,
			rampTo = 1,
			rampPosition = RAMP_FRAMES,
			delayLeft = table.create(LOOKAHEAD_FRAMES, 0),
			delayRight = table.create(LOOKAHEAD_FRAMES, 0),
			delayRequired = table.create(LOOKAHEAD_FRAMES, 1),
			delayIndex = 1,
			enteredFrames = 0,
			minimumFrames = table.create(MINIMUM_SLOTS, 0),
			minimumGains = table.create(MINIMUM_SLOTS, 1),
			minimumFirst = 1,
			minimumCount = 0,
			window = table.create(LOOKAHEAD_FRAMES, 1),
			windowIndex = 1,
			windowSum = LOOKAHEAD_FRAMES,
			windowReduced = 0,
			releaseFrom = 1,
			releasePosition = 0,
		} :: Limiter,
		{ __index = Limiter.Prototype }
	)
end

export type Limiter = typeof(Limiter.Prototype) & {
	volume: number,
	gain: number,
	clampCount: number,
	flushed: boolean,
	heldFrames: number,
	heard: boolean,
	rampFrom: number,
	rampTo: number,
	rampPosition: number,
	delayLeft: { number },
	delayRight: { number },
	delayRequired: { number },
	delayIndex: number,
	enteredFrames: number,
	minimumFrames: { number },
	minimumGains: { number },
	minimumFirst: number,
	minimumCount: number,
	window: { number },
	windowIndex: number,
	windowSum: number,
	windowReduced: number,
	releaseFrom: number,
	releasePosition: number,
}

return Limiter.Interface
