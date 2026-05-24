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

	local pcmPointer = Buffer.dupe(pcmFrame)
	local outputPointer = Buffer.alloc(Sys.MAX_PACKET_SIZE)

	local ffiSuccess, bytesWritten = pcall(function()
		return Sys.lib.opus_encode(
			self.handle,
			pcmPointer,
			frameLength // (self.channels * 2),
			outputPointer,
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

	return Buffer.read(outputPointer, bytesWritten)
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
	self.handle = nil :: any
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
			sampleRate = sampleRate,
			channels = channels,
			application = application,
		} :: Encoder,
		{ __index = Encoder.Prototype }
	)
end

export type Encoder = typeof(Encoder.Prototype) & {
	handle: FFIPointer,
	sampleRate: number,
	channels: number,
	application: number,
}

return Encoder.Interface
