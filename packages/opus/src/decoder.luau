--[=[
	@class Opus.Decoder
	@__index Prototype

	Decodes Opus packets back into raw PCM audio frames.

	The decoder state is an opaque libopus pointer that persists across calls - do not create a new
	Decoder per packet. One Decoder instance per audio stream is the correct usage.

	Call `destroy` when the decoder is no longer needed to free the native state.
]=]

--[=[
	@prop handle FFIPointer
	@within Opus.Decoder
]=]

--[=[
	@prop sampleRate number
	@within Opus.Decoder
]=]

--[=[
	@prop channels number
	@within Opus.Decoder
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local Decoder = {}

Decoder.Interface = {}
Decoder.Prototype = {}

--[=[
	@within Opus.Decoder

	Decodes an Opus packet into a raw s16le PCM frame.
]=]
function Decoder.Prototype.decode(self: Decoder, opusBuffer: buffer): buffer
	local inputLen = buffer.len(opusBuffer)

	if inputLen == 0 then
		error("opus_decode input buffer is empty")
	end

	local inputPointer = Buffer.dupe(opusBuffer)
	local outputPointer = Buffer.alloc(Sys.MAX_FRAME_SIZE * self.channels * 2)

	local ffiSuccess, samplesDecoded = pcall(function()
		return Sys.lib.opus_decode(self.handle, inputPointer, inputLen, outputPointer, Sys.MAX_FRAME_SIZE, 0)
	end)

	Buffer.free(inputPointer)

	if not ffiSuccess then
		Buffer.free(outputPointer)

		error(`opus_decode ffi error: {samplesDecoded}`)
	end

	samplesDecoded = samplesDecoded :: number

	if samplesDecoded < 0 then
		Buffer.free(outputPointer)

		local errorMessage = Buffer.fromCString(Sys.lib.opus_strerror(samplesDecoded), 128)

		error(`opus_decode failed: {errorMessage} (code={samplesDecoded})`)
	end

	local result = Buffer.read(outputPointer, samplesDecoded * self.channels * 2)

	Buffer.free(outputPointer)

	return result
end

--[=[
	@within Opus.Decoder

	Recovers the lost frame preceding `nextPacket` using the FEC data embedded in that packet.
	Use when a packet is missing but the following packet has already arrived.
]=]
function Decoder.Prototype.decodeFec(self: Decoder, nextPacket: buffer): buffer
	local inputLen = buffer.len(nextPacket)

	if inputLen == 0 then
		error("opus_decode FEC input buffer is empty")
	end

	local inputPointer = Buffer.dupe(nextPacket)
	local outputPointer = Buffer.alloc(Sys.MAX_FRAME_SIZE * self.channels * 2)

	local ffiSuccess, samplesDecoded = pcall(function()
		return Sys.lib.opus_decode(self.handle, inputPointer, inputLen, outputPointer, Sys.MAX_FRAME_SIZE, 1)
	end)

	Buffer.free(inputPointer)

	if not ffiSuccess then
		Buffer.free(outputPointer)

		error(`opus_decode FEC ffi error: {samplesDecoded}`)
	end

	samplesDecoded = samplesDecoded :: number

	if samplesDecoded < 0 then
		Buffer.free(outputPointer)

		local errorMessage = Buffer.fromCString(Sys.lib.opus_strerror(samplesDecoded), 128)

		error(`opus_decode FEC failed: {errorMessage} (code={samplesDecoded})`)
	end

	local result = Buffer.read(outputPointer, samplesDecoded * self.channels * 2)

	Buffer.free(outputPointer)

	return result
end

--[=[
	@within Opus.Decoder

	Synthesises a comfort-noise frame for a lost packet when no FEC data is available (packet loss concealment).
]=]
function Decoder.Prototype.decodePLC(self: Decoder): buffer
	local nullPointer = Buffer.getNull()
	local outputPointer = Buffer.alloc(Sys.MAX_FRAME_SIZE * self.channels * 2)

	local ffiSuccess, samplesDecoded = pcall(function()
		return Sys.lib.opus_decode(self.handle, nullPointer, 0, outputPointer, Sys.MAX_FRAME_SIZE, 0)
	end)

	if not ffiSuccess then
		Buffer.free(outputPointer)

		error(`opus_decode PLC ffi error: {samplesDecoded}`)
	end

	samplesDecoded = samplesDecoded :: number

	if samplesDecoded < 0 then
		Buffer.free(outputPointer)

		local errorMessage = Buffer.fromCString(Sys.lib.opus_strerror(samplesDecoded), 128)

		error(`opus_decode PLC failed: {errorMessage} (code={samplesDecoded})`)
	end

	local result = Buffer.read(outputPointer, samplesDecoded * self.channels * 2)

	Buffer.free(outputPointer)

	return result
end

--[=[
	@within Opus.Decoder

	Frees the native decoder state. No-op if already destroyed.
]=]
function Decoder.Prototype.destroy(self: Decoder)
	if not self.handle then
		return
	end

	Sys.lib.opus_decoder_destroy(self.handle)
	self.handle = nil :: any
end

--[=[
	@within Opus.Decoder

	Responsible for constructing this class.
]=]
function Decoder.Interface.new(sampleRate: number, channels: number): Decoder
	local errorPointer = Buffer.alloc(4)

	local handle = Sys.lib.opus_decoder_create(sampleRate, channels, errorPointer)

	local errorCode = errorPointer:readi32(0)

	Buffer.free(errorPointer)

	if errorCode ~= 0 then
		local errorMessage = Buffer.fromCString(Sys.lib.opus_strerror(errorCode), 128)

		error(`opus_decoder_create failed: {errorMessage} (code={errorCode})`)
	end

	return setmetatable(
		{
			handle = handle,
			sampleRate = sampleRate,
			channels = channels,
		} :: Decoder,
		{ __index = Decoder.Prototype }
	)
end

export type Decoder = typeof(Decoder.Prototype) & {
	handle: FFIPointer,
	sampleRate: number,
	channels: number,
}

return Decoder.Interface
