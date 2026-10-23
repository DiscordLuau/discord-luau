local Sys = require("@self/sys")
local Encoder = require("@self/encoder")
local Decoder = require("@self/decoder")
local Stats = require("@self/stats")

export type Encoder = Encoder.Encoder
export type Decoder = Decoder.Decoder
export type Signal = Encoder.Signal
export type FrameStats = Stats.FrameStats

--[=[
	@class Opus

	FFI bindings for libopus, providing PCM→Opus encoding and Opus→PCM decoding.

	All functions use pre-built libopus binaries bundled with this package - no system installation is required.
]=]

--[=[
	@prop sys Opus.Sys
	@within Opus
]=]

--[=[
	@prop encoder Opus.Encoder
	@within Opus
]=]

--[=[
	@prop decoder Opus.Decoder
	@within Opus
]=]

--[=[
	@prop stats Opus.Stats
	@within Opus
]=]

--[=[
	@function checkBitrate
	@within Opus
	@param bitsPerSecond unknown

	Raises unless `bitsPerSecond` is a whole number from 500 to 510000. The same function as `Opus.Encoder.checkBitrate`.
]=]

return {
	sys = Sys,
	encoder = Encoder,
	decoder = Decoder,
	stats = Stats.stats,
	checkBitrate = Encoder.checkBitrate,

	application = Sys.application,
	sampleRate = Sys.sampleRate,
	channels = Sys.channels,

	MAX_PACKET_SIZE = Sys.MAX_PACKET_SIZE,
	MAX_FRAME_SIZE = Sys.MAX_FRAME_SIZE,
	DISCORD_FRAME_SIZE = Sys.DISCORD_FRAME_SIZE,
	DISCORD_SAMPLE_RATE = Sys.DISCORD_SAMPLE_RATE,
	DISCORD_CHANNELS = Sys.DISCORD_CHANNELS,
}
