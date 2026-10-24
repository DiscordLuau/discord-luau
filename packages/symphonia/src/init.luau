--[=[
	@class Symphonia

	Decodes audio files with [Symphonia](https://github.com/pdeljanov/Symphonia), a pure Rust audio library, through
	FFI. The library decodes every format it supports to 48 kHz stereo 32-bit floats; Luau applies the volume, limits
	the audio and converts it to 16-bit little-endian PCM, ready for `audio.fromPCM`. Opus in Ogg, WebM or MP4 is
	passed through as raw Opus packets, ready for `audio.fromOpus`.

	The library loads on first use, not on require. Call `load` at startup to take its first-call cost early.
]=]

--[=[
	@prop sys Symphonia.Sys
	@within Symphonia

	The raw FFI bindings and constants.
]=]

--[=[
	@prop decoder Symphonia.Decoder
	@within Symphonia

	The `Decoder` constructors, `fromBuffer`, `fromFile` and `fromStream`.
]=]

--[=[
	@prop limiter Symphonia.Limiter
	@within Symphonia

	The `Limiter` constructor, `new`, and `checkVolume`: the volume, the look-ahead limiter and the conversion to
	16-bit PCM that `read` uses, for float audio from `readFloat`.
]=]

--[=[
	@prop OUTPUT_SAMPLE_RATE number
	@within Symphonia

	The sample rate `read` and `decode` return: 48000 Hz.
]=]

--[=[
	@prop OUTPUT_CHANNELS number
	@within Symphonia

	The channel count `read` and `decode` return: 2, interleaved.
]=]

local Decoder = require("@self/decoder")
local Limiter = require("@self/limiter")
local Sys = require("@self/sys")

local DEFAULT_MAX_SECONDS = 3600

local function readWhole(decoder: Decoder, maxSeconds: number): buffer
	local maxBytes = maxSeconds * Sys.OUTPUT_SAMPLE_RATE * Sys.BYTES_PER_FRAME
	local chunks: { buffer } = {}
	local byteCount = 0
	local chunk = decoder:read()

	while chunk do
		byteCount += buffer.len(chunk)

		if byteCount > maxBytes then
			error(`the decoded audio is longer than {maxSeconds} s; read it with a Decoder instead`, 0)
		end

		table.insert(chunks, chunk)
		chunk = decoder:read()
	end

	local whole = buffer.create(byteCount)
	local offset = 0

	for _, piece in chunks do
		buffer.copy(whole, offset, piece)
		offset += buffer.len(piece)
	end

	return whole
end

--[=[
	@function load
	@within Symphonia
	@yields
	@return Symphonia.Sys.Lib

	`Symphonia.Sys.load`: loads libsymphonia on the first call and returns it. The first call always yields, may
	download the library and checks its sha256, which blocks for about 360 ms; call it at startup so the first
	`fromBuffer` or `fromFile` does not.
]=]

--[=[
	@function decode
	@within Symphonia
	@yields
	@param bytes buffer | string
	@param options DecodeOptions?
	@return buffer

	Decodes a whole file held in memory, as a buffer or a string, to one buffer of 48 kHz interleaved stereo 16-bit
	little-endian PCM, through the decoder's `read`, so audio that would pass full scale is limited rather than clipped
	and audio that never does comes out bit for bit. Opus raises, since it is passed through rather than decoded; read
	it with a `Decoder`.

	Raises `the decoded audio is longer than <n> s; read it with a Decoder instead` once the output passes
	`options.maxSeconds`, and every error a `Decoder` raises. The decoder is destroyed on every exit.

	Each second of output is 192 KB of PCM, and `decode` holds every 100 ms chunk and the joined buffer at once, so
	its memory peaks near twice the output: about 1.4 GB at the default cap of 3600 s (691 MB of PCM). Lower
	`maxSeconds` for untrusted files, or read long files with a `Decoder`.
]=]
local function decode(bytes: buffer | string, options: DecodeOptions?): buffer
	local decodeOptions: DecodeOptions = options or {}
	local maxSeconds = decodeOptions.maxSeconds or DEFAULT_MAX_SECONDS
	local decoder = Decoder.fromBuffer(bytes, decodeOptions)
	local succeeded, result = pcall(readWhole, decoder, maxSeconds)

	decoder:destroy()

	if not succeeded then
		error(result, 0)
	end

	return result
end

export type Lib = Sys.Lib
export type Decoder = Decoder.Decoder
export type DecoderOptions = Decoder.DecoderOptions
export type Limiter = Limiter.Limiter
--[=[
	@interface DecodeOptions
	@within Symphonia
	.extension string? -- As for `Decoder.fromBuffer`; currently unused.
	.logLevel logger.LogLevel? -- The level of the decoder's logger; `Info` by default.
	.maxSeconds number? -- The longest output `decode` returns before it raises; 3600 s by default.
]=]
export type DecodeOptions = Decoder.DecoderOptions & {
	maxSeconds: number?,
}

return {
	sys = Sys,
	load = Sys.load,
	decoder = Decoder,
	limiter = Limiter,
	decode = decode,

	OUTPUT_SAMPLE_RATE = Sys.OUTPUT_SAMPLE_RATE,
	OUTPUT_CHANNELS = Sys.OUTPUT_CHANNELS,
}
