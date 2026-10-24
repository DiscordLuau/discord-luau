--[=[
	@class Opus.Sys

	Raw FFI bindings for libopus.
	Loads the shared library and exposes the C API as a typed Luau interface.
	Prefer the higher-level `Encoder` and `Decoder` classes over calling `lib` directly.
]=]

local binary = require("../luau_packages/binary")
local stdPolyfills = require("../luau_packages/std_polyfills")

local CHECKSUMS: { [string]: string } = {
	["linux-arm64"] = "sha256:4cb8a22124493de4ab5098c45bd796da3064cfdbeefc25db7a2a7ece7bee5716",
	["linux-x64"] = "sha256:683a614238508cffa0817ad780ec8e3d7f14f9f22b9098b02ba3706bdf428009",
	["macos-arm64"] = "sha256:21075a0e56eebe4c3967d7b3b7d4b365e904f6c0363f2d3569f46076f9cb4e76",
	["macos-x64"] = "sha256:b57d6555f3aafcdee2dbd46315353c3ac61ed9945a3745b0835df5653ae931b4",
	["windows-x64"] = "sha256:9f0918506e823ae3544e13c7c4c3ea7b549afc85bb13838f04a5b3083251381f",
	["windows-x86"] = "sha256:b2ee3ec4faa4a58d2ef52a8d9127d3dffa9527b10aa7afde3ef89c6f7d67797a",
}

local Sys = {
	lib = (nil :: any) :: Lib,

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

	request = {
		setBitrate = 4002,
		getBitrate = 4003,
		setSignal = 4024,
		getSignal = 4025,
	},

	signal = {
		auto = -1000,
		voice = 3001,
		music = 3002,
	},

	MIN_BITRATE = 500,
	MAX_BITRATE = 510000,

	MAX_PACKET_SIZE = 4000,
	MAX_FRAME_SIZE = 5760,
	DISCORD_FRAME_SIZE = 960,
	DISCORD_SAMPLE_RATE = 48000,
	DISCORD_CHANNELS = 2,
}

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

local function loadLibrary(): Lib
	local types = stdPolyfills.ffi.getTypes()
	local void = types.void
	local i32 = types.i32
	local pointer = types.pointer
	local platform = stdPolyfills.process.getPlatform()
	local rawArchitecture = stdPolyfills.process.getArch()
	local architecture = if rawArchitecture == "aarch64"
		then "arm64"
		elseif rawArchitecture == "x86" then "x86"
		else "x64"
	local result = binary.load({
		id = "libopus",
		version = "0.0.5",
		url = "https://raw.githubusercontent.com/DiscordLuau/discord-luau/refs/tags/opus-{version}/packages/opus/binaries/{os}-{arch}/libopus{ext}",
		checksum = CHECKSUMS[`{platform}-{architecture}`]
			or error(`Unsupported platform '{platform}-{architecture}' for libopus`),
		allowSystem = false,
	})

	return (
		stdPolyfills.ffi.dlopen(result.path, {
			opus_encoder_create = { returns = pointer, args = { i32, i32, i32, pointer } },
			opus_encode = { returns = i32, args = { pointer, pointer, i32, pointer, i32 } },
			opus_encoder_destroy = { returns = void, args = { pointer } },

			opus_decoder_create = { returns = pointer, args = { i32, i32, pointer } },
			opus_decode = { returns = i32, args = { pointer, pointer, i32, pointer, i32, i32 } },
			opus_decoder_destroy = { returns = void, args = { pointer } },

			opus_strerror = { returns = pointer, args = { i32 } },

			discord_luau_opus_encoder_set = { returns = i32, args = { pointer, i32, i32 } },
			discord_luau_opus_encoder_get = { returns = i32, args = { pointer, i32, pointer } },
		}) :: any
	) :: Lib
end

if stdPolyfills.runtime.capabilities().ffi then
	Sys.lib = loadLibrary()
else
	Sys.lib = makeStub("Opus.Sys.lib")
end

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

	discord_luau_opus_encoder_set: (st: FFIPointer, request: number, value: number) -> number,
	discord_luau_opus_encoder_get: (st: FFIPointer, request: number, value: FFIPointer) -> number,
}

return Sys
