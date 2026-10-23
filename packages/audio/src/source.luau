--[=[
	@class Audio.Source
	@__index Prototype

	A single-use stream of Opus packets for an audio player. `audio.fromOpus` and `audio.fromPCM` build one from Opus
	packets or PCM; `audio.fromFile`, `audio.fromEncoded` and the named file sources (`fromMP3`, `fromFLAC` and the
	rest) build one from an audio file, decoded with `discord_luau/symphonia`. The player that claims a source reads it
	to its end and destroys it, so a source plays once.

	A PCM source re-chunks its input into 20 ms frames of 48 kHz stereo 16-bit little-endian PCM (3840 bytes) as it is
	read, zero-pads the last frame and encodes each frame with one Opus encoder, created on the first frame. It holds at
	most one partial frame and a reference to the input buffer it is reading, however long the input is.

	A file source holds a native decoder session, and for `fromFile` an open file, from the moment it is built until
	`destroy`. A `playAsync` that starts destroys its source on every exit; a source never handed to one, or handed to
	one that fails its start checks or is never awaited, must be released with `source:destroy()`.

	A stream source, from `audio.fromStream`, plays a file that arrives in pieces. Its `feed`, an `Audio.StreamFeed`,
	opens a libsymphonia stream session on the first `poll`, which the player makes, runs the pump that calls the
	stream's `read`, and reads decoded audio ahead into a queue of up to 6 seconds, before any volume, so a volume change
	is heard within about 20 ms. The source itself limits, frames and encodes that audio, and decides when it is
	`starved`, so the player waits until `bufferSeconds` of audio is buffered, and again whenever the queue and the
	decoder both run dry. A failure after the stream opened plays the audio queued before it first. `read` never yields.
]=]

--[=[
	@prop format "opus" | "pcm"
	@within Audio.Source

	What the input holds: Opus packets, passed through as they are, or PCM, encoded as it is read. A stream source holds
	`"pcm"` until its stream opens as Opus.
]=]

--[=[
	@prop items { buffer }?
	@within Audio.Source

	The input array; a whole PCM buffer is stored as a one-item array. Nil when the input is a function.
]=]

--[=[
	@prop iterator (() -> buffer?)?
	@within Audio.Source

	The input function, which returns the next buffer and nil at the end. Nil when the input is an array.
]=]

--[=[
	@prop itemCount number
	@within Audio.Source

	How many input items the source has taken.
]=]

--[=[
	@prop inputEnded boolean
	@within Audio.Source

	Whether the input gave nil, so an input function is never called again after its end.
]=]

--[=[
	@prop chunk buffer?
	@within Audio.Source

	The PCM input buffer being read.
]=]

--[=[
	@prop chunkOffset number
	@within Audio.Source

	How many bytes of `chunk` are used.
]=]

--[=[
	@prop frame buffer?
	@within Audio.Source

	The reusable 3840-byte PCM frame, created on the first PCM read.
]=]

--[=[
	@prop frameFill number
	@within Audio.Source

	How many bytes `frame` holds.
]=]

--[=[
	@prop totalBytes number
	@within Audio.Source

	The PCM bytes taken so far.
]=]

--[=[
	@prop encoder opus.Encoder?
	@within Audio.Source

	The Opus encoder of a PCM source, created on its first frame and freed when the source ends or is destroyed.
]=]

--[=[
	@prop bitrate number
	@within Audio.Source

	The bitrate in bits per second that every encoder the source creates is set to; `options.bitrate`, or 128000.
	A source that passes Opus through never encodes, so it holds the value without using it.
]=]

--[=[
	@prop volume number
	@within Audio.Source

	The volume of a file or stream source's decoded audio, from 0 to 4; `options.volume`, or 1. Other sources hold 1.
]=]

--[=[
	@prop decoder symphonia.Decoder?
	@within Audio.Source
	@private

	A file source's decoder, which `setVolume` reaches. Nil for every other source; a stream source's session belongs to
	its `feed`.
]=]

--[=[
	@prop feed Audio.StreamFeed?
	@within Audio.Source

	A stream source's feed: its session, its pump and its read-ahead queue, with `feed.bufferedSeconds`,
	`feed.stopping` and `feed.producerEnded`. Nil for every other source.
]=]

--[=[
	@prop starved boolean
	@within Audio.Source

	Whether a stream source has no audio ready yet: true from the start until its first `poll` finds `bufferSeconds`
	buffered, and again whenever `read` finds the queue empty and the decoder dry. Only `poll` clears it, once
	`bufferSeconds` of audio is buffered, the stream can bring no more audio, or the source has ended. A `read` that
	returns nil while it is true means "no data yet", not the end. Every other source holds false.
]=]

--[=[
	@prop failure string?
	@within Audio.Source

	Why a stream source failed, set once the failure is final and nothing queued before it is left to play: at once
	for a failure before the stream opened, and after the queued audio for one after. `read` raises it from then on.
	Nil for every other source.
]=]

--[=[
	@prop bufferSeconds number
	@within Audio.Source

	How many seconds of audio a stream source buffers before it stops being `starved`; `options.bufferSeconds`, or 1.
	Every other source holds 0.
]=]

--[=[
	@prop limiter Symphonia.Limiter?
	@within Audio.Source
	@private

	A stream source's own limiter, holding its volume: `read` feeds it the queued audio and encodes what leaves it.
	Nil for every other source.
]=]

--[=[
	@prop release (() -> ())?
	@within Audio.Source
	@private

	Frees what a file or stream source holds: a file source's decoder session, and for `fromFile` its open file, or a
	stream source's feed. `destroy` clears it before it calls it, so it runs once. Nil for every other source.
]=]

--[=[
	@prop played boolean
	@within Audio.Source

	Whether a player has claimed the source.
]=]

--[=[
	@prop ended boolean
	@within Audio.Source

	Whether the source has ended or been destroyed; `read` returns nil from then on.
]=]

--[=[
	@prop logger logger.Logger
	@within Audio.Source

	The source's logger, named `AudioSource` and at `Info`; lower its level to see the debug lines.
]=]

local logger = require("../luau_packages/logger")
local opus = require("../luau_packages/opus")
local symphonia = require("../luau_packages/symphonia")

local streamFeed = require("./streamFeed")

local PCM_SAMPLE_BYTES = opus.DISCORD_CHANNELS * 2
local PCM_FRAME_BYTES = opus.DISCORD_FRAME_SIZE * PCM_SAMPLE_BYTES

local DEFAULT_BITRATE = 128000
local DEFAULT_BUFFER_SECONDS = 1
local MIN_BUFFER_SECONDS = 0.1
local MAX_BUFFER_SECONDS = 4

local Source = {}

Source.Interface = {}
Source.Prototype = {}

local function checkedBitrate(options: { bitrate: number? }?): number
	local requested: unknown = if options then options.bitrate else nil
	local bitrate = if requested or requested == false then requested :: number else DEFAULT_BITRATE

	opus.checkBitrate(bitrate)

	return bitrate
end

local function checkedVolume(options: { volume: number? }?): number
	local requested: unknown = if options then options.volume else nil
	local volume = if requested or requested == false then requested :: number else 1

	symphonia.decoder.checkVolume(volume)

	return volume
end

local function checkedBufferSeconds(options: StreamOptions?): number
	local requested: unknown = if options then options.bufferSeconds else nil
	local requestedType = type(requested)
	local bufferSeconds = if requestedType == "nil"
		then DEFAULT_BUFFER_SECONDS
		elseif requestedType == "number" then requested :: number
		else 0 / 0

	if not (bufferSeconds >= MIN_BUFFER_SECONDS and bufferSeconds <= MAX_BUFFER_SECONDS) then
		error(`bufferSeconds must be a number from {MIN_BUFFER_SECONDS} to {MAX_BUFFER_SECONDS}`, 0)
	end

	return bufferSeconds
end

local function checkedLogLevel(options: StreamOptions?): logger.LogLevel?
	local logLevel: logger.LogLevel? = if options then options.logLevel else nil

	if logLevel then
		logger.new("SymphoniaDecoder", logLevel)
	end

	return logLevel
end

local function misalignedMessage(byteCount: number): string
	return `PCM input is {byteCount} bytes, which is not a whole number of samples ({PCM_SAMPLE_BYTES} bytes each: 16-bit stereo)`
end

local function newSource(
	format: SourceFormat,
	items: { buffer }?,
	iterator: (() -> buffer?)?,
	release: (() -> ())?,
	bitrate: number
): Source
	return setmetatable(
		{
			format = format,
			items = items,
			iterator = iterator,
			bitrate = bitrate,
			volume = 1,
			itemCount = 0,
			inputEnded = false,
			chunkOffset = 0,
			frameFill = 0,
			totalBytes = 0,
			release = release,
			played = false,
			ended = false,
			starved = false,
			bufferSeconds = 0,
			logger = logger.new("AudioSource", "Info"),
		} :: Source,
		{ __index = Source.Prototype }
	)
end

local function decoderSource(decoder: symphonia.Decoder, bitrate: number, volume: number): Source
	local function release()
		decoder:destroy()
	end

	local source = if decoder.isOpus
		then newSource("opus", nil, function(): buffer?
			return decoder:readPacket()
		end, release, bitrate)
		else newSource("pcm", nil, function(): buffer?
			return decoder:read()
		end, release, bitrate)

	source.decoder = decoder

	if volume ~= 1 then
		local applied, failure = pcall(source.setVolume, source, volume)

		if not applied then
			source.logger:warn(`setting the audio source's volume failed, destroying it: {failure}`)
			source:destroy()
			error(failure, 0)
		end
	end

	return source
end

local function encodedSource(name: string, bytes: buffer | string, options: FileOptions?): Source
	local inputType = type(bytes)

	if inputType ~= "buffer" and inputType ~= "string" then
		error(`audio.{name} takes the file's bytes as a buffer or string; for a path use audio.fromFile`, 3)
	end

	local bitrate = checkedBitrate(options)
	local volume = checkedVolume(options)

	return decoderSource(symphonia.decoder.fromBuffer(bytes, options), bitrate, volume)
end

local function namedOptions(extension: string, options: NamedOptions?): FileOptions
	return {
		extension = extension,
		logLevel = if options then options.logLevel else nil,
		bitrate = if options then options.bitrate else nil,
		volume = if options then options.volume else nil,
	}
end

local function streamSource(
	options: StreamOptions?,
	makeFeed: (logLevel: logger.LogLevel?, sourceLogger: logger.Logger) -> StreamFeed
): Source
	local bitrate = checkedBitrate(options)
	local volume = checkedVolume(options)
	local bufferSeconds = checkedBufferSeconds(options)
	local logLevel: logger.LogLevel? = checkedLogLevel(options)
	local limiter = symphonia.limiter.new()
	local source = newSource("pcm", nil, nil, nil, bitrate)
	local feed = makeFeed(logLevel, source.logger)

	limiter:setVolume(volume)
	source.feed = feed
	source.release = function()
		feed:destroy()
	end
	source.volume = volume
	source.bufferSeconds = bufferSeconds
	source.limiter = limiter
	source.starved = true

	return source
end

--[=[
	@within Audio.Source
	@private

	Takes the next input item: the next array entry or the input function's next result. Nil marks the end of the
	input. Raises for an item that is not a buffer, and an input function's own error propagates.
]=]
function Source.Prototype.nextItem(self: Source): buffer?
	local itemIndex = self.itemCount + 1
	local item: unknown = if self.iterator then self.iterator() else (self.items :: { buffer })[itemIndex]
	local itemType = typeof(item)

	if itemType == "nil" then
		self.inputEnded = true
		self.logger:debug(`audio source input ended after {self.itemCount} items`)

		return
	end

	if itemType ~= "buffer" then
		error(`audio source item {itemIndex} is a {itemType}, not a buffer`, 0)
	end

	self.itemCount = itemIndex

	return item :: buffer
end

--[=[
	@within Audio.Source
	@private

	Copies PCM input into the frame until it holds 3840 bytes or the input ends, taking the next input item only when
	the frame needs more bytes.
]=]
function Source.Prototype.fillFrame(self: Source, frame: buffer)
	while self.frameFill < PCM_FRAME_BYTES and not self.inputEnded do
		local chunk = self.chunk
		local available = if chunk then buffer.len(chunk) - self.chunkOffset else 0
		local copied = math.min(available, PCM_FRAME_BYTES - self.frameFill)

		if chunk and copied > 0 then
			buffer.copy(frame, self.frameFill, chunk, self.chunkOffset, copied)
			self.frameFill += copied
			self.chunkOffset += copied
			self.totalBytes += copied
		else
			self.chunk = self:nextItem()
			self.chunkOffset = 0
		end
	end
end

--[=[
	@within Audio.Source
	@private

	Creates an Opus encoder set to the source's bitrate and the `"music"` signal hint, and frees it if a setting raises.
]=]
function Source.Prototype.createEncoder(self: Source): opus.Encoder
	local encoder = opus.encoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS, opus.application.audio)
	local configured, failure = pcall(function()
		encoder:setBitrate(self.bitrate)
		encoder:setSignal("music")
	end)

	if not configured then
		self.logger:warn(`configuring the audio source's encoder failed: {failure}`)
		encoder:destroy()
		error(failure, 0)
	end

	return encoder
end

--[=[
	@within Audio.Source
	@private

	Encodes the frame, creating the encoder on the first frame, and empties it.
]=]
function Source.Prototype.encodeFrame(self: Source, frame: buffer): buffer
	local encoder: opus.Encoder = self.encoder or self:createEncoder()

	self.encoder = encoder
	self.frameFill = 0

	return encoder:encode(frame)
end

--[=[
	@within Audio.Source
	@private

	Reads the next 20 ms of PCM and encodes it. At the end of the input, an empty frame ends the source, and a partial
	frame is zero-padded and encoded, unless the input's total is not a whole number of samples, which raises.
]=]
function Source.Prototype.readPcm(self: Source): buffer?
	local frame = self.frame or buffer.create(PCM_FRAME_BYTES)

	self.frame = frame
	self:fillFrame(frame)

	if self.frameFill == PCM_FRAME_BYTES then
		return self:encodeFrame(frame)
	end

	if self.frameFill == 0 then
		self:destroy()
		self.logger:debug(`audio source ended after {self.totalBytes} bytes of PCM`)

		return
	end

	if self.totalBytes % PCM_SAMPLE_BYTES ~= 0 then
		error(misalignedMessage(self.totalBytes), 0)
	end

	buffer.fill(frame, self.frameFill, 0)

	return self:encodeFrame(frame)
end

--[=[
	@within Audio.Source
	@private

	Feeds the feed's queued float audio through the source's limiter into the frame until it holds 960 limited frames
	or the queue and the decoder run dry. The limiter holds back its 240-frame look-ahead, so the first packet takes
	1200 frames in. A partial frame is kept for the next read.
]=]
function Source.Prototype.fillLimitedFrame(self: Source, frame: buffer, feed: StreamFeed)
	local limiter = self.limiter :: Limiter

	while self.frameFill < PCM_FRAME_BYTES do
		local wanted = limiter:framesNeeded((PCM_FRAME_BYTES - self.frameFill) // PCM_SAMPLE_BYTES)
		local floats, frames = feed:takeFloats(wanted)

		if not floats then
			break
		end

		local pcm = limiter:process(floats, frames)

		buffer.copy(frame, self.frameFill, pcm)
		self.frameFill += buffer.len(pcm)
	end
end

--[=[
	@within Audio.Source
	@private

	The end of a PCM stream, once the feed can bring no more audio: flushes the limiter once, frames what it held, and
	zero-pads and encodes the last frame, so the last real audio plays. Once nothing is left, `endStream` raises a
	failure or ends the source.
]=]
function Source.Prototype.endStreamPcm(self: Source, frame: buffer, feed: StreamFeed): buffer?
	local limiter = self.limiter :: Limiter

	if not limiter.flushed then
		self.chunk = limiter:flush()
		self.chunkOffset = 0
	end

	local tail = self.chunk :: buffer
	local copied = math.min(buffer.len(tail) - self.chunkOffset, PCM_FRAME_BYTES - self.frameFill)

	buffer.copy(frame, self.frameFill, tail, self.chunkOffset, copied)
	self.frameFill += copied
	self.chunkOffset += copied

	if self.frameFill == 0 then
		self:endStream(feed)

		return
	end

	buffer.fill(frame, self.frameFill, 0, PCM_FRAME_BYTES - self.frameFill)

	return self:encodeFrame(frame)
end

--[=[
	@within Audio.Source
	@private

	The next 20 ms of a PCM stream, limited at the source's volume and encoded. A queue and a decoder that run dry
	before the frame is full set `starved` and keep the partial frame; only the end of the stream flushes the limiter
	and pads.
]=]
function Source.Prototype.readStreamPcm(self: Source, feed: StreamFeed): buffer?
	local frame = self.frame or buffer.create(PCM_FRAME_BYTES)

	self.frame = frame
	self:fillLimitedFrame(frame, feed)

	if self.frameFill == PCM_FRAME_BYTES then
		return self:encodeFrame(frame)
	end

	if not feed:outputDone() then
		self:starve(` {self.frameFill // PCM_SAMPLE_BYTES} frames into a packet`)

		return
	end

	return self:endStreamPcm(frame, feed)
end

--[=[
	@within Audio.Source
	@private

	The next Opus packet of an Opus stream, as stored. A queue and a decoder that run dry set `starved`; once the feed
	can bring no more audio, `endStream` raises a failure or ends the source.
]=]
function Source.Prototype.readStreamPacket(self: Source, feed: StreamFeed): buffer?
	local packet = feed:takePacket()

	if packet then
		return packet
	end

	if feed:outputDone() then
		self:endStream(feed)
	else
		self:starve("")
	end

	return
end

--[=[
	@within Audio.Source
	@private

	Marks a stream that ran dry during a read as `starved`, logged at debug with `detail`.
]=]
function Source.Prototype.starve(self: Source, detail: string)
	self.starved = true
	self.logger:debug(`the audio stream ran dry{detail}; waiting for data`)
end

--[=[
	@within Audio.Source
	@private

	Runs when a stream has nothing left to play. While a program's exit code is not known yet, or a stream that failed
	before it opened may still open, the stream has not ended, so the source waits `starved` for it. Then it raises its
	failure, now final, or ends the source when the stream simply ended.
]=]
function Source.Prototype.endStream(self: Source, feed: StreamFeed)
	if not feed:hasEnded() then
		self.starved = true
		self.logger:debug(`the audio stream played everything it had; waiting for the program's exit or the open`)

		return
	end

	self:settleFailure(feed)

	local failure = self.failure

	if failure then
		error(failure, 0)
	end

	self:destroy()
	self.logger:debug(`the audio stream ended`)
end

--[=[
	@within Audio.Source
	@private

	Makes the feed's pending failure the source's `failure` once it is final: before the stream opened, since nothing
	was queued, as soon as the open is decided (see `StreamFeed:openDecided`) and the program's exit is settled, and
	after it opened only once the stream has ended and nothing is left to play.
]=]
function Source.Prototype.settleFailure(self: Source, feed: StreamFeed)
	local pendingFailure = feed.pendingFailure
	local beforeOpen = not feed:isOpen() and feed:openDecided() and feed:exitSettled()
	local final = beforeOpen or (feed:hasEnded() and not self:hasAudioLeft(feed))

	if pendingFailure and not self.failure and final then
		self.failure = pendingFailure
		self.logger:debug(`the audio stream's failure is final: {pendingFailure}`)
	end
end

--[=[
	@within Audio.Source
	@private

	Whether a stream source still holds audio to play: queued in the feed, in the partial frame, held in the limiter's
	look-ahead, or flushed from it and not yet framed.
]=]
function Source.Prototype.hasAudioLeft(self: Source, feed: StreamFeed): boolean
	local limiter = self.limiter :: Limiter
	local tail = self.chunk
	local tailLeft = if tail then buffer.len(tail) > self.chunkOffset else false

	return feed:hasQueued() or self.frameFill > 0 or limiter.heldFrames > 0 or tailLeft
end

--[=[
	@within Audio.Source
	@private

	The body of `read` for a stream source. Before the stream opens it raises a failure already final, or returns nil
	with `starved` set; then it returns the next packet.
]=]
function Source.Prototype.readStream(self: Source, feed: StreamFeed): buffer?
	if not feed:isOpen() then
		self:settleFailure(feed)
	end

	local failure = self.failure

	if failure then
		error(failure, 0)
	end

	if not feed:isOpen() then
		self.starved = true
		self.logger:debug(`the audio stream was read before it opened`)

		return
	end

	if feed:isOpus() then
		return self:readStreamPacket(feed)
	end

	return self:readStreamPcm(feed)
end

--[=[
	@within Audio.Source
	@private

	The body of `read`: the next packet from the input, with no cleanup when it raises. A stream source's failure is
	raised first, on every call.
]=]
function Source.Prototype.readPacket(self: Source): buffer?
	local failure = self.failure
	local feed = self.feed

	if failure then
		error(failure, 0)
	end

	if self.ended then
		self.logger:debug(`read after the audio source ended`)

		return
	end

	if feed then
		return self:readStream(feed)
	end

	if self.format == "pcm" then
		return self:readPcm()
	end

	local packet = self:nextItem()

	if not packet then
		self.ended = true
	end

	return packet
end

--[=[
	@within Audio.Source

	Returns the next Opus packet, or nil once the source has ended. An Opus source returns its next input item; a PCM
	source returns the next 20 ms of its input, encoded. Raises for an input item that is not a buffer, a PCM total that
	is not a whole number of samples (4 bytes each), an input function's error and an encoder error. Any raise ends the
	source and frees its encoder first, then passes the original error on, so a later `read` returns nil.

	A stream source never yields here. It raises its `failure` first, on every call. Otherwise it fills an empty queue
	from the decoder and returns the next packet, or nil with `starved` set when the queue and the decoder are both dry,
	which means "no data yet" rather than the end. Once the stream can bring no more audio and nothing is left, it
	raises a failure the feed met, after the queued audio and the limiter's last frames have played, or returns nil
	at the true end.
]=]
function Source.Prototype.read(self: Source): buffer?
	local succeeded, result = pcall(self.readPacket, self)

	if not succeeded then
		self.logger:warn(`audio source read failed, ending the source: {result}`)

		local destroyed, destroyFailure = pcall(self.destroy, self)

		if not destroyed then
			self.logger:warn(`destroying the audio source failed: {destroyFailure}`)
		end

		error(result, 0)
	end

	return result
end

--[=[
	@within Audio.Source
	@yields

	Moves a stream source along; any other source only logs at debug. It polls the `feed`: the first call opens the
	stream's session, which loads libsymphonia on first use and so may yield, and starts the pump, and every call reads
	the session's state and fills the queue. A failure the feed met becomes `failure` once it is final and nothing
	queued before it is left to play. Then it clears `starved` once `bufferSeconds` of audio is buffered, the stream
	can bring no more audio, or it has failed. The player calls it every 20 ms while the source is starved. It never
	raises: the next `read` raises `failure`.
]=]
function Source.Prototype.poll(self: Source)
	local feed = self.feed

	if not feed then
		self.logger:debug(`polled an audio source that is not a stream; nothing to do`)

		return
	end

	if self.ended then
		self.starved = false
		self.logger:debug(`polled the audio stream after it ended; it no longer waits for data`)

		return
	end

	feed:poll()

	if feed:isOpus() then
		self.format = "opus"
	end

	self:settleFailure(feed)

	if self.starved and not self.failure and feed:hasEnded() and not self:hasAudioLeft(feed) then
		self:endStream(feed)
		self.starved = false
	elseif self.starved and self:isReady(feed) then
		self.starved = false
		self.logger:debug(`the audio stream is ready with {feed.bufferedSeconds} s buffered`)
	end
end

--[=[
	@within Audio.Source
	@private

	Whether a starved stream may play: `bufferSeconds` of audio is buffered, the feed can bring no more audio, so what
	it holds plays out, or the stream has failed.
]=]
function Source.Prototype.isReady(self: Source, feed: StreamFeed): boolean
	return if self.failure then true else feed:hasEnded() or feed.bufferedSeconds >= self.bufferSeconds
end

--[=[
	@within Audio.Source

	Sets the volume of a file or stream source's decoded audio: a number from 0 to 4, where 1 leaves it as it is. A file
	source hears it at the next 100 ms read of the file, and a stream source at its next packet, since its queue holds
	audio before any volume; either way it is ramped in over 20 ms so it never clicks, and `source.volume` holds it.
	Audio that would pass full scale is limited rather than clipped. Opus passed through is not decoded, so the volume
	has no effect on it; the value is kept, and a file decoder warns once.

	Raises `volume must be a number from 0 to 4` for anything else, `audio source has ended` after the source has
	ended or been destroyed, and `audio source has no file decoder; volume applies to file sources` for `fromOpus` and
	`fromPCM` sources.
]=]
function Source.Prototype.setVolume(self: Source, volume: number)
	symphonia.decoder.checkVolume(volume)

	local decoder = self.decoder
	local limiter = self.limiter

	if self.ended then
		error("audio source has ended", 0)
	end

	if limiter then
		limiter:setVolume(volume)
	elseif decoder then
		decoder:setVolume(volume)
	else
		error("audio source has no file decoder; volume applies to file sources", 0)
	end

	self.volume = volume
end

--[=[
	@within Audio.Source

	Marks the source as played. Raises `audio source has already been played` when a player has claimed it before.
]=]
function Source.Prototype.claim(self: Source)
	if self.played then
		error(`audio source has already been played`, 0)
	end

	self.played = true
end

--[=[
	@within Audio.Source

	Ends the source and frees what it holds: a file source's decoder session and open file, a stream source's feed, and
	a PCM source's encoder. It acts even after the source has ended, while anything is left to free, and a call with
	nothing left logs at debug and does nothing. The release runs once, and one that raises is warned and never raises
	from `destroy`.

	For a stream source it destroys the feed: its pump stops at its next check, without `destroy` waiting for it, so a
	pump inside the stream's `read` stops once that read returns. A playback waiting on the starved source ends
	without speaking.
]=]
function Source.Prototype.destroy(self: Source)
	local encoder = self.encoder
	local release = self.release

	if self.ended and not encoder and not release then
		self.logger:debug(`audio source already ended; nothing to free`)

		return
	end

	self.ended = true
	self.encoder = nil
	self.release = nil

	if release then
		local released, releaseFailure = pcall(function()
			release()

			return true
		end)

		if not released then
			self.logger:warn(`releasing the audio source failed: {releaseFailure}`)
		end
	end

	if encoder then
		encoder:destroy()
	end
end

--[=[
	@within Audio.Source

	Builds a source from Opus packets: an array, read in order up to its first nil, or a function that returns the next
	packet and nil at the end. Each packet passes through as it is. Raises unless `packets` is a table or a function;
	for a buffer or string, the error points at `fromOgg` and `fromFile`, which play an `.opus` file.

	A function input must return the next packet quickly: one that takes longer than a frame leaves a gap in the
	audio, and one that never returns holds the playback, which `stop` cannot end.
]=]
function Source.Interface.fromOpus(packets: { buffer } | () -> buffer?): Source
	local inputType = type(packets)
	local isFileBytes = inputType == "buffer" or inputType == "string"

	if inputType == "function" then
		return newSource("opus", nil, packets :: () -> buffer?, nil, DEFAULT_BITRATE)
	end

	if isFileBytes then
		error(
			`audio.fromOpus takes an array of Opus packets or a function that returns the next one; for an .opus file use audio.fromOgg or audio.fromFile`,
			2
		)
	end

	if inputType ~= "table" then
		error(`audio.fromOpus takes an array of Opus packets or a function that returns the next one`, 2)
	end

	return newSource("opus", packets :: { buffer }, nil, nil, DEFAULT_BITRATE)
end

--[=[
	@within Audio.Source

	Builds a source from 48 kHz stereo 16-bit little-endian PCM: one buffer, an array of buffers, or a function that
	returns the next buffer and nil at the end. Buffers may be any length, empty ones included. Raises unless `pcm` is
	one of those, and raises for a buffer whose length is not a whole number of samples (4 bytes each); an array's or a
	function's total is checked when its input ends, so `read` raises instead.

	`options.bitrate` sets the encoder's bitrate in bits per second, a whole number from 500 to 510000 (128000 by
	default). It is checked at this call with `opus.checkBitrate`, because the encoder is created on the first read; a
	bad value raises there. The encoder also gets the `"music"` signal hint.

	A function input must return the next buffer quickly: one that takes longer than a frame leaves a gap in the
	audio, and one that never returns holds the playback, which `stop` cannot end.
]=]
function Source.Interface.fromPCM(pcm: buffer | { buffer } | () -> buffer?, options: PCMOptions?): Source
	local inputType = type(pcm)
	local byteCount = if inputType == "buffer" then buffer.len(pcm :: buffer) else 0
	local bitrate = checkedBitrate(options)

	if inputType == "buffer" and byteCount % PCM_SAMPLE_BYTES ~= 0 then
		error(misalignedMessage(byteCount), 2)
	end

	if inputType == "buffer" then
		return newSource("pcm", { pcm :: buffer }, nil, nil, bitrate)
	end

	if inputType == "function" then
		return newSource("pcm", nil, pcm :: () -> buffer?, nil, bitrate)
	end

	if inputType ~= "table" then
		error(`audio.fromPCM takes a buffer of PCM, an array of buffers or a function that returns the next buffer`, 2)
	end

	return newSource("pcm", pcm :: { buffer }, nil, nil, bitrate)
end

--[=[
	@within Audio.Source
	@yields

	Plays the audio file at `path`, streamed from the disk as it plays rather than read into Luau. Otherwise as
	`fromEncoded`: the same formats, errors, Opus passthrough and release rule. A slow disk stalls the whole VM while a
	read waits on it.

	Raises `could not open audio: <message>` for a missing file or one that cannot be opened, and
	`audio.fromFile takes the file's path as a string; for the file's bytes use audio.fromEncoded` for anything but a
	string. The source holds the open file and a native decoder session from the moment it is built: a source not
	handed to a `playAsync` that starts must be released with `source:destroy()`.

	`options.bitrate` is as for `fromPCM`, and applies to the audio that is encoded; a bad one raises before the file
	is opened.

	`options.volume` (1) is a number from 0 to 4, checked at the call like the bitrate, and sets the volume of the
	decoded audio; see `source:setVolume`.
]=]
function Source.Interface.fromFile(path: string, options: FileOptions?): Source
	local pathType = type(path)

	if pathType ~= "string" then
		error(`audio.fromFile takes the file's path as a string; for the file's bytes use audio.fromEncoded`, 2)
	end

	local bitrate = checkedBitrate(options)
	local volume = checkedVolume(options)

	return decoderSource(symphonia.decoder.fromFile(path, options), bitrate, volume)
end

--[=[
	@within Audio.Source
	@yields

	Plays an audio file held in memory, as a buffer or a string of its bytes, such as what `fs.readFile` returns. A
	string is the file's bytes, never a path; use `fromFile` for a path. The file is decoded with
	`discord_luau/symphonia`, which finds the format from the content alone:
	- decoded to PCM and encoded to Opus as it plays: MP1, MP2 and MP3; AAC-LC, mono or stereo; FLAC; Vorbis; PCM;
	  ADPCM, mono or stereo; ALAC; in WAV, AIFF, CAF, Ogg, Matroska, WebM, MP4 and M4A, or as a bare MP3, FLAC or ADTS
	  stream. PCM, FLAC, Vorbis and ALAC in any channel layout are mixed to stereo; AAC and ADPCM with more than two
	  channels fail to open. HE-AAC that states its SBR fails to open, and HE-AAC that signals it only inside the
	  stream plays only its band-limited LC core;
	- passed through as it is stored: single-stream Opus in Ogg, WebM, Matroska or MP4, without the pre-skip (about
	  6.5 ms), the end trimming (up to one packet) or the OpusHead output gain that an Opus decoder would apply.

	The first file source loads libsymphonia, which always yields, may download it, and checks it, which blocks for
	about 360 ms; call `audio.loadFileDecoder()` at startup to take that cost early. Opening and each read block on
	native code.

	Raises `could not open audio: <message>` for a file that cannot be opened, and
	`audio.fromEncoded takes the file's bytes as a buffer or string; for a path use audio.fromFile` for anything else.
	A file that fails to decode partway fails its playback with `audio source failed: could not decode audio: <message>`.

	The source holds a native decoder session from the moment it is built: a source not handed to a `playAsync` that
	starts must be released with `source:destroy()`.

	`options.bitrate` is as for `fromPCM`, and applies to the audio that is encoded; a bad one raises before the file
	is decoded. The named sources take the same option.

	`options.volume` (1) is a number from 0 to 4, checked at the call, and sets the volume of the decoded audio; see
	`source:setVolume`. The named sources take it too.
]=]
function Source.Interface.fromEncoded(bytes: buffer | string, options: FileOptions?): Source
	return encodedSource("fromEncoded", bytes, options)
end

--[=[
	@within Audio.Source
	@yields

	Plays an MP3 file held in memory, as a buffer or a string of its bytes; MP1 and MP2 play too. An alias of
	`fromEncoded`, whose rules apply: the format is found from the content, so any supported file plays here too, and a
	source not handed to a `playAsync` that starts must be released with `source:destroy()`.
]=]
function Source.Interface.fromMP3(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromMP3", bytes, namedOptions("mp3", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays an Ogg file held in memory, as a buffer or a string of its bytes: Vorbis and FLAC are decoded, and Opus, an
	`.opus` file, is passed through. An alias of `fromEncoded`, whose rules apply: the format is found from the
	content, so any supported file plays here too, and a source not handed to a `playAsync` that starts must be
	released with `source:destroy()`.
]=]
function Source.Interface.fromOgg(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromOgg", bytes, namedOptions("ogg", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays a WAV file held in memory, as a buffer or a string of its bytes: PCM, or ADPCM in mono or stereo. An alias of
	`fromEncoded`, whose rules apply: the format is found from the content, so any supported file plays here too, and a
	source not handed to a `playAsync` that starts must be released with `source:destroy()`.
]=]
function Source.Interface.fromWAV(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromWAV", bytes, namedOptions("wav", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays a FLAC file held in memory, as a buffer or a string of its bytes. An alias of `fromEncoded`, whose rules
	apply: the format is found from the content, so any supported file plays here too, and a source not handed to a
	`playAsync` that starts must be released with `source:destroy()`.
]=]
function Source.Interface.fromFLAC(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromFLAC", bytes, namedOptions("flac", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays an ADTS AAC file (`.aac`) held in memory, as a buffer or a string of its bytes: AAC-LC, mono or stereo.
	HE-AAC that states its SBR fails to open, and HE-AAC that signals it only inside the stream, as most ADTS files do,
	plays only its band-limited LC core. An alias of `fromEncoded`, whose rules apply: the format is found from the
	content, so any supported file plays here too, and a source not handed to a `playAsync` that starts must be
	released with `source:destroy()`.
]=]
function Source.Interface.fromAAC(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromAAC", bytes, namedOptions("aac", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays an M4A or MP4 file held in memory, as a buffer or a string of its bytes: AAC-LC in mono or stereo and ALAC are
	decoded, and Opus is passed through. A 5.1 AAC track, common in video files, fails to open. An alias of
	`fromEncoded`, whose rules apply: the format is found from the content, so any supported file plays here too, and a
	source not handed to a `playAsync` that starts must be released with `source:destroy()`.
]=]
function Source.Interface.fromM4A(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromM4A", bytes, namedOptions("m4a", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays a WebM file held in memory, as a buffer or a string of its bytes: Opus is passed through, and Vorbis is
	decoded. An alias of `fromEncoded`, whose rules apply: the format is found from the content, so any supported file
	plays here too, and a source not handed to a `playAsync` that starts must be released with `source:destroy()`.
]=]
function Source.Interface.fromWebM(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromWebM", bytes, namedOptions("webm", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays a Matroska file (`.mkv` or `.mka`) held in memory, as a buffer or a string of its bytes: Opus is passed
	through, and the other supported codecs are decoded. An alias of `fromEncoded`, whose rules apply: the format is
	found from the content, so any supported file plays here too, and a source not handed to a `playAsync` that starts
	must be released with `source:destroy()`.
]=]
function Source.Interface.fromMKV(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromMKV", bytes, namedOptions("mkv", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays an AIFF file held in memory, as a buffer or a string of its bytes. An alias of `fromEncoded`, whose rules
	apply: the format is found from the content, so any supported file plays here too, and a source not handed to a
	`playAsync` that starts must be released with `source:destroy()`.
]=]
function Source.Interface.fromAIFF(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromAIFF", bytes, namedOptions("aiff", options))
end

--[=[
	@within Audio.Source
	@yields

	Plays a Core Audio Format file (`.caf`) held in memory, as a buffer or a string of its bytes. An alias of
	`fromEncoded`, whose rules apply: the format is found from the content, so any supported file plays here too, and a
	source not handed to a `playAsync` that starts must be released with `source:destroy()`.
]=]
function Source.Interface.fromCAF(bytes: buffer | string, options: NamedOptions?): Source
	return encodedSource("fromCAF", bytes, namedOptions("caf", options))
end

--[=[
	@within Audio.Source

	Plays an audio file that arrives in pieces, such as internet radio or a media URL fetched in HTTP range requests.
	`read` returns the next chunk of the file's bytes, as a buffer or a string of any length, and nil at the end; it may
	yield for as long as the next bytes take. The formats are those of `fromEncoded`. An MP4 or M4A with its index at
	the end, and a CAF, cannot be read from the front: once the stream fails to open on one, the rest of the file is
	read and the whole file plays, with memory up to about 4 times its size, and a file over 128 MiB fails with
	`could not open audio: this file must be complete before it plays and is larger than 128 MiB`.

	This call only checks and records the options: it never calls `read`, yields, opens a decoder session or starts a
	thread. The player's first `poll` does that, inside `playAsync`, so a source that is never played holds nothing.
	From then on a pump thread calls `read` and pushes the bytes, in slices of at most 64 KiB, into a libsymphonia
	stream session, and decoded audio is read ahead up to 6 seconds. The playback sends Speaking once
	`options.bufferSeconds` of audio is buffered; when the stream stalls, it sends its silence tail and Speaking 0,
	waits, and speaks again on a fresh schedule once `bufferSeconds` is buffered again. `player:stop()` and
	`source:destroy()` end those waits.

	The playback fails with `audio source failed: <reason>`, where the reason is `audio stream read failed: <error>`
	for a `read` that raises, `could not open audio: <message>` for bytes that are not audio,
	`could not open audio: the stream ended before any audio` for a stream that gives no bytes,
	`could not decode audio: <message>` for one that fails partway, and
	`invalid Opus packet from the audio source: <error>` for an Opus stream with a bad packet. A failure before the
	stream opened ends the playback at once, without Speaking. One after it plays the audio that came before it first:
	what was queued, and for a `read` that raises, every byte it had already returned. A stream that ends early, such
	as a WAV followed by other bytes, stops being read and plays the audio it decoded.

	Options, each checked at the call:
	- `volume` (1), a number from 0 to 4, as for `fromEncoded`; `source:setVolume` changes it mid-song, heard at the
	next packet;
	- `bitrate` (128000), as for `fromPCM`;
	- `bufferSeconds` (1), a number from 0.1 to 4: how much audio to buffer before playing, and again after a stall;
	- `logLevel`, the level of the stream session's logger, `SymphoniaDecoder`.

	Raises `audio.fromStream takes a function that returns the next chunk of the file's bytes` when `read` is not a
	function, `bufferSeconds must be a number from 0.1 to 4`, and the volume, bitrate and log level messages.
]=]
function Source.Interface.fromStream(read: StreamReader, options: StreamOptions?): Source
	local readType = type(read)

	if readType ~= "function" then
		error(`audio.fromStream takes a function that returns the next chunk of the file's bytes`, 2)
	end

	return streamSource(options, function(logLevel: logger.LogLevel?, sourceLogger: logger.Logger): StreamFeed
		return streamFeed.new(read, logLevel, sourceLogger)
	end)
end

--[=[
	@within Audio.Source

	Plays what a program writes to its stdout, such as `yt-dlp` or `ffmpeg` writing a file to `-`. The program runs
	directly, without a shell, with stderr kept for errors and stdin ignored. Otherwise it is a stream source, as for
	`fromStream`: the same formats, buffering, stalls, options and failures, read from the program's output, which is
	joined into chunks of up to 64 KiB.

	Nothing starts at this call. The player's first `poll` starts the program; one that cannot start fails the playback
	with `audio source failed: could not start <command>: <reason>`, such as `FileNotFound`, without Speaking.

	Once the program's stdout ends, the stream waits up to 5 seconds for its exit code, and the playback has not ended
	until it is known. A non-zero code wins over every other outcome, a failure to open or decode and the clean end:
	`audio source failed: <command> exited with code <n>: <last stderr line>`, or `no error output`. A program that does
	not exit within 5 seconds is killed, with a warning, and the stream ends normally. The program is also killed when
	the stream stops reading it while its stdout is still open, such as after bytes that are not audio or a failure met
	while the stream waits for the program to write, and when the source is destroyed; a code that follows such a kill
	is ignored.

	Raises `audio.fromProcess takes the program to run as a string` and
	`audio.fromProcess takes the program's arguments as an array of strings` for anything else, and the option messages
	of `fromStream`.
]=]
function Source.Interface.fromProcess(command: string, arguments: { string }?, options: StreamOptions?): Source
	local commandType = type(command)
	local argumentsType = type(arguments)
	local argumentList: { string } = if argumentsType == "table" then table.clone(arguments :: { string }) else {}

	if commandType ~= "string" or command == "" then
		error(`audio.fromProcess takes the program to run as a string`, 2)
	end

	if argumentsType ~= "nil" and argumentsType ~= "table" then
		error(`audio.fromProcess takes the program's arguments as an array of strings`, 2)
	end

	for _, argument in argumentList do
		local argumentType = type(argument)

		if argumentType ~= "string" then
			error(`audio.fromProcess takes the program's arguments as an array of strings`, 2)
		end
	end

	return streamSource(options, function(logLevel: logger.LogLevel?, sourceLogger: logger.Logger): StreamFeed
		return streamFeed.fromProcess(command, argumentList, logLevel, sourceLogger)
	end)
end

type SourceFormat = "opus" | "pcm"
type Limiter = typeof(symphonia.limiter.new())

--[=[
	@interface FileOptions
	@within Audio.Source
	.extension string? -- The file's extension without the dot, such as `"mp3"`. Passed to libsymphonia, which currently ignores it: the format is always found from the content.
	.logLevel logger.LogLevel? -- The level of the file decoder's logger, `SymphoniaDecoder`; `Info` by default.
	.bitrate number? -- The Opus bitrate in bits per second, a whole number from 500 to 510000; 128000 by default. Checked at the call, because the encoder is created on the first read. Unused for Opus passed through.
	.volume number? -- The volume of the decoded audio, from 0 to 4; 1 by default. Checked at the call. No effect on Opus passed through.
]=]
export type FileOptions = {
	extension: string?,
	logLevel: logger.LogLevel?,
	bitrate: number?,
	volume: number?,
}

--[=[
	@interface NamedOptions
	@within Audio.Source
	.logLevel logger.LogLevel? -- The level of the file decoder's logger, `SymphoniaDecoder`; `Info` by default.
	.bitrate number? -- The Opus bitrate in bits per second, a whole number from 500 to 510000; 128000 by default.
	.volume number? -- The volume of the decoded audio, from 0 to 4; 1 by default.
]=]
export type NamedOptions = {
	logLevel: logger.LogLevel?,
	bitrate: number?,
	volume: number?,
}

--[=[
	@interface PCMOptions
	@within Audio.Source
	.bitrate number? -- The Opus bitrate in bits per second, a whole number from 500 to 510000; 128000 by default.
]=]
export type PCMOptions = {
	bitrate: number?,
}

--[=[
	@interface StreamOptions
	@within Audio.Source
	.volume number? -- The volume of the decoded audio, from 0 to 4; 1 by default. No effect on Opus passed through.
	.bitrate number? -- The Opus bitrate in bits per second, a whole number from 500 to 510000; 128000 by default. Unused for Opus passed through.
	.bufferSeconds number? -- How many seconds of audio to buffer before playing, and again after a stall, from 0.1 to 4; 1 by default.
	.logLevel logger.LogLevel? -- The level of the stream session's logger, `SymphoniaDecoder`; `Info` by default.
]=]
export type StreamOptions = {
	volume: number?,
	bitrate: number?,
	bufferSeconds: number?,
	logLevel: logger.LogLevel?,
}

export type StreamReader = streamFeed.StreamReader
export type StreamFeed = streamFeed.StreamFeed

export type Source = typeof(Source.Prototype) & {
	format: SourceFormat,
	items: { buffer }?,
	iterator: (() -> buffer?)?,
	itemCount: number,
	inputEnded: boolean,
	chunk: buffer?,
	chunkOffset: number,
	frame: buffer?,
	frameFill: number,
	totalBytes: number,
	bitrate: number,
	volume: number,
	decoder: symphonia.Decoder?,
	encoder: opus.Encoder?,
	release: (() -> ())?,
	played: boolean,
	ended: boolean,
	starved: boolean,
	failure: string?,
	bufferSeconds: number,
	feed: StreamFeed?,
	limiter: Limiter?,
	logger: logger.Logger,
}

return Source.Interface
