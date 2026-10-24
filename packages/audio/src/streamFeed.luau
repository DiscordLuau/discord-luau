--[=[
	@class Audio.StreamFeed
	@__index Prototype

	Feeds a stream source from `audio.fromStream` or `audio.fromProcess`. It opens a libsymphonia stream session, runs
	the pump, a thread that reads the stream's bytes and pushes them into the session, and keeps the read-ahead: a queue
	of decoded audio of up to 6 seconds, as 48 kHz stereo 32-bit float blocks before any volume, or as Opus packets as
	stored. The `Source` that owns it takes audio from the queue, decides when the stream is starved, and surfaces its
	failures.

	A failure the feed meets is kept as `pendingFailure`, and the source raises it once the audio queued before it has
	played. The pump stops at a failure, at the end of the input, when the session can take no more bytes, and at
	`destroy`, which never waits for it.

	For `fromProcess`, the feed spawns the program on the first `poll` and reads its stdout. Once stdout ends it waits
	up to 5 seconds for the exit code; a non-zero code wins over every other outcome, with the last line of stderr as
	its reason, and a program that does not exit is killed, with a warning. A program is killed only while its stdout is
	still open, or at `destroy`, and a code that follows its own kill is ignored. A failure met while the pump waits on
	stdout kills the program at once, so the failure does not wait for the program to write or exit. Until the exit is
	known the stream has not ended.

	An MP4 with its index at the end, or a CAF, cannot be read from the front: the session fails before it opens. The
	feed keeps every byte until the session opens, up to 128 MiB, and on that failure, when the stream starts with an
	MP4 (`ftyp` at byte 4) or CAF (`caff` at byte 0) marker, reads the rest of the stream, opens the whole file with
	`Symphonia.Decoder.fromBuffer` and plays it through the same queue. Peak memory is up to about 4 times the file.
]=]

--[=[
	@prop decoder symphonia.Decoder?
	@within Audio.StreamFeed
	@private

	The stream session from the first `poll`, or after the whole-file fallback the decoder of the whole file; nil before
	the first `poll` and when the session could not be opened.
]=]

--[=[
	@prop pump thread?
	@within Audio.StreamFeed

	The pump's thread, nil until the first `poll` opens the session.
]=]

--[=[
	@prop stopping boolean
	@within Audio.StreamFeed

	Whether `destroy` has asked the pump to stop. The pump checks it after every read, push and wait.
]=]

--[=[
	@prop producerEnded boolean
	@within Audio.StreamFeed

	Whether the stream's input has ended: its `read` returned nil, or the program's stdout closed.
]=]

--[=[
	@prop bufferedSeconds number
	@within Audio.StreamFeed

	How many seconds of decoded audio the queue holds, up to about 6.
]=]

--[=[
	@prop pendingFailure string?
	@within Audio.StreamFeed

	The failure the feed met, kept until the source has played the audio queued before it. The first failure wins,
	except a program's non-zero exit code, which wins over every other.
]=]

--[=[
	@prop command string?
	@within Audio.StreamFeed

	The program `fromProcess` runs; nil for `fromStream`.
]=]

--[=[
	@prop arguments { string }
	@within Audio.StreamFeed

	The program's arguments; empty for `fromStream`.
]=]

--[=[
	@prop process Process?
	@within Audio.StreamFeed
	@private

	The running program, from the first `poll`; nil for `fromStream` and when the program could not start.
]=]

--[=[
	@prop exitCode number?
	@within Audio.StreamFeed

	The program's exit code once it is known; nil until then, and when the code followed the feed's own kill.
]=]

--[=[
	@prop failedAtMillis number?
	@within Audio.StreamFeed
	@private

	When `pendingFailure` was first set, in Unix milliseconds; nil until the feed fails.
]=]

--[=[
	@prop exitKnown boolean
	@within Audio.StreamFeed

	Whether the program's exit is settled: its code is known, or the feed killed it, which makes the code meaningless.
	Always false for `fromStream`, which has no program; see `exitSettled`.
]=]

--[=[
	@prop killedByUs boolean
	@within Audio.StreamFeed
	@private

	Whether the feed killed the program, so its exit code is ignored.
]=]

--[=[
	@prop fallbackEnabled boolean
	@within Audio.StreamFeed

	Whether the whole-file fallback can still run: true until the bytes kept before the session opened pass
	`maxRetainedBytes`.
]=]

--[=[
	@prop fallingBack boolean
	@within Audio.StreamFeed
	@private

	Whether the session failed before it opened on an MP4 or CAF stream, so the pump reads the rest of the file to open
	it whole.
]=]

--[=[
	@prop retained buffer?
	@within Audio.StreamFeed
	@private

	Every byte read before the session opened, in one buffer that doubles as it grows; nil once the session opens, past
	the cap, and after the fallback opened the file.
]=]

--[=[
	@prop retainedBytes number
	@within Audio.StreamFeed
	@private

	How many bytes of `retained` are used.
]=]

--[=[
	@prop maxRetainedBytes number
	@within Audio.StreamFeed
	@private

	The most bytes kept for the fallback, 128 MiB. Tests lower it to reach the cap.
]=]

--[=[
	@prop firstBytes string
	@within Audio.StreamFeed
	@private

	The stream's first 8 bytes, always kept for the MP4 and CAF marker check.
]=]

--[=[
	@prop outputClosed boolean
	@within Audio.StreamFeed
	@private

	Whether the feed has stopped reading the session's output for good: a read raised, an Opus packet was not valid,
	or the pump failed. No more audio will reach the queue.
]=]

--[=[
	@prop started boolean
	@within Audio.StreamFeed
	@private

	Whether the first `poll` has started the stream: spawned the program and opened the session, or tried to.
]=]

--[=[
	@prop pipeReading boolean
	@within Audio.StreamFeed
	@private

	Whether a read of the program's stdout is in flight.
]=]

--[=[
	@prop pipeDone boolean
	@within Audio.StreamFeed
	@private

	Whether the read in flight has finished; `pipeData` holds its bytes, nil at the end of stdout, and `pipeFailure` its
	error when it raised.
]=]

--[=[
	@prop pipeData buffer?
	@within Audio.StreamFeed
	@private

	The bytes the finished stdout read returned.
]=]

--[=[
	@prop pipeFailure string?
	@within Audio.StreamFeed
	@private

	The error of the finished stdout read when it raised; the pump raises it when it takes that read.
]=]

--[=[
	@prop pipeWaiter thread?
	@within Audio.StreamFeed
	@private

	The pump, while it waits for the stdout read in flight.
]=]

--[=[
	@prop reader StreamReader?
	@within Audio.StreamFeed
	@private

	The stream's `read`, which returns the next chunk of the file's bytes and nil at the end; nil for `fromProcess`.
]=]

--[=[
	@prop logLevel logger.LogLevel?
	@within Audio.StreamFeed
	@private

	The level of the stream session's logger, `SymphoniaDecoder`.
]=]

--[=[
	@prop queue { buffer }
	@within Audio.StreamFeed
	@private

	The read-ahead, oldest first: float blocks or Opus packets.
]=]

--[=[
	@prop queueOffset number
	@within Audio.StreamFeed
	@private

	How many bytes of the first queued float block have been taken.
]=]

--[=[
	@prop bufferedFrames number
	@within Audio.StreamFeed
	@private

	How many 48 kHz frames the queue holds; `bufferedSeconds` is this over 48000.
]=]

--[=[
	@prop streamBytes number
	@within Audio.StreamFeed
	@private

	How many bytes the stream has given so far.
]=]

--[=[
	@prop logger logger.Logger
	@within Audio.StreamFeed

	The owning source's logger, `AudioSource`, which the feed logs through.
]=]

local logger = require("../luau_packages/logger")
local stdPolyfills = require("../luau_packages/std_polyfills")
local symphonia = require("../luau_packages/symphonia")
local voice = require("../luau_packages/voice")

local FLOAT_FRAME_BYTES = symphonia.sys.FLOAT_BYTES_PER_FRAME
local SAMPLE_RATE = symphonia.OUTPUT_SAMPLE_RATE
local MAX_READ_AHEAD_FRAMES = 6 * SAMPLE_RATE
local MAX_PUSH_BYTES = 64 * 1024
local FULL_INPUT_WAIT_SECONDS = 0.02
local ENDED_STATE = 2
local PIPE_READ_BYTES = 1024
local EXIT_WAIT_MILLISECONDS = 5000
local EXIT_POLL_SECONDS = 0.02
local STDERR_WAIT_MILLISECONDS = 250
local OUTCOME_POLL_SECONDS = 0.02
local OPEN_DECISION_MILLISECONDS = 500
local MARKER_BYTES = 8
local MAX_RETAINED_BYTES = 128 * 1024 * 1024
local MIN_RETAINED_CAPACITY = 64 * 1024
local CAP_FAILURE = "could not open audio: this file must be complete before it plays and is larger than 128 MiB"

local StreamFeed = {}

StreamFeed.Interface = {}
StreamFeed.Prototype = {}

local function sliceOf(input: buffer, offset: number, length: number): buffer
	local piece = buffer.create(length)

	buffer.copy(piece, 0, input, offset, length)

	return piece
end

local function joined(pieces: { buffer }, length: number): buffer
	local whole = buffer.create(length)
	local offset = 0

	for _, piece in pieces do
		buffer.copy(whole, offset, piece)
		offset += buffer.len(piece)
	end

	return whole
end

local function blockFrames(block: buffer, isOpus: boolean): number
	return if isOpus then voice.opusSamples(block) else buffer.len(block) // FLOAT_FRAME_BYTES
end

local function lastLine(text: string): string?
	local last: string? = nil

	for line in string.gmatch(text, "[^\r\n]+") do
		last = if string.find(line, "%S") then line else last
	end

	return last
end

local function nowMillis(): number
	return stdPolyfills.datetime.now().unixTimestampMillis
end

local function newFeed(
	reader: StreamReader?,
	command: string?,
	arguments: { string },
	logLevel: logger.LogLevel?,
	sourceLogger: logger.Logger
): StreamFeed
	return setmetatable(
		{
			reader = reader,
			command = command,
			arguments = arguments,
			logLevel = logLevel,
			started = false,
			stopping = false,
			producerEnded = false,
			outputClosed = false,
			exitKnown = false,
			killedByUs = false,
			fallbackEnabled = true,
			fallingBack = false,
			retainedBytes = 0,
			maxRetainedBytes = MAX_RETAINED_BYTES,
			firstBytes = "",
			pipeReading = false,
			pipeDone = false,
			queue = {},
			queueOffset = 0,
			bufferedFrames = 0,
			bufferedSeconds = 0,
			streamBytes = 0,
			logger = sourceLogger,
		} :: StreamFeed,
		{ __index = StreamFeed.Prototype }
	)
end

--[=[
	@within Audio.StreamFeed
	@yields

	Moves the stream along. The first call spawns the program, for `fromProcess`, then opens the session, which loads
	libsymphonia on first use and so may yield, and starts the pump; a program that cannot start or a failed open
	becomes `pendingFailure`. Every call then reads the session's state and fills the queue. Does nothing after
	`destroy`.
]=]
function StreamFeed.Prototype.poll(self: StreamFeed)
	if not self.started and not self.stopping then
		self:start()
	end

	if self.decoder and not self.stopping then
		self:refresh()
		self:fill()
	end
end

--[=[
	@within Audio.StreamFeed

	Whether the session has opened, so the queue's kind of audio is known.
]=]
function StreamFeed.Prototype.isOpen(self: StreamFeed): boolean
	local decoder = self.decoder

	return if decoder then decoder.opened else false
end

--[=[
	@within Audio.StreamFeed

	Whether the session opened as Opus, so the queue holds Opus packets rather than float blocks.
]=]
function StreamFeed.Prototype.isOpus(self: StreamFeed): boolean
	local decoder = self.decoder

	return if decoder then decoder.opened and decoder.isOpus else false
end

--[=[
	@within Audio.StreamFeed

	Whether no more audio will reach the queue: the session has ended, or the feed stopped reading its output after a
	failure. What is still queued plays first.
]=]
function StreamFeed.Prototype.outputDone(self: StreamFeed): boolean
	local decoder = self.decoder
	local decoderEnded = if decoder then decoder.ended else false

	return self.outputClosed or decoderEnded
end

--[=[
	@within Audio.StreamFeed

	Whether the session's open is decided, so that a failure met before it opened is final. It is when the session has
	opened or failed before it opened, when there is no session or the stream gave no bytes, and 500 ms after the
	failure. A stream that fails just after bytes the session has not probed yet so plays them first whenever they
	open, rather than depending on which of the two the source saw first.
]=]
function StreamFeed.Prototype.openDecided(self: StreamFeed): boolean
	local decoder = self.decoder
	local failedAt = self.failedAtMillis
	local waitedOut = if failedAt then nowMillis() - failedAt >= OPEN_DECISION_MILLISECONDS else false

	return if decoder then decoder.opened or decoder.failedBeforeOpen or self.streamBytes == 0 or waitedOut else true
end

--[=[
	@within Audio.StreamFeed

	Whether the program's exit is settled: always for `fromStream`, and for `fromProcess` once the exit code is known or
	the feed killed the program.
]=]
function StreamFeed.Prototype.exitSettled(self: StreamFeed): boolean
	return if self.process then self.exitKnown else true
end

--[=[
	@within Audio.StreamFeed

	Whether the stream has ended: no more audio will reach the queue, the program's exit is settled, and the open is
	decided (see `openDecided`), so a stream that may still open is never taken for ended. This is the one test for the
	end of the stream.
]=]
function StreamFeed.Prototype.hasEnded(self: StreamFeed): boolean
	return self:outputDone() and self:exitSettled() and self:openDecided()
end

--[=[
	@within Audio.StreamFeed

	Whether the queue holds any audio.
]=]
function StreamFeed.Prototype.hasQueued(self: StreamFeed): boolean
	return if self.queue[1] then true else false
end

--[=[
	@within Audio.StreamFeed

	Takes up to `maxFrames` float frames from the first queued block, filling the queue from the session first when it
	is empty. Returns the floats and how many frames to use from them, or nil and 0 when nothing is ready.
]=]
function StreamFeed.Prototype.takeFloats(self: StreamFeed, maxFrames: number): (buffer?, number)
	local block = self:firstBlock()
	local offset = self.queueOffset
	local available = if block then (buffer.len(block) - offset) // FLOAT_FRAME_BYTES else 0
	local frames = math.min(maxFrames, available)
	local floats = if block and offset > 0 then sliceOf(block, offset, frames * FLOAT_FRAME_BYTES) else block

	if block then
		self:advance(block, frames)
	end

	return floats, frames
end

--[=[
	@within Audio.StreamFeed

	Takes the next queued Opus packet, filling the queue from the session first when it is empty. Nil when nothing is
	ready.
]=]
function StreamFeed.Prototype.takePacket(self: StreamFeed): buffer?
	local packet = self:firstBlock()

	if packet then
		table.remove(self.queue, 1)
		self:countBuffered(-voice.opusSamples(packet))
	end

	return packet
end

--[=[
	@within Audio.StreamFeed
	@private

	Returns the first queued block, filling the queue from the session first when it is empty, so audio the session
	holds plays on while the stream's input waits.
]=]
function StreamFeed.Prototype.firstBlock(self: StreamFeed): buffer?
	if not self.queue[1] then
		self:fill()
	end

	return self.queue[1]
end

--[=[
	@within Audio.StreamFeed
	@private

	Moves past `frames` frames of the first queued block, dropping the block once it is used up.
]=]
function StreamFeed.Prototype.advance(self: StreamFeed, block: buffer, frames: number)
	local offset = self.queueOffset + frames * FLOAT_FRAME_BYTES

	if offset >= buffer.len(block) then
		table.remove(self.queue, 1)
		offset = 0
	end

	self.queueOffset = offset
	self:countBuffered(-frames)
end

--[=[
	@within Audio.StreamFeed

	Moves ready output from the session into the queue, up to 6 seconds. A read that raises, which is a failure after
	the session opened, and an Opus packet that is not valid each become `pendingFailure` and close the output. Does
	nothing before the session opens, after `destroy` or once the output is closed.
]=]
function StreamFeed.Prototype.fill(self: StreamFeed)
	local decoder = self.decoder

	if not decoder or self.stopping or self.outputClosed then
		self.logger:debug(`the audio stream's queue was not filled: it is not open, destroyed or closed`)

		return
	end

	if not decoder.opened then
		self:refresh()
	end

	local isOpus = decoder.isOpus

	while decoder.opened and not decoder.ended and self.bufferedFrames < MAX_READ_AHEAD_FRAMES do
		local read, block = pcall(if isOpus then decoder.readPacket else decoder.readFloat, decoder)

		if not read then
			self.outputClosed = true
			self:fail(tostring(block))

			break
		end

		if not block then
			break
		end

		local counted, frames = pcall(blockFrames, block, isOpus)

		if not counted then
			self.outputClosed = true
			self:fail(`invalid Opus packet from the audio source: {frames}`)

			break
		end

		table.insert(self.queue, block)
		self:countBuffered(frames)
	end
end

--[=[
	@within Audio.StreamFeed

	Reads the session's state. Once it has opened, the bytes kept for the fallback are dropped. A session that failed
	before it opened sends an MP4 or CAF stream into the whole-file fallback, fails one that is past the cap with the
	128 MiB message, and fails any other with `could not open audio: <reason>`.
]=]
function StreamFeed.Prototype.refresh(self: StreamFeed)
	local decoder = self.decoder :: symphonia.Decoder

	decoder:refresh()

	if decoder.opened and self.retained then
		self.retained = nil
		self.retainedBytes = 0
		self.logger:debug(`the audio stream opened; dropped the bytes kept for the whole-file fallback`)
	end

	if decoder.failedBeforeOpen and not self.pendingFailure and not self.fallingBack then
		self:noteFailedOpen(decoder)
	end
end

--[=[
	@within Audio.StreamFeed

	Stops the pump at its next check, kills the program unless its exit is already settled, closes the session,
	whichever decoder it is by then, and drops the queue and the kept bytes. It never waits for the pump: a pump inside
	the stream's `read` stops once that read returns. A second call logs at debug.
]=]
function StreamFeed.Prototype.destroy(self: StreamFeed)
	local decoder = self.decoder
	local process = self.process

	if self.stopping then
		self.logger:debug(`the audio stream's feed was destroyed again; nothing to free`)

		return
	end

	self.stopping = true
	self.queue = {}
	self.queueOffset = 0
	self.retained = nil
	self.retainedBytes = 0
	self:countBuffered(-self.bufferedFrames)

	if process and not self.exitKnown then
		self:killProcess(process)
	end

	if decoder then
		decoder:destroy()
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Decides what a session that failed before it opened means: the fallback for an MP4 or CAF stream while it is
	enabled, the 128 MiB message for one past the cap, and `could not open audio: <reason>` for anything else.
]=]
function StreamFeed.Prototype.noteFailedOpen(self: StreamFeed, decoder: symphonia.Decoder)
	if self:hasMarker() and self.fallbackEnabled then
		self.fallingBack = true
		self.logger:debug(`the audio stream is a file that must be complete before it plays; reading it to the end`)
	elseif self:hasMarker() then
		self:fail(CAP_FAILURE)
	else
		self:fail(`could not open audio: {decoder.failure}`)
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Whether the stream's first bytes mark an MP4 (`ftyp` at byte 4) or a CAF (`caff` at byte 0), the files that must be
	complete before they play.
]=]
function StreamFeed.Prototype.hasMarker(self: StreamFeed): boolean
	local firstBytes = self.firstBytes

	return string.sub(firstBytes, 5, 8) == "ftyp" or string.sub(firstBytes, 1, 4) == "caff"
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Spawns the program, for `fromProcess`, then opens the session and starts the pump.
]=]
function StreamFeed.Prototype.start(self: StreamFeed)
	local spawned = if self.command then self:spawn() else true

	self.started = true

	if spawned then
		self:open()
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Starts the program. A program that cannot start becomes `pendingFailure`: `could not start <command>: <reason>`.
	Returns whether it started.
]=]
function StreamFeed.Prototype.spawn(self: StreamFeed): boolean
	local command = self.command :: string
	local spawned, result = pcall(stdPolyfills.process.spawn, command, self.arguments)

	if spawned then
		self.process = result
		self.logger:debug(`started {command}`)
	else
		self:fail(tostring(result))
	end

	return spawned
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Opens the stream session and starts the pump. A failed open becomes `pendingFailure` and kills the program, whose
	stdout is still open; a session that opens after `destroy` is closed at once.
]=]
function StreamFeed.Prototype.open(self: StreamFeed)
	local opened, result = pcall(symphonia.decoder.fromStream, { logLevel = self.logLevel })

	if not opened then
		self:fail(tostring(result))
		self:settleProcess()
	elseif self.stopping then
		result:destroy()
		self.logger:debug(`the audio source was destroyed while its stream opened; closed the session`)
	else
		self.decoder = result
		self:startPump()
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Creates the pump's thread and starts it.
]=]
function StreamFeed.Prototype.startPump(self: StreamFeed)
	local pump = coroutine.create(function()
		self:runPump()
	end)

	self.pump = pump
	self:resumePump(pump)
end

--[=[
	@within Audio.StreamFeed
	@private

	Runs the pump until its first wait, logging at warn, and failing the feed, if it fails before then.
]=]
function StreamFeed.Prototype.resumePump(self: StreamFeed, pump: thread)
	local resumed, resumeError = coroutine.resume(pump)

	if not resumed then
		self.logger:warn(`the audio stream's pump failed to start: {resumeError}`)
		self:fail(`the audio stream's pump failed: {resumeError}`)
		self.outputClosed = true
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	The pump's body, under `pcall`: an error it did not expect fails the feed instead of ending the thread unseen, and
	closes the output, so the source plays what is queued and then surfaces the failure rather than waiting for audio
	that can no longer come. Then it settles the program's exit, also under `pcall`.
]=]
function StreamFeed.Prototype.runPump(self: StreamFeed)
	local pumped, pumpFailure = pcall(self.pumpChunks, self)

	if not pumped and self.stopping then
		self.logger:debug(`the audio stream's pump raised after the source was destroyed: {pumpFailure}`)
	elseif not pumped then
		self:fail(`the audio stream's pump failed: {pumpFailure}`)
		self.outputClosed = true
	end

	local settled, settleFailure = pcall(self.settleProcess, self)

	if not settled then
		self.exitKnown = true
		self.outputClosed = true
		self:fail(`the audio stream's program could not be settled: {settleFailure}`)
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Reads chunks and pushes them, until the source is destroyed, the feed fails, the input ends, the session can take
	no more, or the session needs the whole file. A read that raises, or returns something that is not bytes, fails the
	feed and ends the session's input, so the bytes already pushed still decode and play. At the end of the input it
	waits for the session to open or fail, when the stream may need the whole-file fallback, and runs that fallback.
]=]
function StreamFeed.Prototype.pumpChunks(self: StreamFeed)
	local pumping = true

	while pumping and not self.stopping and not self.pendingFailure and not self.fallingBack do
		local read, chunk = self:readChunk()
		local chunkType = typeof(chunk)

		if self.stopping then
			pumping = false
		elseif not read then
			self:fail(`audio stream read failed: {chunk}`)
			self:finishInput()
		elseif chunkType == "nil" then
			self:endInput()
			self:awaitOpenOutcome()
			pumping = false
		elseif chunkType ~= "buffer" and chunkType ~= "string" then
			self:fail(`audio stream read failed: it returned a {chunkType}, not a buffer or string`)
			self:finishInput()
		else
			pumping =
				self:pushChunk(if chunkType == "string" then buffer.fromstring(chunk :: string) else chunk :: buffer)
		end
	end

	if self.fallingBack and not self.stopping and not self.pendingFailure then
		self:runFallback()
	end

	if self.stopping then
		self.logger:debug(`the audio source was destroyed; the pump stopped`)
	elseif self.pendingFailure then
		self.logger:debug(`the audio stream failed; the pump stopped reading`)
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	The one place the pump reads the stream: the program's stdout, joined into chunks, for `fromProcess`, or the
	stream's own `read` for `fromStream`, each under `pcall`. It may yield for as long as the next bytes take. Returns
	whether the read succeeded, then its chunk or its error.
]=]
function StreamFeed.Prototype.readChunk(self: StreamFeed): (boolean, unknown)
	if self.process then
		return pcall(self.joinProcessOutput, self)
	end

	return pcall(self.reader :: StreamReader)
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	The next chunk of the program's stdout, or nil at its end. A stdout read returns at most 1 KiB, so reads are joined
	into chunks of up to 64 KiB, by one rule that never holds bytes back for a slow program: it waits only for the
	first read, then joins only the reads that finish at once, because their bytes are already in the pipe. The first
	read that would wait stays in flight for the next call, so the bytes joined so far go out at once. So does a read
	that ends stdout or raises: the next call returns nil or raises its error, after the joined bytes are pushed.
]=]
function StreamFeed.Prototype.joinProcessOutput(self: StreamFeed): buffer?
	local first = self:takePipeRead()
	local pieces = { first }
	local length = if first then buffer.len(first) else 0

	while first and length + PIPE_READ_BYTES <= MAX_PUSH_BYTES and self:pipeReadReady() and self.pipeData do
		local piece = self.pipeData :: buffer

		self:clearPipeRead()
		table.insert(pieces, piece)
		length += buffer.len(piece)
	end

	return if first then joined(pieces :: { buffer }, length) else nil
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Returns the bytes of the stdout read in flight, starting one when none is, and waits for it when it has not
	finished. Nil at the end of stdout. Raises the read's error when it raised, so the pump fails the feed and closes
	the session's input.
]=]
function StreamFeed.Prototype.takePipeRead(self: StreamFeed): buffer?
	if not self.pipeReading then
		self:startPipeRead()
	end

	if not self.pipeDone then
		self.pipeWaiter = coroutine.running()
		coroutine.yield()
	end

	local data = self.pipeData
	local failure = self.pipeFailure

	self:clearPipeRead()

	if failure then
		error(failure, 0)
	end

	return data
end

--[=[
	@within Audio.StreamFeed
	@private

	Starts a stdout read when none is in flight, and returns whether the one in flight has finished, without waiting.
]=]
function StreamFeed.Prototype.pipeReadReady(self: StreamFeed): boolean
	if not self.pipeReading then
		self:startPipeRead()
	end

	return self.pipeDone
end

--[=[
	@within Audio.StreamFeed
	@private

	Starts one read of the program's stdout in its own thread. The read finishes at once when bytes are already in the
	pipe; otherwise it waits there, and the pump is woken when it finishes.
]=]
function StreamFeed.Prototype.startPipeRead(self: StreamFeed)
	local process = self.process :: Process
	local pipeRead = coroutine.create(function()
		local read, data = pcall(process.read, PIPE_READ_BYTES)

		self:finishPipeRead(if read then data else nil, if read then nil else tostring(data))
	end)

	self.pipeReading = true
	self.pipeDone = false
	self:resumePipeRead(pipeRead)
end

--[=[
	@within Audio.StreamFeed
	@private

	Runs a stdout read until it finishes or waits, logging at warn, and recording the error as the read's, if it fails
	before then.
]=]
function StreamFeed.Prototype.resumePipeRead(self: StreamFeed, pipeRead: thread)
	local resumed, resumeError = coroutine.resume(pipeRead)

	if not resumed then
		self.logger:warn(`a read of the program's stdout failed to start: {resumeError}`)
		self:finishPipeRead(nil, tostring(resumeError))
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Records a finished stdout read, its bytes, nil at the end, or the error of a read that raised, which the pump raises
	when it takes the read, then wakes the pump when it waits for it. The wake is checked and warned. A read that raised
	after the feed killed the program, whose stdout the kill closes, is the end of stdout rather than a failure.
]=]
function StreamFeed.Prototype.finishPipeRead(self: StreamFeed, data: buffer?, failure: string?)
	local waiter = self.pipeWaiter
	local closedByKill = if failure then self.killedByUs else false

	self.pipeDone = true
	self.pipeData = data
	self.pipeFailure = if closedByKill then nil else failure
	self.pipeWaiter = nil

	if closedByKill then
		self.logger:debug(`a stdout read raised after the feed killed {self.command}; stdout ended: {failure}`)
	end

	if waiter then
		local resumed, resumeError = coroutine.resume(waiter)

		if not resumed then
			self.logger:warn(`the audio stream's pump failed after a stdout read woke it: {resumeError}`)
		end
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Forgets the finished stdout read, so the next one can start.
]=]
function StreamFeed.Prototype.clearPipeRead(self: StreamFeed)
	self.pipeReading = false
	self.pipeDone = false
	self.pipeData = nil
	self.pipeFailure = nil
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Pushes a chunk in slices of at most 64 KiB, yielding and filling the queue after each. Until the session opens, it
	first keeps the chunk for the whole-file fallback, and the stream's first 8 bytes always. An empty chunk pushes
	nothing and only yields, so a `read` that keeps returning empty chunks without yielding cannot hold the VM. Returns
	whether the pump should read on.
]=]
function StreamFeed.Prototype.pushChunk(self: StreamFeed, input: buffer): boolean
	local length = buffer.len(input)
	local offset = 0
	local pushing = true

	self.streamBytes += length
	self:noteFirstBytes(input)

	if self.fallbackEnabled and not self:isOpen() then
		self:retain(input)
	end

	if length == 0 then
		stdPolyfills.task.wait()
	end

	while pushing and offset < length do
		local size = math.min(MAX_PUSH_BYTES, length - offset)

		pushing = self:pushSlice(if size == length then input else sliceOf(input, offset, size))
		offset += size

		if pushing then
			stdPolyfills.task.wait()
			self:fill()
		end

		pushing = pushing and not self.stopping and not self.pendingFailure
	end

	return pushing
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Pushes one slice. It reads the session's state before every push and stops reading once the session has failed,
	ended, or sent the stream into the whole-file fallback. While the input is full, it waits 20 ms and pushes again,
	until the source is destroyed or the feed fails. Returns whether the slice went in.
]=]
function StreamFeed.Prototype.pushSlice(self: StreamFeed, piece: buffer): boolean
	local decoder = self.decoder :: symphonia.Decoder

	while not self.stopping and not decoder.destroyed and not self.pendingFailure do
		self:refresh()

		if decoder.failed or decoder.state == ENDED_STATE then
			self.logger:debug(
				`the audio stream session {if decoder.failed then "failed" else "ended"}; the pump stopped pushing`
			)

			return false
		end

		local pushed, accepted = pcall(decoder.push, decoder, piece)

		if not pushed then
			return self:refusedPush(tostring(accepted))
		end

		if accepted then
			return true
		end

		stdPolyfills.task.wait(FULL_INPUT_WAIT_SECONDS)
	end

	self.logger:debug(`the stream's input was full until the source was destroyed or the feed failed; the pump stopped`)

	return false
end

--[=[
	@within Audio.StreamFeed
	@private

	Handles a push the session refused. A session that has ended stops the pump quietly and one that has failed stops it
	as `pushSlice` does; anything else fails the feed with the push's message and ends the session's input. Returns
	false, so the pump stops.
]=]
function StreamFeed.Prototype.refusedPush(self: StreamFeed, message: string): boolean
	local decoder = self.decoder :: symphonia.Decoder

	if self.stopping then
		self.logger:debug(`the audio source was destroyed during a push; the pump stopped`)
	else
		self:refresh()

		if decoder.state == ENDED_STATE then
			self.logger:debug(`the audio stream session ended; the pump stopped reading`)
		elseif decoder.failed then
			self.logger:debug(`the audio stream session failed; the pump stopped reading`)
		else
			self:fail(message)
			self:finishInput()
		end
	end

	return false
end

--[=[
	@within Audio.StreamFeed
	@private

	Ends the session's input after the stream's input ended. A stream that gave no bytes at all fails with its own
	message.
]=]
function StreamFeed.Prototype.endInput(self: StreamFeed)
	print(`[trace {string.format("%.3f", os.clock())}] feed endInput, producerEnded`)
	self.producerEnded = true

	if self.streamBytes == 0 then
		self:fail("could not open audio: the stream ended before any audio")
	end

	self:finishInput()
	self.logger:debug(`the audio stream's input ended after {self.streamBytes} bytes`)
end

--[=[
	@within Audio.StreamFeed
	@private

	Tells the session that no more bytes are coming, so it decodes what it holds and ends.
]=]
function StreamFeed.Prototype.finishInput(self: StreamFeed)
	local decoder = self.decoder :: symphonia.Decoder

	decoder:finish()
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	After the input ended, waits for the session to open or to fail, when the stream may need the whole-file fallback:
	a CAF fails only once it has all its bytes. The wait ends at the session's outcome, which the end of the input makes
	certain, or at `destroy`.
]=]
function StreamFeed.Prototype.awaitOpenOutcome(self: StreamFeed)
	local decoder = self.decoder :: symphonia.Decoder
	local mayFallBack = self:hasMarker() and self.fallbackEnabled

	while mayFallBack and not self.stopping and not decoder.opened and not decoder.failed do
		stdPolyfills.task.wait(OUTCOME_POLL_SECONDS)
		self:refresh()
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	The whole-file fallback: reads the rest of the stream, yielding after every read, then opens the whole file. Ends
	early at `destroy` or a failure.
]=]
function StreamFeed.Prototype.runFallback(self: StreamFeed)
	local session = self.decoder :: symphonia.Decoder

	self:readToEnd()

	if self.stopping or self.pendingFailure then
		self.logger:debug(`the whole-file fallback stopped before the file was complete`)
	else
		session:destroy()
		self:openWhole()
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Reads the stream to its end into the kept bytes, yielding after every read. A read past the cap fails at once with
	the 128 MiB message.
]=]
function StreamFeed.Prototype.readToEnd(self: StreamFeed)
	while not self.producerEnded and not self.stopping and not self.pendingFailure do
		local read, chunk = self:readChunk()
		local chunkType = typeof(chunk)

		if self.stopping then
			self.logger:debug(`the audio source was destroyed while the whole file was read`)
		elseif not read then
			self:fail(`audio stream read failed: {chunk}`)
		elseif chunkType == "nil" then
			self.producerEnded = true
		elseif chunkType ~= "buffer" and chunkType ~= "string" then
			self:fail(`audio stream read failed: it returned a {chunkType}, not a buffer or string`)
		else
			self:keepWhole(if chunkType == "string" then buffer.fromstring(chunk :: string) else chunk :: buffer)
		end

		stdPolyfills.task.wait()
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Keeps a chunk the whole-file fallback read, failing the feed with the 128 MiB message when it passes the cap.
]=]
function StreamFeed.Prototype.keepWhole(self: StreamFeed, input: buffer)
	self.streamBytes += buffer.len(input)

	if not self:retain(input) then
		self:fail(CAP_FAILURE)
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Opens the complete file with `Symphonia.Decoder.fromBuffer` from an exact-size copy of the kept bytes, drops them
	once that returns, and plays the file through the same queue. A file that still cannot be opened fails with
	`could not open audio: <reason>`.
]=]
function StreamFeed.Prototype.openWhole(self: StreamFeed)
	local whole = buffer.create(self.retainedBytes)
	local retained = self.retained

	if retained then
		buffer.copy(whole, 0, retained, 0, self.retainedBytes)
	end

	local opened, result = pcall(symphonia.decoder.fromBuffer, whole, { logLevel = self.logLevel })

	self.retained = nil
	self.retainedBytes = 0
	self.fallingBack = false

	if not opened then
		self:fail(tostring(result))
	elseif self.stopping then
		result:destroy()
		self.logger:debug(`the audio source was destroyed while the whole file opened; closed it`)
	else
		self.decoder = result
		self.logger:debug(`opened the whole file, {buffer.len(whole)} bytes, after the stream could not open`)
		self:fill()
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Keeps the stream's first 8 bytes for the MP4 and CAF marker check.
]=]
function StreamFeed.Prototype.noteFirstBytes(self: StreamFeed, input: buffer)
	local missing = math.min(MARKER_BYTES - #self.firstBytes, buffer.len(input))

	if missing > 0 then
		self.firstBytes ..= buffer.readstring(input, 0, missing)
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Appends a chunk to the kept bytes, doubling the buffer as it grows. Past `maxRetainedBytes` it drops them, turns the
	fallback off and returns false.
]=]
function StreamFeed.Prototype.retain(self: StreamFeed, input: buffer): boolean
	local retained = self.retained
	local length = self.retainedBytes + buffer.len(input)
	local capacity = if retained then buffer.len(retained) else 0
	local grownCapacity = math.min(math.max(capacity * 2, length, MIN_RETAINED_CAPACITY), self.maxRetainedBytes)

	if length > self.maxRetainedBytes then
		self.retained = nil
		self.retainedBytes = 0
		self.fallbackEnabled = false
		self.logger:debug(`the audio stream passed {self.maxRetainedBytes} bytes; the whole-file fallback is off`)

		return false
	end

	if length > capacity or not retained then
		local grown = buffer.create(grownCapacity)

		if retained then
			buffer.copy(grown, 0, retained, 0, self.retainedBytes)
		end

		retained = grown
	end

	buffer.copy(retained :: buffer, self.retainedBytes, input)
	self.retained = retained
	self.retainedBytes = length

	return true
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Settles the program's exit once the pump has stopped, for `fromProcess`: waits for it when its stdout has ended,
	and otherwise kills it, since it is still writing to a stream nobody reads.
]=]
function StreamFeed.Prototype.settleProcess(self: StreamFeed)
	local process = self.process

	if process and not self.exitKnown and self.producerEnded then
		self:awaitExit(process)
	elseif process and not self.exitKnown then
		self:killProcess(process)
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Waits up to 5 seconds after stdout ended for the program to exit. A program that does not is killed, with a warn
	line, and the stream ends as if it had exited cleanly. The wait also ends when `destroy` settles the exit first,
	with its kill or with the code of a program that had already exited; that outcome stands.
]=]
function StreamFeed.Prototype.awaitExit(self: StreamFeed, process: Process)
	local deadline = nowMillis() + EXIT_WAIT_MILLISECONDS

	while not self.exitKnown and not process.exited() and nowMillis() < deadline do
		stdPolyfills.task.wait(EXIT_POLL_SECONDS)
	end

	if self.exitKnown then
		self.logger:debug(`{self.command}'s exit was settled while the feed waited for it`)
	elseif process.exited() then
		self:noteExit(process, process.wait())
	else
		self.logger:warn(
			`{self.command} did not exit within {EXIT_WAIT_MILLISECONDS // 1000} s after its output ended; killed it`
		)
		self:killProcess(process)
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Kills the program and ignores its exit code. A program that had already exited keeps its own code.
]=]
function StreamFeed.Prototype.killProcess(self: StreamFeed, process: Process)
	if not self:stopProgram(process) then
		self:noteExit(process, process.wait())
	end
end

--[=[
	@within Audio.StreamFeed
	@private

	Kills the program unless it has already exited, and returns whether it did. A killed program's exit is settled and
	its code is ignored. Never yields: `process.kill` closes the program's stdout and stderr, so one blocked on writing
	them can exit, and stops it in the background without waiting for the exit.
]=]
function StreamFeed.Prototype.stopProgram(self: StreamFeed, process: Process): boolean
	local killed = process.kill()

	if killed then
		self.killedByUs = true
		self.exitKnown = true
		self.logger:debug(`killed {self.command}; its exit code is ignored`)
	end

	return killed
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	Records the exit code of a program the feed did not kill. A non-zero code wins over every other outcome:
	`<command> exited with code <n>: <last stderr line>`, or `no error output`. The line is read once stderr's reader
	has reached the end of stderr, see `errorReason`, and the code is dropped when `destroy` settled the exit meanwhile.
]=]
function StreamFeed.Prototype.noteExit(self: StreamFeed, process: Process, code: number)
	local reason = if code == 0 then nil else self:errorReason(process)

	if self.exitKnown then
		self.logger:debug(`{self.command}'s exit was settled while its stderr was read; code {code} is dropped`)

		return
	end

	self.exitCode = code
	self.exitKnown = true

	if reason then
		self.pendingFailure = `{self.command} exited with code {code}: {reason}`
		self.failedAtMillis = self.failedAtMillis or nowMillis()
		self.logger:debug(`{self.command} exited with code {code}, which wins over any other outcome`)
	else
		self.logger:debug(`{self.command} exited with code {code}`)
	end
end

--[=[
	@within Audio.StreamFeed
	@private
	@yields

	The last line of the program's stderr, or `no error output`. Stderr's reader takes 1 KiB per scheduler tick and can
	trail the exit, so this first waits up to 250 ms for it to reach the end of stderr (`errorEnded`), and warns when it
	has not, since the line may then be an older one. At `destroy` it does not wait.
]=]
function StreamFeed.Prototype.errorReason(self: StreamFeed, process: Process): string
	local deadline = nowMillis() + STDERR_WAIT_MILLISECONDS

	while not process.errorEnded() and not self.stopping and nowMillis() < deadline do
		stdPolyfills.task.wait(EXIT_POLL_SECONDS)
	end

	if not process.errorEnded() and not self.stopping then
		self.logger:warn(
			`{self.command}'s stderr did not end within {STDERR_WAIT_MILLISECONDS} ms of its exit; its last line may be missing`
		)
	end

	return lastLine(process.errorTail()) or "no error output"
end

--[=[
	@within Audio.StreamFeed
	@private

	Adds `frames` to the frames the queue holds, or takes them away when negative, and updates `bufferedSeconds`.
]=]
function StreamFeed.Prototype.countBuffered(self: StreamFeed, frames: number)
	self.bufferedFrames += frames
	self.bufferedSeconds = self.bufferedFrames / SAMPLE_RATE
end

--[=[
	@within Audio.StreamFeed
	@private

	Records the feed's failure as `pendingFailure`. The first failure wins; a later one is logged at debug. When the
	pump waits on the program's stdout, which is then still open, the program is killed at once, so the failure does
	not wait for the program to write or exit. Never yields.
]=]
function StreamFeed.Prototype.fail(self: StreamFeed, message: string)
	local process = self.process

	if self.pendingFailure then
		self.logger:debug(`the audio stream failed again, which is dropped: {message}`)

		return
	end

	self.pendingFailure = message
	self.failedAtMillis = nowMillis()
	self.logger:debug(`the audio stream failed: {message}`)

	if process and self.pipeWaiter and not self.exitKnown then
		local stopped = self:stopProgram(process)

		if not stopped then
			self.logger:debug(`{self.command} exited while the pump waited on its stdout; the pump settles its exit`)
		end
	end
end

--[=[
	@within Audio.StreamFeed

	Creates the feed for `audio.fromStream`; nothing is read, opened or started until the first `poll`. `sourceLogger` is
	the owning source's logger.
]=]
function StreamFeed.Interface.new(
	reader: StreamReader,
	logLevel: logger.LogLevel?,
	sourceLogger: logger.Logger
): StreamFeed
	return newFeed(reader, nil, {}, logLevel, sourceLogger)
end

--[=[
	@within Audio.StreamFeed

	Creates the feed for `audio.fromProcess`; the program is not started until the first `poll`.
]=]
function StreamFeed.Interface.fromProcess(
	command: string,
	arguments: { string },
	logLevel: logger.LogLevel?,
	sourceLogger: logger.Logger
): StreamFeed
	return newFeed(nil, command, arguments, logLevel, sourceLogger)
end

type Process = typeof(stdPolyfills.process.spawn("", {}))

--[=[
	@type StreamReader () -> (buffer | string)?
	@within Audio.StreamFeed

	Returns the next chunk of a stream's file bytes, of any length, or nil at the end. It may yield.
]=]
export type StreamReader = () -> (buffer | string)?

export type StreamFeed = typeof(StreamFeed.Prototype) & {
	reader: StreamReader?,
	command: string?,
	arguments: { string },
	logLevel: logger.LogLevel?,
	decoder: symphonia.Decoder?,
	process: Process?,
	pump: thread?,
	started: boolean,
	stopping: boolean,
	producerEnded: boolean,
	outputClosed: boolean,
	pendingFailure: string?,
	exitCode: number?,
	failedAtMillis: number?,
	exitKnown: boolean,
	killedByUs: boolean,
	fallbackEnabled: boolean,
	fallingBack: boolean,
	retained: buffer?,
	retainedBytes: number,
	maxRetainedBytes: number,
	firstBytes: string,
	pipeReading: boolean,
	pipeDone: boolean,
	pipeData: buffer?,
	pipeFailure: string?,
	pipeWaiter: thread?,
	queue: { buffer },
	queueOffset: number,
	bufferedFrames: number,
	bufferedSeconds: number,
	streamBytes: number,
	logger: logger.Logger,
}

return StreamFeed.Interface
