--[=[
	@class Opus.Encoder
	@__index Prototype

	Encodes raw PCM audio frames into Opus packets.

	The encoder state is an opaque libopus pointer that persists across calls - do not create a new
	Encoder per frame. One Encoder instance per audio stream is the correct usage.

	Call `destroy` when the encoder is no longer needed to free the native state.
]=]

--[=[
	@prop handle FFIPointer
	@within Opus.Encoder
]=]

--[=[
	@prop pcmPointer FFIPointer
	@within Opus.Encoder

	Native buffer that each PCM frame is copied into before encoding, reused for every call.
]=]

--[=[
	@prop outputPointer FFIPointer
	@within Opus.Encoder

	Native buffer that libopus writes the encoded packet into, reused for every call.
]=]

--[=[
	@prop sampleRate number
	@within Opus.Encoder
]=]

--[=[
	@prop channels number
	@within Opus.Encoder
]=]

--[=[
	@prop application number
	@within Opus.Encoder
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local Encoder = {}

Encoder.Interface = {}
Encoder.Prototype = {}

--[=[
	@within Opus.Encoder

	Encodes a raw PCM frame into an Opus packet. The frame must be exactly one Opus frame duration of samples.
]=]
function Encoder.Prototype.encode(self: Encoder, pcmFrame: buffer): buffer
	local frameLength = buffer.len(pcmFrame)
	local capacity = Sys.MAX_FRAME_SIZE * self.channels * 2

	assert(self.handle, "Encoder has been destroyed")
	assert(frameLength <= capacity, `opus_encode frame is {frameLength} bytes, more than {capacity}`)

	Buffer.write(self.pcmPointer, pcmFrame)

	local ffiSuccess, bytesWritten = pcall(function()
		return Sys.lib.opus_encode(
			self.handle,
			self.pcmPointer,
			frameLength // (self.channels * 2),
			self.outputPointer,
			Sys.MAX_PACKET_SIZE
		)
	end)

	if not ffiSuccess then
		error(`opus_encode ffi error: {bytesWritten}`)
	end

	bytesWritten = bytesWritten :: number

	if bytesWritten < 0 then
		local errorMessage = Buffer.fromCString(Sys.lib.opus_strerror(bytesWritten), 128)

		error(`opus_encode failed: {errorMessage} (code={bytesWritten})`)
	end

	return Buffer.read(self.outputPointer, bytesWritten)
end

--[=[
	@within Opus.Encoder
	@private

	Sets one libopus control through the shim, raising `could not set the Opus <label>: <reason>` when libopus refuses.
]=]
function Encoder.Prototype.control(self: Encoder, request: number, value: number, label: string)
	assert(self.handle, "Encoder has been destroyed")

	local result = Sys.lib.discord_luau_opus_encoder_set(self.handle, request, value)

	if result < 0 then
		error(`could not set the Opus {label}: {Buffer.fromCString(Sys.lib.opus_strerror(result), 128)}`)
	end
end

--[=[
	@within Opus.Encoder
	@private

	Reads one libopus control through the shim into a 4-byte cell that is freed before this returns or raises.
]=]
function Encoder.Prototype.query(self: Encoder, request: number, label: string): number
	assert(self.handle, "Encoder has been destroyed")

	local cell = Buffer.alloc(4)
	local result = Sys.lib.discord_luau_opus_encoder_get(self.handle, request, cell)
	local value = cell:readi32(0)

	Buffer.free(cell)

	if result < 0 then
		error(`could not read the Opus {label}: {Buffer.fromCString(Sys.lib.opus_strerror(result), 128)}`)
	end

	return value
end

--[=[
	@within Opus.Encoder

	Raises unless `bitsPerSecond` is a whole number from 500 to 510000, including when it is not a number at all, so
	it can check a bitrate taken straight from user options.

	libopus calls 500 to 512000 the meaningful range. The cap is 510000 because, after encoding a 20 ms stereo
	frame, libopus reports at most 510400, so the value read back equals the value set across the whole range.
]=]
function Encoder.Interface.checkBitrate(bitsPerSecond: unknown)
	assert(
		typeof(bitsPerSecond) == "number"
			and bitsPerSecond % 1 == 0
			and bitsPerSecond >= Sys.MIN_BITRATE
			and bitsPerSecond <= Sys.MAX_BITRATE,
		`bitrate must be a whole number from {Sys.MIN_BITRATE} to {Sys.MAX_BITRATE} bits per second`
	)
end

--[=[
	@within Opus.Encoder

	Sets the target bitrate in bits per second. Raises outside 500 to 510000, and after `destroy`.
]=]
function Encoder.Prototype.setBitrate(self: Encoder, bitsPerSecond: number)
	Encoder.Interface.checkBitrate(bitsPerSecond)

	self:control(Sys.request.setBitrate, bitsPerSecond, "bitrate")
end

--[=[
	@within Opus.Encoder

	Returns the bitrate libopus is using, in bits per second. Raises after `destroy`.
]=]
function Encoder.Prototype.getBitrate(self: Encoder): number
	return self:query(Sys.request.getBitrate, "bitrate")
end

--[=[
	@within Opus.Encoder

	Hints what the audio is: `"voice"`, `"music"`, or `"auto"` to let libopus decide. Raises on any other
	value, and after `destroy`.
]=]
function Encoder.Prototype.setSignal(self: Encoder, signal: Signal)
	local code = Sys.signal[signal]

	if not code then
		error('signal must be "auto", "voice" or "music"')
	end

	self:control(Sys.request.setSignal, code, "signal")
end

--[=[
	@within Opus.Encoder

	Returns the signal hint in effect. Raises after `destroy`.
]=]
function Encoder.Prototype.getSignal(self: Encoder): Signal
	local code = self:query(Sys.request.getSignal, "signal")

	for name, signalCode in Sys.signal do
		if signalCode == code then
			return name :: Signal
		end
	end

	error(`libopus reported an unknown signal {code}`)
end

--[=[
	@within Opus.Encoder

	Frees the native encoder state. No-op if already destroyed.
]=]
function Encoder.Prototype.destroy(self: Encoder)
	if not self.handle then
		return
	end

	Sys.lib.opus_encoder_destroy(self.handle)
	Buffer.free(self.pcmPointer)
	Buffer.free(self.outputPointer)

	self.handle = nil :: any
	self.pcmPointer = nil :: any
	self.outputPointer = nil :: any
end

--[=[
	@within Opus.Encoder

	Responsible for constructing this class.
]=]
function Encoder.Interface.new(sampleRate: number, channels: number, application: number): Encoder
	local errorPointer = Buffer.alloc(4)
	local handle = Sys.lib.opus_encoder_create(sampleRate, channels, application, errorPointer)
	local errorCode = errorPointer:readi32(0)

	Buffer.free(errorPointer)

	if errorCode ~= 0 then
		local errorMessage = Buffer.fromCString(Sys.lib.opus_strerror(errorCode), 128)

		error(`opus_encoder_create failed: {errorMessage} (code={errorCode})`)
	end

	return setmetatable(
		{
			handle = handle,
			pcmPointer = Buffer.alloc(Sys.MAX_FRAME_SIZE * channels * 2),
			outputPointer = Buffer.alloc(Sys.MAX_PACKET_SIZE),
			sampleRate = sampleRate,
			channels = channels,
			application = application,
		} :: Encoder,
		{ __index = Encoder.Prototype }
	)
end

export type Signal = "auto" | "voice" | "music"

export type Encoder = typeof(Encoder.Prototype) & {
	handle: FFIPointer,
	pcmPointer: FFIPointer,
	outputPointer: FFIPointer,
	sampleRate: number,
	channels: number,
	application: number,
}

return Encoder.Interface
