--[=[
	@class Voice.Jitter
	@__index Prototype

	Per-SSRC jitter buffer for the voice receive pipeline.

	Holds incoming Opus packets indexed by RTP sequence number and replays them at a steady 20ms rate
	after an initial four-frame delay. Gaps in the sequence are filled via FEC (if the next packet is
	already buffered) or Opus PLC, so the consumer always receives a continuous PCM stream.

	The tick loop uses clock-anchored absolute deadlines to prevent timing drift over long calls. If
	the speaker stops talking and resumes (VAD silence gap), the buffer detects the discontinuity and
	resyncs automatically.
]=]

--[=[
	@prop packets { [number]: buffer }
	@within Voice.Jitter
]=]

--[=[
	@prop nextSequence number
	@within Voice.Jitter
]=]

--[=[
	@prop stopped boolean
	@within Voice.Jitter
]=]

--[=[
	@prop clockAnchor number
	@within Voice.Jitter
]=]

--[=[
	@prop tickCount number
	@within Voice.Jitter
]=]

--[=[
	@prop thread thread?
	@within Voice.Jitter
]=]

--[=[
	@prop decoder opus.Decoder
	@within Voice.Jitter
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local opus = require("../luau_packages/opus")
local util = require("../luau_packages/util")

local FRAME_DURATION = 0.02
local BUFFER_DEPTH = 4

local Jitter = {}

Jitter.Interface = {}
Jitter.Prototype = {}

local function seqDiff(a: number, b: number): number
	local diff = bit32.band(a - b, 0xFFFF)
	return if diff > 32767 then diff - 65536 else diff
end

local function seqAdd(sequence: number, delta: number): number
	return bit32.band(sequence + delta, 0xFFFF)
end

--[=[
	@within Voice.Jitter

	Inserts an Opus packet for the given RTP sequence number. Packets that have already been played or
	are implausibly far ahead are silently discarded. Detects VAD silence gaps and resyncs the buffer.
]=]
function Jitter.Prototype.push(self: Jitter, sequence: number, packet: buffer)
	local diff = seqDiff(sequence, self.nextSequence)

	-- tick loop drifted ahead during a VAD silence gap - resync to this packet
	-- and re-apply the initial delay so the buffer has time to fill again
	if diff < -BUFFER_DEPTH then
		table.clear(self.packets)
		self.nextSequence = sequence
		self.clockAnchor = os.clock() + BUFFER_DEPTH * FRAME_DURATION
		self.tickCount = 0
		diff = 0
	end

	if diff < 0 or diff > BUFFER_DEPTH * 2 then
		return
	end

	self.packets[sequence] = packet
end

--[=[
	@within Voice.Jitter

	Starts the 20ms tick loop. Fires `onRawFrame(sequence, packet)` when a packet was present in the
	buffer, and `onPcmFrame(pcm)` for every slot whether a packet was present or not, filling gaps
	with FEC from the next buffered packet or Opus PLC.
]=]
function Jitter.Prototype.start(
	self: Jitter,
	onRawFrame: (sequence: number, packet: buffer) -> (),
	onPcmFrame: (pcm: buffer) -> ()
)
	self.thread = util.coroutineRun(function()
		stdPolyfills.task.wait(BUFFER_DEPTH * FRAME_DURATION)

		-- anchor the clock so every tick targets an absolute time, not a relative one,
		-- preventing drift from accumulating over long calls
		self.clockAnchor = os.clock()
		self.tickCount = 0

		while not self.stopped do
			local sequence = self.nextSequence
			local packet = self.packets[sequence]
			self.packets[sequence] = nil
			self.nextSequence = seqAdd(sequence, 1)
			self.tickCount += 1

			local pcm: buffer?

			if packet then
				onRawFrame(sequence, packet)

				local ok, result = pcall(self.decoder.decode, self.decoder, packet)

				if ok then
					pcm = result :: buffer
				end
			else
				local nextPacket = self.packets[self.nextSequence]

				if nextPacket then
					local ok, result = pcall(self.decoder.decodeFec, self.decoder, nextPacket)

					if ok then
						pcm = result :: buffer
					end
				end

				if not pcm then
					local ok, result = pcall(self.decoder.decodePLC, self.decoder)

					if ok then
						pcm = result :: buffer
					end
				end
			end

			if pcm then
				onPcmFrame(pcm)
			end

			local nextDeadline = self.clockAnchor + self.tickCount * FRAME_DURATION
			local remaining = nextDeadline - os.clock()

			if remaining > 0 then
				stdPolyfills.task.wait(remaining)
			end
			-- if remaining <= 0 the tick already ran late; immediately process the next frame to catch up
		end
	end)
end

--[=[
	@within Voice.Jitter

	Stops the tick loop and frees the Opus decoder. Must not be called more than once.
]=]
function Jitter.Prototype.destroy(self: Jitter)
	self.stopped = true

	if self.thread then
		coroutine.close(self.thread)
		self.thread = nil
	end

	self.decoder:destroy()
end

--[=[
	@within Voice.Jitter

	Responsible for constructing this class.
]=]
function Jitter.Interface.new(firstSequence: number): Jitter
	return setmetatable(
		{
			packets = {},
			nextSequence = firstSequence,
			stopped = false,
			clockAnchor = 0,
			tickCount = 0,
			decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS),
		} :: Jitter,
		{ __index = Jitter.Prototype }
	)
end

export type Jitter = typeof(Jitter.Prototype) & {
	packets: { [number]: buffer },
	nextSequence: number,
	stopped: boolean,
	clockAnchor: number,
	tickCount: number,
	thread: thread?,
	decoder: opus.Decoder,
}

return Jitter.Interface
