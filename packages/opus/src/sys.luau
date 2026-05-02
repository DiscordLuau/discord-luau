--[=[
	@class Opus.Sys

	Raw FFI bindings for libopus.
	Loads the shared library and exposes the C API as a typed Luau interface.
	Prefer the higher-level `Encoder` and `Decoder` classes over calling `lib` directly.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

if not stdPolyfills.runtime.capabilities().ffi then
	local function makeStub(name: string): any
		return setmetatable({} :: any, {
			__index = function(_, key)
				return makeStub(`{name}.{key}`)
			end,
			__call = function()
				error(`Opus requires FFI which is not available on this runtime (accessed: {name})`)
			end,
		})
	end
	return makeStub("Opus.Sys")
end

local types = stdPolyfills.ffi.getTypes()

local void = types.void
local i32 = types.i32
local pointer = types.pointer

export type Lib = {
	opus_encoder_create: (Fs: number, channels: number, application: number, error: FFIPointer) -> FFIPointer,
	opus_encode: (st: FFIPointer, pcm: FFIPointer, frameSize: number, data: FFIPointer, maxDataBytes: number) -> number,
	opus_encoder_destroy: (st: FFIPointer) -> (),

	opus_decoder_create: (Fs: number, channels: number, error: FFIPointer) -> FFIPointer,
	opus_decode: (
		st: FFIPointer,
		data: FFIPointer,
		length: number,
		pcm: FFIPointer,
		frameSize: number,
		decodeFec: number
	) -> number,
	opus_decoder_destroy: (st: FFIPointer) -> (),

	opus_strerror: (error: number) -> FFIPointer,
}

local os = stdPolyfills.process.getPlatform()
local arch = stdPolyfills.process.getArch()

local osName = if os == "linux" then "Linux" elseif os == "macos" then "macOS" else "Windows"
local archName = if arch == "aarch64" then "ARM64" else "X64"
local subdir = if os == "windows" then "bin" else "lib"
local ext = if os == "linux" then "so" elseif os == "macos" then "dylib" else "dll"

local libPath = `{zune.require.navigate("../binaries")}/{osName}-{archName}/{subdir}/libopus.{ext}`

local lib = (
	stdPolyfills.ffi.dlopen(libPath, {
		opus_encoder_create = { returns = pointer, args = { i32, i32, i32, pointer } },
		opus_encode = { returns = i32, args = { pointer, pointer, i32, pointer, i32 } },
		opus_encoder_destroy = { returns = void, args = { pointer } },

		opus_decoder_create = { returns = pointer, args = { i32, i32, pointer } },
		opus_decode = { returns = i32, args = { pointer, pointer, i32, pointer, i32, i32 } },
		opus_decoder_destroy = { returns = void, args = { pointer } },

		opus_strerror = { returns = pointer, args = { i32 } },
	}) :: any
) :: Lib

return {
	lib = lib,

	application = {
		voip = 2048,
		audio = 2049,
		restrictedLowDelay = 2051,
	},

	sampleRate = {
		hz8000 = 8000,
		hz12000 = 12000,
		hz16000 = 16000,
		hz24000 = 24000,
		hz48000 = 48000,
	},

	channels = {
		mono = 1,
		stereo = 2,
	},

	MAX_PACKET_SIZE = 4000,
	MAX_FRAME_SIZE = 5760,
	DISCORD_FRAME_SIZE = 960,
	DISCORD_SAMPLE_RATE = 48000,
	DISCORD_CHANNELS = 2,
}
