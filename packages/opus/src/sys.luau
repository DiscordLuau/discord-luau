--[=[
	@class Opus.Sys

	Raw FFI bindings for libopus.
	Loads the shared library and exposes the C API as a typed Luau interface.
	Prefer the higher-level `Encoder` and `Decoder` classes over calling `lib` directly.
]=]

local binary = require("../luau_packages/binary")
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

local platform = stdPolyfills.process.getPlatform()
local architecture = if stdPolyfills.process.getArch() == "aarch64" then "arm64" else "x64"

local checksums: { [string]: string } = {
	["linux-arm64"] = "sha256:b2bbb70c86a9c819c35796cd37d8fdae0292fa2424ce131ec7df6e6f174fa68f",
	["linux-x64"] = "sha256:57d2875a85a8a31918f802664137f843d70e4911bcda4ac7ac2b5a7f00ca3e6a",
	["macos-arm64"] = "sha256:d4e65ac92a40b106d6f856ae4d04def8a3a0c2631f1495c69a8b46058ffc4222",
	["windows-x64"] = "sha256:28ebdfa2959360bc318e89d0fd944b775b85f179523b0d360e1ec0a86bfe1df7",
}

local result = binary.load({
	id = "libopus",
	version = "0.0.1",
	url = "https://raw.githubusercontent.com/DiscordLuau/discord-luau/refs/tags/opus-{version}/packages/opus/binaries/{os}-{arch}/libopus{ext}",
	checksum = checksums[`{platform}-{architecture}`] or error(`Unsupported platform '{platform}-{architecture}' for libopus`),
})

local lib = (
	stdPolyfills.ffi.dlopen(result.path, {
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
