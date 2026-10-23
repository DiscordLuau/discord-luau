--[=[
	@class Symphonia.Decoder
	@__index Prototype

	Decodes one audio file with libsymphonia. Every format except Opus decodes to 48 kHz interleaved stereo 16-bit
	little-endian PCM through `read`, at `volume` and through a `Limiter` instead of clipping, or to the library's 32-bit
	floats through `readFloat`; Opus is passed through, never decoded, as raw Opus packets through `readPacket`.
	PCM, FLAC, Vorbis and ALAC in any channel layout are mixed to stereo. AAC-LC and ADPCM take mono or stereo only:
	AAC with more than two channels fails to open, and implicitly signalled HE-AAC plays only its AAC-LC core.

	Build one with `fromBuffer`, `fromFile` or `fromStream`, read it to its end, and call `destroy`. A decoder that is
	never destroyed keeps its native session, and for `fromFile` its open file, until the process exits. A stream is fed
	with `push` and `finish`, and `refresh` follows its worker thread.

	Nothing here is `Async`: opening, `read` and `readPacket` block on native code and, for `fromFile`, on the disk, and
	a future would not unblock them. A slow disk stalls the whole VM while it reads. Reads on a stream never block: they
	return nil with `dry` set while nothing is ready.
]=]

--[=[
	@prop id number
	@within Symphonia.Decoder

	The native session's id.
]=]

--[=[
	@prop codec string
	@within Symphonia.Decoder

	The codec's short name, such as `"mp3"`, `"flac"`, `"vorbis"`, `"aac"`, `"pcm_s16le"` or `"opus"`.
]=]

--[=[
	@prop container string
	@within Symphonia.Decoder

	The container's short name, such as `"mp3"`, `"flac"`, `"ogg"`, `"wave"`, `"isomp4"` or `"matroska"`.
]=]

--[=[
	@prop sampleRate number
	@within Symphonia.Decoder

	The file's own sample rate in Hz. `read` always returns 48 kHz.
]=]

--[=[
	@prop channels number
	@within Symphonia.Decoder

	The file's own channel count, or 0 when it does not state one. `read` always returns stereo.
]=]

--[=[
	@prop durationSeconds number?
	@within Symphonia.Decoder

	The length the file states, or nil when it states none (Matroska and WebM never do).
]=]

--[=[
	@prop isOpus boolean
	@within Symphonia.Decoder

	Whether the audio is Opus, read with `readPacket`; anything else is read with `read`.
]=]

--[=[
	@prop ended boolean
	@within Symphonia.Decoder

	Whether a read has reached the end of the audio, or the decoder has been destroyed.
]=]

--[=[
	@prop endedEarly boolean
	@within Symphonia.Decoder

	Whether decoding ended short of the length the file states, because the file is truncated or because damaged
	packets were skipped. Read when a read reaches the end, which warns once when it is set; false until then. A file
	that states no length, such as a WAV streamed with unknown sizes, an MP2 stream or an ADTS AAC stream, is never
	flagged; an MP3 with a Xing header states its length and is. Opus is passed through, not decoded, so it is never
	flagged.
]=]

--[=[
	@prop destroyed boolean
	@within Symphonia.Decoder

	Whether `destroy` has freed the native session.
]=]

--[=[
	@prop skippedPackets number
	@within Symphonia.Decoder

	How many undecodable or empty packets were skipped so far.
]=]

--[=[
	@prop volume number
	@within Symphonia.Decoder

	The volume `setVolume` last set, from 0 to 4; 1 until then. `read` applies it through `limiter`; it has no effect on
	`readFloat`, or on Opus, which is passed through.
]=]

--[=[
	@prop limiter Symphonia.Limiter?
	@within Symphonia.Decoder

	The decoder's own `Limiter`, which turns `read`'s floats into 16-bit PCM at `volume`; nil once `destroy` has
	released it. Its `clampCount` stays 0.
]=]

--[=[
	@prop opened boolean
	@within Symphonia.Decoder

	Whether the audio has been opened, so that `codec`, `container`, `sampleRate`, `channels`, `isOpus` and
	`durationSeconds` are real. True from the start for `fromBuffer` and `fromFile`; for `fromStream` it turns true in
	the first `refresh` after enough bytes have arrived, and until then those fields are `""`, -1 or false. A failed
	stream that never opened stays false.
]=]

--[=[
	@prop dry boolean
	@within Symphonia.Decoder

	Whether the last read of a stream returned nil because nothing was ready yet, so the audio has not ended: push more
	bytes or wait. A successful read, or the end, clears it. Always false for `fromBuffer` and `fromFile`.
]=]

--[=[
	@prop state number
	@within Symphonia.Decoder

	The native session's state as of the last `refresh`: 0 while a stream probes, 1 open, 2 ended, 3 failed.
]=]

--[=[
	@prop failed boolean
	@within Symphonia.Decoder

	Whether the stream session failed, as of the last `refresh`; `failure` says why.
]=]

--[=[
	@prop failure string?
	@within Symphonia.Decoder

	The text of the session's failure, nil until `failed`.
]=]

--[=[
	@prop failedBeforeOpen boolean
	@within Symphonia.Decoder

	Whether the session failed before the audio opened, which means the bytes are not audio libsymphonia can read from
	a stream; false until `failed`.
]=]

--[=[
	@prop isStream boolean
	@within Symphonia.Decoder
	@private

	Whether the decoder is a stream session built by `fromStream`.
]=]

--[=[
	@prop finished boolean
	@within Symphonia.Decoder
	@private

	Whether `finish` has marked the end of the input.
]=]

--[=[
	@prop endReturned boolean
	@within Symphonia.Decoder
	@private

	Whether `read` has returned the nil that ends the audio, after the limiter's last frames. A read after that is a
	read after the end.
]=]

--[=[
	@prop warnedOpusVolume boolean
	@within Symphonia.Decoder
	@private

	Whether `setVolume` has already warned that volume has no effect on this Opus decoder.
]=]

--[=[
	@prop logger logger.Logger
	@within Symphonia.Decoder

	The decoder's logger, named `SymphoniaDecoder` and at `Info` unless `logLevel` says otherwise.
]=]

--[=[
	@prop library Sys.Lib
	@within Symphonia.Decoder
	@private

	The library that opened the session.
]=]

--[=[
	@prop errorPointer FFIPointer
	@within Symphonia.Decoder
	@private

	Native memory libsymphonia writes its error text into, allocated once.
]=]

--[=[
	@prop outputPointer FFIPointer
	@within Symphonia.Decoder
	@private

	Native memory libsymphonia writes PCM or the next packet into, allocated once: room for `READ_FRAMES` float frames
	plus the limiter's look-ahead, which also holds the largest packet, `MAX_PACKET_SIZE` bytes.
]=]

local logger = require("../luau_packages/logger")

local Buffer = require("./buffer")
local Limiter = require("./limiter")
local Sys = require("./sys")

local OUTPUT_BYTES =
	math.max((Sys.READ_FRAMES + Limiter.LOOKAHEAD_FRAMES) * Sys.FLOAT_BYTES_PER_FRAME, Sys.MAX_PACKET_SIZE)

local FAILED_STATE = 3

local Decoder = {}

Decoder.Interface = {}
Decoder.Prototype = {}

local function describe(
	library: Sys.Lib,
	id: number,
	field: number,
	outputPointer: FFIPointer,
	capacity: number?
): string
	local written = library.symphonia_describe(id, field, outputPointer, capacity or Sys.NAME_CAPACITY)

	return buffer.tostring(Buffer.read(outputPointer, math.max(written, 0)))
end

local function buildDecoder(
	library: Sys.Lib,
	id: number,
	errorPointer: FFIPointer,
	outputPointer: FFIPointer,
	decoderLogger: logger.Logger,
	isStream: boolean
): Decoder
	local durationMilliseconds = library.symphonia_info(id, Sys.infoField.durationMilliseconds)
	local codec = describe(library, id, Sys.describeField.codec, outputPointer)
	local container = describe(library, id, Sys.describeField.container, outputPointer)
	local sampleRate = library.symphonia_info(id, Sys.infoField.sampleRate)
	local self = setmetatable(
		{
			id = id,
			codec = codec,
			container = container,
			sampleRate = sampleRate,
			channels = library.symphonia_info(id, Sys.infoField.channels),
			durationSeconds = if durationMilliseconds >= 0 then durationMilliseconds / 1000 else nil,
			isOpus = library.symphonia_info(id, Sys.infoField.isOpus) == 1,
			opened = sampleRate >= 0,
			dry = false,
			state = library.symphonia_info(id, Sys.infoField.state),
			failed = false,
			failure = nil :: string?,
			failedBeforeOpen = false,
			isStream = isStream,
			finished = false,
			ended = false,
			endedEarly = false,
			destroyed = false,
			skippedPackets = 0,
			volume = 1,
			limiter = Limiter.new() :: Limiter.Limiter?,
			endReturned = false,
			warnedOpusVolume = false,
			logger = decoderLogger,
			library = library,
			errorPointer = errorPointer,
			outputPointer = outputPointer,
		} :: Decoder,
		{ __index = Decoder.Prototype }
	)

	if self.opened then
		self.logger:debug(`decoder {id} opened {codec} audio in a {container} container`)
	else
		self.logger:debug(`decoder {id} is a stream waiting for bytes`)
	end

	return self
end

local function newDecoder(
	library: Sys.Lib,
	id: number,
	errorPointer: FFIPointer,
	decoderLogger: logger.Logger,
	isStream: boolean
): Decoder
	if id < 0 then
		local message = Buffer.fromCString(errorPointer, Sys.ERROR_CAPACITY)

		Buffer.free(errorPointer)
		error(`could not open audio: {message}`, 0)
	end

	local outputPointer = Buffer.alloc(OUTPUT_BYTES)
	local succeeded, result = pcall(buildDecoder, library, id, errorPointer, outputPointer, decoderLogger, isStream)

	if not succeeded then
		library.symphonia_close(id)
		Buffer.free(errorPointer)
		Buffer.free(outputPointer)
		decoderLogger:debug(`decoder {id} was closed because building it failed: {result}`)
		error(result, 0)
	end

	return result
end

--[=[
	@within Symphonia.Decoder
	@private

	Raises when the decoder has been destroyed, or when the read does not match the audio: `readsOpus` is true for
	`readPacket` and false for `read`.
]=]
function Decoder.Prototype.checkReadable(self: Decoder, readsOpus: boolean)
	if self.destroyed then
		error("decoder has been destroyed", 0)
	end

	if self.opened and self.isOpus and not readsOpus then
		error("this audio is Opus; read it with readPacket", 0)
	elseif self.opened and readsOpus and not self.isOpus then
		error("this audio is not Opus; read it with read", 0)
	end
end

--[=[
	@within Symphonia.Decoder

	Reads the session's state from libsymphonia, which a stream's worker thread changes on its own:
	- the first time the audio has opened, it fills `codec`, `container`, `sampleRate`, `channels`, `isOpus` and
	`durationSeconds`, sets `opened`, and logs it at debug;
	- once the session has failed, it sets `failed`, `failure` and `failedBeforeOpen`;
	- it always updates `state`.

	Call it from a loop that feeds a stream, before a push or a read that depends on the shape. `read`, `readFloat` and
	`readPacket` call it themselves until the audio has opened. After `destroy` it only logs at debug.
]=]
function Decoder.Prototype.refresh(self: Decoder)
	if self.destroyed then
		self.logger:debug(`decoder {self.id} was refreshed after it was destroyed; nothing to read`)

		return
	end

	local library = self.library
	local state = library.symphonia_info(self.id, Sys.infoField.state)
	local sampleRate = library.symphonia_info(self.id, Sys.infoField.sampleRate)
	local opensNow = not self.opened and sampleRate >= 0
	local failsNow = state == FAILED_STATE and not self.failed

	self.state = state

	if opensNow then
		local durationMilliseconds = library.symphonia_info(self.id, Sys.infoField.durationMilliseconds)

		self.codec = describe(library, self.id, Sys.describeField.codec, self.outputPointer)
		self.container = describe(library, self.id, Sys.describeField.container, self.outputPointer)
		self.sampleRate = sampleRate
		self.channels = library.symphonia_info(self.id, Sys.infoField.channels)
		self.durationSeconds = if durationMilliseconds >= 0 then durationMilliseconds / 1000 else nil
		self.isOpus = library.symphonia_info(self.id, Sys.infoField.isOpus) == 1
		self.opened = true
		self.logger:debug(`decoder {self.id} opened {self.codec} audio in a {self.container} container`)
	end

	if failsNow then
		self.failed = true
		self.failure = describe(library, self.id, Sys.describeField.failure, self.outputPointer, Sys.ERROR_CAPACITY)
		self.failedBeforeOpen = not self.opened
		self.logger:debug(`decoder {self.id} failed{if self.opened then "" else " before it opened"}: {self.failure}`)
	end
end

--[=[
	@within Symphonia.Decoder

	Queues the next piece of a stream's file, as a buffer or a string, and returns true. Returns false, with nothing
	queued, when the input is full (64 chunks): wait for the worker to catch up, read some output, and push the same
	chunk again. It never blocks.

	Raises `decoder has been destroyed` after `destroy`, `this decoder is not a stream` for a decoder from `fromBuffer`
	or `fromFile`, and `could not push audio: <reason>` when the session cannot take bytes any more: its failure text,
	`the stream has ended` for a session that finished decoding early, or `the stream was finished` after `finish`.
]=]
function Decoder.Prototype.push(self: Decoder, chunk: buffer | string): boolean
	self:checkStream()

	local input = if type(chunk) == "string" then buffer.fromstring(chunk) else chunk
	local result = self.library.symphonia_push(self.id, input, buffer.len(input))

	if result == Sys.FULL then
		self.logger:debug(`decoder {self.id} refused {buffer.len(input)} bytes because its input is full`)

		return false
	end

	if result < 0 then
		self:refresh()

		local reason = if self.failed
			then self.failure
			elseif self.finished then "the stream was finished"
			else "the stream has ended"

		error(`could not push audio: {reason}`, 0)
	end

	return true
end

--[=[
	@within Symphonia.Decoder

	Marks the end of a stream's input, so the session can decode what it holds and end. A second call logs at debug and
	does nothing.

	Raises `decoder has been destroyed` after `destroy` and `this decoder is not a stream` for any other decoder.
]=]
function Decoder.Prototype.finish(self: Decoder)
	self:checkStream()

	if self.finished then
		self.logger:debug(`decoder {self.id} was finished again; nothing to do`)

		return
	end

	self.finished = true
	self.library.symphonia_finish(self.id)
	self.logger:debug(`decoder {self.id} input finished`)
end

--[=[
	@within Symphonia.Decoder
	@private

	Raises when the decoder has been destroyed or is not a stream.
]=]
function Decoder.Prototype.checkStream(self: Decoder)
	if self.destroyed then
		error("decoder has been destroyed", 0)
	end

	if not self.isStream then
		error("this decoder is not a stream", 0)
	end
end

--[=[
	@within Symphonia.Decoder
	@private

	Brings `skippedPackets` up to the native count. The first skip of the decoder's life is warned and later ones are
	logged at debug, so a damaged file cannot warn on every read.
]=]
function Decoder.Prototype.noteSkippedPackets(self: Decoder)
	local skippedPackets = self.library.symphonia_info(self.id, Sys.infoField.skippedPackets)
	local newlySkipped = skippedPackets - self.skippedPackets
	local isFirstSkip = self.skippedPackets == 0 and newlySkipped > 0
	local laterSkips = if isFirstSkip then newlySkipped - 1 else newlySkipped

	if isFirstSkip then
		self.logger:warn("skipped an undecodable packet; later skips are logged at debug")
	end

	if laterSkips > 0 then
		self.logger:debug(
			`skipped {laterSkips} more undecodable packet{if laterSkips == 1 then "" else "s"}, {skippedPackets} in all`
		)
	end

	self.skippedPackets = math.max(skippedPackets, self.skippedPackets)
end

--[=[
	@within Symphonia.Decoder
	@private

	The body of `read`, `readFloat` and `readPacket`: the next float PCM, up to `floatFrames` frames, or the next packet,
	or nil at the end. A packet read ignores `floatFrames`.
]=]
function Decoder.Prototype.readNext(self: Decoder, readsOpus: boolean, floatFrames: number): buffer?
	if not self.opened then
		self:refresh()
	end

	self:checkReadable(readsOpus)

	if self.ended then
		self.logger:debug(`decoder {self.id} was read after its end`)

		return
	end

	if not self.opened and not self.failed then
		self.dry = true
		self.logger:debug(`decoder {self.id} was read before its stream opened`)

		return
	end

	local library = self.library
	local count = if readsOpus
		then library.symphonia_read_packet(
			self.id,
			self.outputPointer,
			Sys.MAX_PACKET_SIZE,
			self.errorPointer,
			Sys.ERROR_CAPACITY
		)
		else library.symphonia_read(
			self.id,
			self.outputPointer,
			floatFrames,
			self.errorPointer,
			Sys.ERROR_CAPACITY
		)

	self:noteSkippedPackets()

	if count == Sys.NOT_READY then
		self.dry = true
		self.logger:debug(`decoder {self.id} has no audio ready yet`)

		return
	end

	if count < 0 then
		error(`could not decode audio: {Buffer.fromCString(self.errorPointer, Sys.ERROR_CAPACITY)}`, 0)
	end

	self.dry = false

	if count == 0 then
		self.ended = true
		self.endedEarly = library.symphonia_info(self.id, Sys.infoField.endedEarly) == 1

		if self.endedEarly then
			self.logger:warn(
				"the audio ended early, short of the length the file states; it may be truncated or damaged"
			)
		end

		self.logger:debug(`decoder {self.id} reached the end of the audio`)

		return
	end

	return Buffer.read(self.outputPointer, if readsOpus then count else count * Sys.FLOAT_BYTES_PER_FRAME)
end

--[=[
	@within Symphonia.Decoder
	@private

	The next floats through `limiter`, as 16-bit PCM. It reads the frames the limiter needs to return `READ_FRAMES`:
	240 more on the first read, to fill the look-ahead. The result is empty only while a file shorter than that is
	filling it. A read that returns no floats before the end leaves the limiter as it is. Once the audio has ended, it
	flushes the limiter once and returns the frames it held. The read after those returns nil without reading again,
	so only a read past that nil reaches `readNext` and logs that it came after the end.
]=]
function Decoder.Prototype.readLimited(self: Decoder): buffer?
	local limiter = self.limiter

	if not limiter then
		error("decoder has been destroyed", 0)
	end

	local endingRead = self.ended and limiter.flushed and not self.endReturned
	local floats = if endingRead then nil else self:readNext(false, limiter:framesNeeded(Sys.READ_FRAMES))
	local tail = if floats or limiter.flushed or not self.ended then nil else limiter:flush()
	local pcm = if floats
		then limiter:process(floats, buffer.len(floats) // Sys.FLOAT_BYTES_PER_FRAME)
		elseif tail and buffer.len(tail) > 0 then tail
		else nil

	self.endReturned = self.endReturned or (self.ended and not pcm)

	return pcm
end

--[=[
	@within Symphonia.Decoder

	Returns up to `READ_FRAMES` (4800, 100 ms) frames of 48 kHz interleaved stereo 16-bit little-endian PCM, never an
	empty buffer, or nil at the end. An undecodable packet is skipped and counted in `skippedPackets`. A file cut short
	ends at the audio it holds; when that falls short of the length the file states, it sets `endedEarly`, with one
	warning.

	The samples are libsymphonia's floats through `limiter`: a non-finite sample becomes 0, then the volume applies,
	ramped over 20 ms after a change, and audio that would pass full scale is limited with 5 ms of look-ahead instead
	of clipped. Audio that never passes full scale comes out bit for bit as a plain conversion. The limiter holds the
	last 240 frames (5 ms) back, so the first read decodes 240 frames more than it returns and every read returns 100
	ms until the audio runs out. The read that reaches the end sets `ended` and returns the frames the limiter held;
	the next returns nil, as does every read after it. The frame count in all is the file's own.

	On a stream, a read also returns nil, with `dry` set and `ended` not, while nothing is ready; the limiter keeps what
	it holds and is flushed only at the true end, so keep reading after a dry nil.

	Raises `this audio is Opus; read it with readPacket` for Opus, `decoder has been destroyed` after `destroy`, and
	`could not decode audio: <message>` when the file cannot be decoded further.
]=]
function Decoder.Prototype.read(self: Decoder): buffer?
	local pcm = self:readLimited()

	while pcm and buffer.len(pcm) == 0 do
		pcm = self:readLimited()
	end

	return pcm
end

--[=[
	@within Symphonia.Decoder

	Returns up to `READ_FRAMES` (4800, 100 ms) frames of 48 kHz interleaved stereo 32-bit float little-endian PCM,
	exactly as libsymphonia decoded them, without `volume` and without conversion; samples may pass full scale. It
	returns nil, sets `ended` and `endedEarly`, and raises, as `read` does. On a stream it also returns nil, with `dry`
	set and `ended` not, while nothing is ready.

	It shares the decoded stream with `read`, and mixing the two is allowed: each frame comes out exactly once, through
	one or the other. Frames `readFloat` takes bypass `limiter`, so the next `read` first returns the up to 240 frames
	the limiter held from before them, and the frames it holds at the end come out only through a `read` after the end.
]=]
function Decoder.Prototype.readFloat(self: Decoder): buffer?
	return self:readNext(false, Sys.READ_FRAMES)
end

--[=[
	@within Symphonia.Decoder

	Returns the next Opus packet as it is stored in the file, or nil at the end, which sets `ended`; a read after the
	end returns nil again. Empty packets are skipped and counted in `skippedPackets`. A file cut short ends at the
	packets it holds; Opus is not decoded, so `endedEarly` stays false. On a stream it also returns nil, with `dry` set
	and `ended` not, while no packet is ready.

	The packets play as they are, without the OpusHead's pre-skip, end trimming or output gain.

	Raises `this audio is not Opus; read it with read` for anything else, `decoder has been destroyed` after `destroy`,
	and `could not decode audio: <message>` when the file cannot be read further.
]=]
function Decoder.Prototype.readPacket(self: Decoder): buffer?
	return self:readNext(true, Sys.READ_FRAMES)
end

--[=[
	@within Symphonia.Decoder

	Sets the volume of the PCM that `read` returns: a number from 0 to 4, where 1 leaves the audio as it is. The
	decoder's `limiter` applies it to the frames the next read takes, ramped over 20 ms so it never clicks, and limits
	audio it would push past full scale instead of clipping it. The look-ahead holds 240 frames, so the change is heard
	5 ms into the next read. `readFloat` is never changed by it.

	An Opus decoder passes its packets through undecoded, so the volume has no effect on it: the value is kept and the
	first call logs a warning.

	Raises `volume must be a number from 0 to 4` for anything else, and `decoder has been destroyed` after `destroy`.
]=]
function Decoder.Prototype.setVolume(self: Decoder, volume: number)
	local limiter = self.limiter

	Decoder.Interface.checkVolume(volume)

	if not limiter then
		error("decoder has been destroyed", 0)
	end

	limiter:setVolume(volume)
	self.volume = volume

	if self.isOpus and not self.warnedOpusVolume then
		self.warnedOpusVolume = true
		self.logger:warn("volume has no effect on Opus passed through as stored")
	end
end

--[=[
	@within Symphonia.Decoder

	Closes the native session, and the file for `fromFile`, frees the decoder's native memory and releases its
	`limiter`. A second call does nothing.
]=]
function Decoder.Prototype.destroy(self: Decoder)
	if self.destroyed then
		self.logger:debug(`decoder {self.id} is already destroyed; nothing to free`)

		return
	end

	self.destroyed = true
	self.ended = true
	self.limiter = nil
	self.library.symphonia_close(self.id)
	Buffer.free(self.errorPointer)
	Buffer.free(self.outputPointer)
	self.logger:debug(`decoder {self.id} destroyed`)
end

--[=[
	@within Symphonia.Decoder

	Raises `volume must be a number from 0 to 4` unless `volume` is a number in that range. This is the boundary where
	users hand in a volume of any type: a non-number is checked as NaN, so it raises the same message from
	`Limiter.checkVolume`, which owns the range and the message. `setVolume` and the audio file sources use it.
]=]
function Decoder.Interface.checkVolume(volume: unknown)
	local number = if type(volume) == "number" then volume else 0 / 0

	Limiter.checkVolume(number)
end

--[=[
	@within Symphonia.Decoder
	@yields

	Opens a whole file held in memory, as a buffer or a string. The bytes are handed to libsymphonia as they are, which
	copies them, so the input can be dropped afterwards. The format is found from the content alone:
	`options.extension` (such as `"mp3"`, without the dot) is passed to libsymphonia, but Symphonia 0.6.1's probe does
	not read it, so it currently has no effect.

	Loads the library first, so the first call always yields, even when the library is cached; see
	`Symphonia.Sys.load`. Raises `could not open audio: <message>` for anything libsymphonia cannot open.
]=]
function Decoder.Interface.fromBuffer(bytes: buffer | string, options: DecoderOptions?): Decoder
	local library = Sys.load()
	local decoderOptions: DecoderOptions = options or {}
	local decoderLogger = logger.new("SymphoniaDecoder", decoderOptions.logLevel or "Info")
	local input = if type(bytes) == "string" then buffer.fromstring(bytes) else bytes
	local length = buffer.len(input)
	local extension = if decoderOptions.extension then Buffer.cString(decoderOptions.extension) else Buffer.getNull()
	local errorPointer = Buffer.alloc(Sys.ERROR_CAPACITY)
	local id = library.symphonia_open_memory(input, length, extension, errorPointer, Sys.ERROR_CAPACITY)

	return newDecoder(library, id, errorPointer, decoderLogger, false)
end

--[=[
	@within Symphonia.Decoder
	@yields

	Opens the file at `path` and streams it from the disk as it is read, without reading it into Luau. The format is
	found from the content alone: `options.extension`, or else the path's own extension, is passed to libsymphonia, but
	Symphonia 0.6.1's probe does not read it, so it currently has no effect.

	Loads the library first, so the first call always yields, even when the library is cached; see
	`Symphonia.Sys.load`. Raises `could not open audio: the path contains a NUL byte` before opening anything, since
	the library would read only the path's text before the NUL, and `could not open audio: <message>` for a missing
	file or anything libsymphonia cannot open.
]=]
function Decoder.Interface.fromFile(path: string, options: DecoderOptions?): Decoder
	local library = Sys.load()
	local decoderOptions: DecoderOptions = options or {}
	local decoderLogger = logger.new("SymphoniaDecoder", decoderOptions.logLevel or "Info")
	local pathString = Buffer.cString(path)
	local extension = if decoderOptions.extension then Buffer.cString(decoderOptions.extension) else Buffer.getNull()

	if string.find(path, "\0", 1, true) then
		error("could not open audio: the path contains a NUL byte", 0)
	end

	local errorPointer = Buffer.alloc(Sys.ERROR_CAPACITY)
	local id = library.symphonia_open_file(pathString, extension, errorPointer, Sys.ERROR_CAPACITY)

	return newDecoder(library, id, errorPointer, decoderLogger, false)
end

--[=[
	@within Symphonia.Decoder
	@yields

	Opens a stream session for a file that arrives in pieces, decoded on a worker thread: feed it with `push`, end the
	input with `finish`, and read as for any decoder. The session starts probing, with `opened` false, and `refresh`
	opens it once enough bytes have arrived. Reads never block: they return nil with `dry` set while nothing is ready.
	Nothing here destroys the session: call `destroy` when done, even after a failure.

	Loads the library first, so the first call always yields; see `Symphonia.Sys.load`. Raises
	`could not open audio: <message>` if the session cannot be created.
]=]
function Decoder.Interface.fromStream(options: DecoderOptions?): Decoder
	local library = Sys.load()
	local decoderOptions: DecoderOptions = options or {}
	local decoderLogger = logger.new("SymphoniaDecoder", decoderOptions.logLevel or "Info")
	local errorPointer = Buffer.alloc(Sys.ERROR_CAPACITY)
	local id = library.symphonia_open_stream(errorPointer, Sys.ERROR_CAPACITY)

	return newDecoder(library, id, errorPointer, decoderLogger, true)
end

--[=[
	@interface DecoderOptions
	@within Symphonia.Decoder
	.extension string? -- The file's extension without the dot, such as `"mp3"`. Currently unused: Symphonia 0.6.1 finds the format from the content alone.
	.logLevel logger.LogLevel? -- The level of the decoder's logger; `Info` by default.
]=]
export type DecoderOptions = {
	extension: string?,
	logLevel: logger.LogLevel?,
}

export type Decoder = typeof(Decoder.Prototype) & {
	id: number,
	codec: string,
	container: string,
	sampleRate: number,
	channels: number,
	durationSeconds: number?,
	isOpus: boolean,
	opened: boolean,
	dry: boolean,
	state: number,
	failed: boolean,
	failure: string?,
	failedBeforeOpen: boolean,
	isStream: boolean,
	finished: boolean,
	ended: boolean,
	endedEarly: boolean,
	destroyed: boolean,
	skippedPackets: number,
	volume: number,
	limiter: Limiter.Limiter?,
	endReturned: boolean,
	warnedOpusVolume: boolean,
	logger: logger.Logger,
	library: Sys.Lib,
	errorPointer: FFIPointer,
	outputPointer: FFIPointer,
}

return Decoder.Interface
