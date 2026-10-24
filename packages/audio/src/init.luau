local symphonia = require("./luau_packages/symphonia")

local player = require("@self/player")
local source = require("@self/source")

--[=[
	@function loadFileDecoder
	@within Audio
	@yields

	Loads libsymphonia, the library the file sources decode with, so the first file source neither waits for it nor
	yields. The load always yields; when the library is not cached it downloads the 2 to 3 MB file, and it checks the
	library's sha256, which blocks the VM for about 360 ms. Call it once at startup, from a thread that can yield.
	Later calls return at once.

	Raises `Symphonia requires FFI which is not available on this runtime` without FFI, and any error the load hits; a
	failed load is not cached, so the next call or file source tries again.
]=]
local function loadFileDecoder(): ()
	symphonia.load()
end

export type Player = player.Player
export type PlayerOptions = player.PlayerOptions
export type PlayerClock = player.PlayerClock
export type PlaybackEnd = player.PlaybackEnd
export type Source = source.Source
export type FileOptions = source.FileOptions
export type NamedOptions = source.NamedOptions
export type PCMOptions = source.PCMOptions
export type StreamOptions = source.StreamOptions
export type StreamReader = source.StreamReader
export type StreamFeed = source.StreamFeed

--[=[
	@class Audio

	Interface for the discord-luau Audio package: audio sources and a paced player for a voice connection. Runs on Zune
	only, because `voice` and `opus` load native libraries through FFI, and audio files decode through
	`discord_luau/symphonia`, which does too.

	A file source holds a native decoder session from the moment it is built. A source not handed to a `playAsync` that
	starts must be released with `source:destroy()`.
]=]

--[=[
	@prop player Audio.Player
	@within Audio

	`audio.player.new(connection, options?)` builds a player for a voice connection. See `Audio.Player`.
]=]

--[=[
	@prop fromOpus (packets: { buffer } | () -> buffer?) -> Source
	@within Audio

	Builds a source from Opus packets. See `Audio.Source`.
]=]

--[=[
	@prop fromPCM (pcm: buffer | { buffer } | () -> buffer?, options: PCMOptions?) -> Source
	@within Audio

	Builds a source from 48 kHz stereo 16-bit little-endian PCM of any length; `options.bitrate` sets the Opus bitrate
	(128000 by default). See `Audio.Source`.
]=]

--[=[
	@prop fromFile (path: string, options: FileOptions?) -> Source
	@within Audio

	Builds a source from the audio file at `path`, streamed from the disk. See `Audio.Source`.
]=]

--[=[
	@prop fromEncoded (bytes: buffer | string, options: FileOptions?) -> Source
	@within Audio

	Builds a source from an audio file held in memory; the format is found from the content. See `Audio.Source`.
]=]

--[=[
	@prop fromMP3 (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for an MP3, MP2 or MP1 file. Any supported file plays through it. See `Audio.Source`.
]=]

--[=[
	@prop fromOgg (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for an Ogg file: Vorbis, FLAC, or Opus passed through. Any supported file plays through it. See
	`Audio.Source`.
]=]

--[=[
	@prop fromWAV (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for a WAV file: PCM or ADPCM. Any supported file plays through it. See `Audio.Source`.
]=]

--[=[
	@prop fromFLAC (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for a FLAC file. Any supported file plays through it. See `Audio.Source`.
]=]

--[=[
	@prop fromAAC (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for an ADTS AAC file: AAC-LC, mono or stereo. Any supported file plays through it. See
	`Audio.Source`.
]=]

--[=[
	@prop fromM4A (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for an M4A or MP4 file: AAC-LC in mono or stereo, ALAC, or Opus passed through. Any supported file
	plays through it. See `Audio.Source`.
]=]

--[=[
	@prop fromWebM (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for a WebM file: Opus passed through, or Vorbis. Any supported file plays through it. See
	`Audio.Source`.
]=]

--[=[
	@prop fromMKV (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for a Matroska file. Any supported file plays through it. See `Audio.Source`.
]=]

--[=[
	@prop fromAIFF (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for an AIFF file. Any supported file plays through it. See `Audio.Source`.
]=]

--[=[
	@prop fromCAF (bytes: buffer | string, options: NamedOptions?) -> Source
	@within Audio

	`fromEncoded` for a Core Audio Format file. Any supported file plays through it. See `Audio.Source`.
]=]

--[=[
	@prop fromStream (read: StreamReader, options: StreamOptions?) -> Source
	@within Audio

	Builds a source from an audio file that arrives in pieces: `read` returns the next chunk of its bytes and nil at
	the end, and may yield. Nothing is read or opened until the source plays; the player waits while it buffers
	`options.bufferSeconds` of audio (1 by default) and whenever it stalls. See `Audio.Source`.
]=]

--[=[
	@prop fromProcess (command: string, arguments: { string }?, options: StreamOptions?) -> Source
	@within Audio

	Builds a stream source from what a program writes to its stdout, such as
	`audio.fromProcess("yt-dlp", { "-f", "251", "-o", "-", url })`. The program starts when the source plays; a
	non-zero exit code fails the playback with the program's last stderr line. See `Audio.Source`.
]=]

return {
	player = player,
	loadFileDecoder = loadFileDecoder,
	fromOpus = source.fromOpus,
	fromPCM = source.fromPCM,
	fromFile = source.fromFile,
	fromEncoded = source.fromEncoded,
	fromMP3 = source.fromMP3,
	fromOgg = source.fromOgg,
	fromWAV = source.fromWAV,
	fromFLAC = source.fromFLAC,
	fromAAC = source.fromAAC,
	fromM4A = source.fromM4A,
	fromWebM = source.fromWebM,
	fromMKV = source.fromMKV,
	fromAIFF = source.fromAIFF,
	fromCAF = source.fromCAF,
	fromStream = source.fromStream,
	fromProcess = source.fromProcess,
}
