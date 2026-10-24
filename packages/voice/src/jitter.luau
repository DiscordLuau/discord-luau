--[=[
	@class Voice.Jitter
	@__index Prototype

	Per-SSRC jitter buffer for the voice receive pipeline.

	Holds incoming Opus packets indexed by RTP sequence number and replays them at a steady 20ms rate
	after an initial four-frame delay. Gaps in the sequence are filled via FEC (if the next packet is
	already buffered) or Opus PLC, so the consumer receives a continuous PCM stream while the speaker talks.

	The tick loop runs only while audio is arriving: after five empty slots with nothing buffered it
	stops, and the next pushed packet resyncs and restarts it. A packet that arrives after a pause, far
	ahead of the expected sequence, or into an empty buffer resyncs the stream; any other late packet is
	dropped, so playback never rewinds.
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

	True once `destroy` has been called.
]=]

--[=[
	@prop running boolean
	@within Voice.Jitter

	True while the tick loop is producing frames.
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
	@prop emptyTicks number
	@within Voice.Jitter

	Consecutive slots that had no packet.
]=]

--[=[
	@prop lastPushClock number
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

--[=[
	@prop shouldDecode (() -> boolean)?
	@within Voice.Jitter

	Asked once per slot whether to decode it; nil decodes every slot.
]=]

--[=[
	@prop decoding boolean
	@within Voice.Jitter

	The latest answer from `shouldDecode`, so each change is logged once.
]=]

--[=[
	@prop decoderStale boolean
	@within Voice.Jitter

	True from the slot decoding resumes until a new decoder has replaced the one that sat idle.
]=]

--[=[
	@prop logger logger.Logger
	@within Voice.Jitter
]=]

--[=[
	@prop onRawFrame ((sequence: number, packet: buffer) -> ())?
	@within Voice.Jitter
]=]

--[=[
	@prop onPcmFrame ((pcm: buffer) -> ())?
	@within Voice.Jitter
]=]

local logger = require("../luau_packages/logger")
local opus = require("../luau_packages/opus")
local stdPolyfills = require("../luau_packages/std_polyfills")

local FRAME_DURATION = 0.02
local BUFFER_DEPTH = 4
local IDLE_STOP_TICKS = 5
local IDLE_RESYNC_SECONDS = 0.08

local Jitter = {}

Jitter.Interface = {}
Jitter.Prototype = {}

local function sequenceDifference(sequence: number, reference: number): number
	local difference = bit32.band(sequence - reference, 0xFFFF)

	return if difference > 32767 then difference - 65536 else difference
end

local function sequenceAdd(sequence: number, delta: number): number
	return bit32.band(sequence + delta, 0xFFFF)
end

--[=[
	@within Voice.Jitter

	Inserts an Opus packet for the given RTP sequence number, resyncing and restarting the tick loop
	when the stream was idle, jumped far ahead, or ran dry. Other late packets are dropped.
]=]
function Jitter.Prototype.push(self: Jitter, sequence: number, packet: buffer)
	local now = os.clock()
	local difference = sequenceDifference(sequence, self.nextSequence)
	local idle = not self.running or now - self.lastPushClock > IDLE_RESYNC_SECONDS
	local underrun = difference < 0 and not next(self.packets)

	if self.stopped then
		self.logger:debug(`jitter is destroyed, dropping packet {sequence}`)

		return
	end

	self.lastPushClock = now

	if idle or underrun or difference > BUFFER_DEPTH * 2 then
		self:resync(sequence, now)
	elseif difference < 0 then
		self.logger:debug(`dropping late packet {sequence}, already playing {self.nextSequence}`)

		return
	end

	self.packets[sequence] = packet

	if not self.running and self.onRawFrame then
		self:startLoop()
	end
end

--[=[
	@within Voice.Jitter

	Starts producing frames. `onRawFrame(sequence, packet)` fires for each packet that was present in its
	slot and `onPcmFrame(pcm)` for every slot while audio is arriving, filling gaps with FEC from the next
	buffered packet or Opus PLC. `shouldDecode`, when given, is asked once per slot: while it returns false the slot
	skips decoding, FEC and PLC, so `onPcmFrame` does not fire while `onRawFrame` still does, and when it returns true
	again a new decoder takes over. `shouldDecode` must return without yielding; one that yields is closed and warned
	about, and the slot decodes. Errors raised by any callback are logged at warn and do not stop the loop.
]=]
function Jitter.Prototype.start(
	self: Jitter,
	onRawFrame: (sequence: number, packet: buffer) -> (),
	onPcmFrame: (pcm: buffer) -> (),
	shouldDecode: (() -> boolean)?
)
	self.onRawFrame = onRawFrame
	self.onPcmFrame = onPcmFrame
	self.shouldDecode = shouldDecode

	if next(self.packets) then
		self:startLoop()
	end
end

--[=[
	@within Voice.Jitter
	@private

	Drops everything buffered and restarts the schedule at `sequence`, four frames from now.
]=]
function Jitter.Prototype.resync(self: Jitter, sequence: number, now: number)
	table.clear(self.packets)

	self.nextSequence = sequence
	self.clockAnchor = now + BUFFER_DEPTH * FRAME_DURATION
	self.tickCount = 0
	self.emptyTicks = 0
end

--[=[
	@within Voice.Jitter
	@private

	Runs a frame callback, logging any error at warn with its traceback.
]=]
function Jitter.Prototype.deliver(self: Jitter, callback: (...any) -> (), ...: any)
	local delivered, deliveryError = xpcall(callback :: (...any) -> ...any, debug.traceback, ...)

	if not delivered then
		self.logger:warn(`jitter frame callback errored:\n{deliveryError}`)
	end
end

--[=[
	@within Voice.Jitter
	@private

	Asks `shouldDecode` whether this slot decodes, logging at debug when the answer changes. When decoding resumes, the
	decoder that sat idle is replaced before the next decode, so concealment never runs on stale state; while a new one
	cannot be created, slots skip decoding and each tries again. Returns whether this slot decodes.
]=]
function Jitter.Prototype.prepareDecoder(self: Jitter): boolean
	local shouldDecode = self.shouldDecode
	local failure: string? = nil
	local answer: any = true

	if shouldDecode then
		local asker = coroutine.create(shouldDecode)
		local asked, result = coroutine.resume(asker)

		if not asked then
			failure = `jitter shouldDecode errored, decoding this slot: {result}`
		elseif coroutine.status(asker) == "suspended" then
			local closed, closeError = coroutine.close(asker)

			failure = `jitter shouldDecode yielded; it must return without yielding, decoding this slot`
				.. if closed then "" else ` (closing it failed: {closeError})`
		else
			answer = result
		end
	end

	if failure then
		self.logger:warn(failure)
	end

	if self.stopped then
		self.logger:debug(`jitter destroyed by shouldDecode; skipping this slot`)

		return false
	end

	local wanted = if failure then true else answer == true

	if wanted ~= self.decoding then
		self.decoding = wanted
		self.decoderStale = wanted
		self.logger:debug(if wanted then `jitter decoding resumed` else `jitter decoding paused; raw frames still play`)
	end

	if wanted and self.decoderStale then
		self:renewDecoder()
	end

	return wanted and not self.decoderStale
end

--[=[
	@within Voice.Jitter
	@private

	Replaces the decoder with a new one and destroys the old. When the new one cannot be created it logs at warn and
	keeps the old one, still marked stale, so the slot skips decoding and the next slot tries again.
]=]
function Jitter.Prototype.renewDecoder(self: Jitter)
	local created, decoder = pcall(opus.decoder.new, opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)

	if not created then
		self.logger:warn(`jitter could not create a new Opus decoder, trying again next slot: {decoder}`)

		return
	end

	self.decoder:destroy()
	self.decoder = decoder
	self.decoderStale = false
end

--[=[
	@within Voice.Jitter
	@private

	Decodes the packet for one slot, falling back to FEC from the next packet and then to PLC.
]=]
function Jitter.Prototype.decodeSlot(self: Jitter, packet: buffer?): buffer?
	local nextPacket = self.packets[self.nextSequence]

	if packet then
		local decoded, pcm = pcall(self.decoder.decode, self.decoder, packet)

		if decoded then
			return pcm
		end

		self.logger:warn(`jitter could not decode a packet, concealing it instead: {pcm}`)
	elseif nextPacket then
		local recovered, pcm = pcall(self.decoder.decodeFec, self.decoder, nextPacket)

		if recovered then
			return pcm
		end

		self.logger:debug(`jitter could not recover a lost packet from FEC, concealing it instead: {pcm}`)
	end

	local concealed, pcm = pcall(self.decoder.decodePLC, self.decoder)

	if concealed then
		return pcm
	end

	if self.stopped then
		self.logger:debug(`jitter was destroyed during packet loss concealment: {pcm}`)
	else
		self.logger:warn(`jitter packet loss concealment failed: {pcm}`)
	end

	return
end

--[=[
	@within Voice.Jitter
	@private

	Starts the tick loop thread, which waits for each slot's deadline, plays it, and ends itself once
	the stream has been empty for `IDLE_STOP_TICKS` slots.
]=]
function Jitter.Prototype.startLoop(self: Jitter)
	local thread = coroutine.create(function()
		while not self.stopped do
			local deadline = self.clockAnchor + self.tickCount * FRAME_DURATION
			local remaining = deadline - os.clock()

			if remaining > 0 then
				stdPolyfills.task.wait(remaining)

				continue
			end

			local sequence = self.nextSequence
			local packet = self.packets[sequence]

			self.packets[sequence] = nil
			self.nextSequence = sequenceAdd(sequence, 1)
			self.tickCount += 1

			if packet then
				self.emptyTicks = 0

				self:deliver(self.onRawFrame :: any, sequence, packet)
			else
				self.emptyTicks += 1
			end

			if self.stopped then
				break
			end

			if not packet and self.emptyTicks >= IDLE_STOP_TICKS and not next(self.packets) then
				break
			end

			local pcm = if self:prepareDecoder() then self:decodeSlot(packet) else nil

			if pcm and not self.stopped then
				self:deliver(self.onPcmFrame :: any, pcm)
			end
		end

		self.running = false
		self.thread = nil
	end)

	self.running = true
	self.thread = thread

	self:resumeLoop(thread)
end

--[=[
	@within Voice.Jitter
	@private

	Starts the tick loop thread, logging at warn if it fails before its first wait.
]=]
function Jitter.Prototype.resumeLoop(self: Jitter, thread: thread)
	local started, startError = coroutine.resume(thread)

	if not started then
		self.logger:warn(`jitter tick loop failed to start: {startError}`)
	end
end

--[=[
	@within Voice.Jitter

	Stops the tick loop and frees the Opus decoder. Safe to call more than once, and from inside a frame
	callback, where the loop stops as soon as the callback returns.
]=]
function Jitter.Prototype.destroy(self: Jitter)
	local thread = self.thread

	if self.stopped then
		self.logger:debug(`jitter already destroyed`)

		return
	end

	self.stopped = true

	if thread and coroutine.status(thread) == "suspended" then
		local closed, closeError = coroutine.close(thread)

		if not closed then
			self.logger:warn(`jitter tick loop failed while closing: {closeError}`)
		end

		self.thread = nil
		self.running = false
	end

	self.decoder:destroy()
end

--[=[
	@within Voice.Jitter

	Responsible for constructing this class. `jitterLogger` receives warnings about callback errors and
	undecodable packets, and debug lines for dropped packets; without one, the jitter logs as `Jitter`.
]=]
function Jitter.Interface.new(firstSequence: number, jitterLogger: logger.Logger?): Jitter
	return setmetatable(
		{
			packets = {},
			nextSequence = firstSequence,
			stopped = false,
			running = false,
			clockAnchor = 0,
			tickCount = 0,
			emptyTicks = 0,
			lastPushClock = 0,
			decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS),
			decoding = true,
			decoderStale = false,
			logger = jitterLogger or logger.new("Jitter"),
		} :: Jitter,
		{ __index = Jitter.Prototype }
	)
end

export type Jitter = typeof(Jitter.Prototype) & {
	packets: { [number]: buffer },
	nextSequence: number,
	stopped: boolean,
	running: boolean,
	clockAnchor: number,
	tickCount: number,
	emptyTicks: number,
	lastPushClock: number,
	thread: thread?,
	decoder: opus.Decoder,
	shouldDecode: (() -> boolean)?,
	decoding: boolean,
	decoderStale: boolean,
	logger: logger.Logger,
	onRawFrame: ((sequence: number, packet: buffer) -> ())?,
	onPcmFrame: ((pcm: buffer) -> ())?,
}

return Jitter.Interface
