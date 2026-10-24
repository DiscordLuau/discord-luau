local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local symphonia = require("../src")
local SymphoniaBuffer = require("../src/buffer")

local FIXTURES = "packages/symphonia/tests/fixtures"
local CHUNK_BYTES = 4096
local SLICE_BYTES = 1500
local OPENING_BYTES = 8000
local MAX_ITERATIONS = 6000
local MAX_WAITS = 1000
local MAX_READS = 400
local MAX_PUSHES = 2000
local WAIT_SECONDS = 0.005
local CYCLES = 30
local FULL_SECONDS = 16
local SAMPLE_RATE = 48000
local PCM_BYTES_PER_FRAME = 4
local WAV_HEADER_BYTES = 44
local WAV_PCM_FORMAT = 1
local BLOCK_FRAMES = 4800
local AMPLITUDE = 16384
local TONE_FRAMES = 24000
local LARGE_CHUNK_BYTES = 65536
local STEADY_POLLS = 10
local ADPCM = stdPolyfills.fileSystem.readFile(`{FIXTURES}/tone-adpcm.wav`)
local ADPCM_BLOCK_START = 61
local ADPCM_BLOCK_BYTES = 1024
local ADPCM_BLOCK_FRAMES = 2041
local ADPCM_BLOCKS = 10003
local DECODE_PREFIX = "could not decode audio: "
local NOT_AUDIO = string.rep("this is not audio at all. ", 160)
local FORMATS = { "tone.wav", "tone.mp3", "tone.flac", "tone.ogg", "tone.aiff", "tone-vorbis.webm" }
local READERS: { { name: string, fixture: string, read: (decoder: symphonia.Decoder) -> buffer? } } = {
	{
		name = "read",
		fixture = "tone.wav",
		read = function(decoder)
			return decoder:read()
		end,
	},
	{
		name = "readFloat",
		fixture = "tone.wav",
		read = function(decoder)
			return decoder:readFloat()
		end,
	},
	{
		name = "readPacket",
		fixture = "tone.opus",
		read = function(decoder)
			return decoder:readPacket()
		end,
	},
}

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Symphonia streams", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function waitFor(description: string, condition: () -> boolean)
	for _ = 1, MAX_WAITS do
		if condition() then
			return
		end

		stdPolyfills.task.wait(WAIT_SECONDS)
	end

	error(`timed out waiting for {description}`)
end

local function joinChunks(chunks: { buffer }): buffer
	local length = 0

	for _, chunk in chunks do
		length += buffer.len(chunk)
	end

	local whole = buffer.create(length)
	local offset = 0

	for _, chunk in chunks do
		buffer.copy(whole, offset, chunk)
		offset += buffer.len(chunk)
	end

	return whole
end

local function sineWav(seconds: number): string
	local frames = seconds * SAMPLE_RATE
	local dataBytes = frames * PCM_BYTES_PER_FRAME
	local wav = buffer.create(WAV_HEADER_BYTES + dataBytes)
	local blockBytes = BLOCK_FRAMES * PCM_BYTES_PER_FRAME

	buffer.writestring(wav, 0, "RIFF")
	buffer.writeu32(wav, 4, WAV_HEADER_BYTES - 8 + dataBytes)
	buffer.writestring(wav, 8, "WAVE")
	buffer.writestring(wav, 12, "fmt ")
	buffer.writeu32(wav, 16, 16)
	buffer.writeu16(wav, 20, WAV_PCM_FORMAT)
	buffer.writeu16(wav, 22, 2)
	buffer.writeu32(wav, 24, SAMPLE_RATE)
	buffer.writeu32(wav, 28, SAMPLE_RATE * PCM_BYTES_PER_FRAME)
	buffer.writeu16(wav, 32, PCM_BYTES_PER_FRAME)
	buffer.writeu16(wav, 34, 16)
	buffer.writestring(wav, 36, "data")
	buffer.writeu32(wav, 40, dataBytes)

	for frame = 0, BLOCK_FRAMES - 1 do
		local sample = math.round(math.sin(frame * 440 * 2 * math.pi / SAMPLE_RATE) * AMPLITUDE)
		local offset = WAV_HEADER_BYTES + frame * PCM_BYTES_PER_FRAME

		buffer.writei16(wav, offset, sample)
		buffer.writei16(wav, offset + 2, -sample)
	end

	for blockOffset = blockBytes, dataBytes - blockBytes, blockBytes do
		buffer.copy(wav, WAV_HEADER_BYTES + blockOffset, wav, WAV_HEADER_BYTES, blockBytes)
	end

	return buffer.tostring(wav)
end

local function readChunks(nextChunk: () -> buffer?): { buffer }
	local chunks = {}
	local chunk = nextChunk()

	while chunk do
		if #chunks >= MAX_READS then
			error(`the decoder did not end within {MAX_READS} reads`)
		end

		table.insert(chunks, chunk)
		chunk = nextChunk()
	end

	return chunks
end

local function decodeWhole(bytes: string): buffer
	local decoder = symphonia.decoder.fromBuffer(bytes)
	local chunks = readChunks(function()
		return decoder:read()
	end)

	decoder:destroy()

	return joinChunks(chunks)
end

local function streamAll(decoder: symphonia.Decoder, bytes: string, read: () -> buffer?): { buffer }
	local chunks = {}
	local offset = 1
	local finished = false

	for _ = 1, MAX_ITERATIONS do
		local progressed = false

		if offset <= #bytes then
			local chunk = string.sub(bytes, offset, offset + CHUNK_BYTES - 1)

			if decoder:push(chunk) then
				offset += #chunk
				progressed = true
			end
		elseif not finished then
			if not decoder.finished then
				decoder:finish()
			end

			finished = true
		end

		local item = read()

		if item then
			table.insert(chunks, item)

			progressed = true
		elseif decoder.ended then
			return chunks
		end

		if not progressed then
			stdPolyfills.task.wait(WAIT_SECONDS)
		end
	end

	error(`the stream did not end within {MAX_ITERATIONS} iterations`)
end

local function openedStream(bytes: string): symphonia.Decoder
	local decoder = symphonia.decoder.fromStream()

	assert(decoder:push(string.sub(bytes, 1, OPENING_BYTES)), "the first push was refused")
	waitFor("the stream to open", function()
		decoder:refresh()

		return decoder.opened
	end)

	return decoder
end

local function waitForFailure(decoder: symphonia.Decoder)
	waitFor("the stream to fail", function()
		decoder:refresh()

		return decoder.failed
	end)
end

local function captureLogs(decoder: symphonia.Decoder): { string }
	local lines = {}

	decoder.logger:setLogLevel("Debug")
	decoder.logger:setSink(function(message: string)
		table.insert(lines, message)
	end)

	return lines
end

local function countLines(lines: { string }, text: string): number
	local count = 0

	for _, line in lines do
		count += if string.find(line, text, 1, true) then 1 else 0
	end

	return count
end

local function workerCount(): number
	return symphonia.load().symphonia_worker_count()
end

local function settledWorkerCount(): number
	local last = workerCount()
	local steadyPolls = 0

	for _ = 1, MAX_WAITS do
		stdPolyfills.task.wait(WAIT_SECONDS)

		local current = workerCount()

		steadyPolls = if current == last then steadyPolls + 1 else 0
		last = current

		if steadyPolls >= STEADY_POLLS then
			return last
		end
	end

	error("the worker count did not settle")
end

local function openCount(): number
	return symphonia.load().symphonia_open_count()
end

local function countNativeMemory(work: () -> ()): (number, number)
	local originalAlloc = SymphoniaBuffer.alloc
	local originalFree = SymphoniaBuffer.free
	local allocations = 0
	local frees = 0
	local succeeded, workError = pcall(function()
		SymphoniaBuffer.alloc = function(size: number)
			allocations += 1

			return originalAlloc(size)
		end
		SymphoniaBuffer.free = function(pointer: FFIPointer)
			frees += 1

			originalFree(pointer)
		end

		work()
	end)

	SymphoniaBuffer.alloc = originalAlloc
	SymphoniaBuffer.free = originalFree

	assert(succeeded, workError)

	return allocations, frees
end

return function()
	test.suite("Symphonia streams", function()
		test.case("pushed, finished and read through to the end, a stream decodes as fromBuffer does", function()
			for _, name in FORMATS do
				local bytes = readFixture(name)
				local decoder = symphonia.decoder.fromStream()
				local streamed = joinChunks(streamAll(decoder, bytes, function()
					return decoder:read()
				end))

				decoder:destroy()

				check.is_true(buffer.len(streamed) > 0)
				check.is_true(buffer.tostring(streamed) == buffer.tostring(decodeWhole(bytes)))
			end
		end)

		test.case("push returns false when the input is full, with nothing queued", function()
			local wav = sineWav(FULL_SECONDS)
			local decoder = symphonia.decoder.fromStream()
			local offset = 1
			local refused = false

			for _ = 1, MAX_PUSHES do
				local chunk = string.sub(wav, offset, offset + CHUNK_BYTES - 1)

				if not decoder:push(chunk) then
					refused = true

					break
				end

				offset += #chunk
			end

			local streamed = joinChunks(streamAll(decoder, string.sub(wav, offset), function()
				return decoder:read()
			end))

			decoder:destroy()

			check.is_true(refused)
			check.is_true(buffer.tostring(streamed) == buffer.tostring(decodeWhole(wav)))
		end)

		test.case("push after finish raises that the stream was finished, whatever state the worker is in", function()
			local decoder = symphonia.decoder.fromStream()

			streamAll(decoder, readFixture("tone.wav"), function()
				return decoder:read()
			end)

			local succeeded, failure = pcall(decoder.push, decoder, "more")

			decoder:destroy()

			check.is_false(succeeded)
			check.equal(tostring(failure), "could not push audio: the stream was finished")
		end)

		test.case("push and finish raise on a decoder that is not a stream", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local pushSucceeded, pushFailure = pcall(decoder.push, decoder, "x")
			local finishSucceeded, finishFailure = pcall(function(): boolean
				decoder:finish()

				return true
			end)

			decoder:destroy()

			check.is_false(pushSucceeded)
			check.equal(tostring(pushFailure), "this decoder is not a stream")
			check.is_false(finishSucceeded)
			check.equal(tostring(finishFailure), "this decoder is not a stream")
		end)

		test.case("a session that fails after it opened is failed, not failedBeforeOpen", function()
			local decoder = symphonia.decoder.fromStream()
			local corruptBlock =
				buffer.fromstring(string.sub(ADPCM, ADPCM_BLOCK_START, ADPCM_BLOCK_START + ADPCM_BLOCK_BYTES - 1))

			buffer.writeu8(corruptBlock, 2, 0xFF)

			local header = buffer.fromstring(string.sub(ADPCM, 1, ADPCM_BLOCK_START - 1))
			local validBlock = string.sub(ADPCM, ADPCM_BLOCK_START, ADPCM_BLOCK_START + ADPCM_BLOCK_BYTES - 1)

			buffer.writeu32(header, 4, ADPCM_BLOCK_START - 8 + ADPCM_BLOCKS * ADPCM_BLOCK_BYTES)
			buffer.writeu32(header, 48, ADPCM_BLOCKS * ADPCM_BLOCK_FRAMES)
			buffer.writeu32(header, 56, ADPCM_BLOCKS * ADPCM_BLOCK_BYTES)

			local bytes = buffer.tostring(header)
				.. validBlock
				.. string.rep(buffer.tostring(corruptBlock), ADPCM_BLOCKS - 2)
				.. validBlock
			local offset = 1

			for _ = 1, MAX_ITERATIONS do
				decoder:refresh()
				decoder:read()

				if decoder.failed or offset > #bytes then
					break
				end

				local pushed = pcall(decoder.push, decoder, string.sub(bytes, offset, offset + LARGE_CHUNK_BYTES - 1))

				if pushed then
					offset += LARGE_CHUNK_BYTES
				else
					stdPolyfills.task.wait(WAIT_SECONDS)
				end
			end

			decoder:finish()
			waitForFailure(decoder)
			decoder:destroy()

			check.is_true(decoder.opened)
			check.is_false(decoder.failedBeforeOpen)
			check.equal(decoder.state, 3)
			check.equal(decoder.failure, "the audio has more than 10000 undecodable packets in a row")
		end)

		test.case("reading a stream the wrong way raises once it has opened", function()
			local opus = openedStream(readFixture("tone.opus"))
			local wav = openedStream(readFixture("tone.wav"))
			local readSucceeded, readFailure = pcall(opus.read, opus)
			local packetSucceeded, packetFailure = pcall(wav.readPacket, wav)

			opus:destroy()
			wav:destroy()

			check.is_false(readSucceeded)
			check.equal(tostring(readFailure), "this audio is Opus; read it with readPacket")
			check.is_false(packetSucceeded)
			check.equal(tostring(packetFailure), "this audio is not Opus; read it with read")
		end)

		test.case("push after a failure raises the session's failure", function()
			local decoder = symphonia.decoder.fromStream()

			decoder:push(NOT_AUDIO)
			decoder:finish()
			waitForFailure(decoder)

			local succeeded, failure = pcall(decoder.push, decoder, "more")
			local reason = decoder.failure :: string

			decoder:destroy()

			check.is_false(succeeded)
			check.is_true(#reason > 0)
			check.equal(tostring(failure), `could not push audio: {reason}`)
		end)

		test.case("push and finish raise after destroy, and a second finish only logs", function()
			local decoder = symphonia.decoder.fromStream()
			local lines = captureLogs(decoder)

			decoder:finish()
			decoder:finish()

			local linesAfterFinishes = countLines(lines, "finished again")

			decoder:destroy()

			local pushSucceeded, pushFailure = pcall(decoder.push, decoder, "x")
			local finishSucceeded, finishFailure = pcall(function(): boolean
				decoder:finish()

				return true
			end)

			check.equal(linesAfterFinishes, 1)
			check.is_false(pushSucceeded)
			check.equal(tostring(pushFailure), "decoder has been destroyed")
			check.is_false(finishSucceeded)
			check.equal(tostring(finishFailure), "decoder has been destroyed")
		end)

		for _, readerCase in READERS do
			test.case(`{readerCase.name} is dry, never ended, until bytes arrive, and ended at the end`, function()
				local bytes = readFixture(readerCase.fixture)
				local decoder = symphonia.decoder.fromStream()
				local first = readerCase.read(decoder)
				local dryAtStart = decoder.dry
				local endedAtStart = decoder.ended

				for _ = 1, MAX_PUSHES do
					if decoder:push(bytes) then
						break
					end
				end

				decoder:finish()

				local sawData = false

				waitFor("a successful read", function()
					sawData = if readerCase.read(decoder) then true else false

					return sawData
				end)

				local dryAfterData = decoder.dry
				local chunks = streamAll(decoder, "", function()
					return readerCase.read(decoder)
				end)

				decoder:destroy()

				check.is_true(not first)
				check.is_true(dryAtStart)
				check.is_false(endedAtStart)
				check.is_true(sawData)
				check.is_false(dryAfterData)
				check.is_true(#chunks > 0)
				check.is_true(decoder.ended)
				check.is_false(decoder.dry)
			end)
		end

		test.case("a stream that has received no audio yet is not opened and reads dry", function()
			local decoder = symphonia.decoder.fromStream()
			local opened = decoder.opened
			local state = decoder.state
			local sampleRate = decoder.sampleRate
			local codec = decoder.codec
			local duration = decoder.durationSeconds
			local pcm = decoder:read()

			decoder:push(string.sub(readFixture("tone.wav"), 1, 10))
			decoder:refresh()

			local openedAfterHeaderStart = decoder.opened
			local dryAfterPartialHeader = not decoder:read() and decoder.dry and not decoder.ended

			decoder:destroy()

			check.is_false(opened)
			check.equal(state, 0)
			check.equal(sampleRate, -1)
			check.equal(codec, "")
			check.is_true(not duration)
			check.is_true(not pcm)
			check.is_false(openedAfterHeaderStart)
			check.is_true(dryAfterPartialHeader)
		end)

		test.case("refresh fills the shape fields on the first open and logs it once", function()
			local bytes = readFixture("tone.mp3")
			local reference = symphonia.decoder.fromBuffer(bytes)
			local decoder = symphonia.decoder.fromStream()
			local lines = captureLogs(decoder)

			decoder:push(bytes)
			waitFor("the stream to open", function()
				decoder:refresh()

				return decoder.opened
			end)
			decoder:refresh()

			check.equal(decoder.codec, reference.codec)
			check.equal(decoder.container, reference.container)
			check.equal(decoder.sampleRate, reference.sampleRate)
			check.equal(decoder.channels, reference.channels)
			check.equal(decoder.isOpus, reference.isOpus)
			check.equal(decoder.durationSeconds, reference.durationSeconds)
			check.is_true(decoder.state == 1 or decoder.state == 2)
			check.is_false(decoder.failed)
			check.is_false(decoder.failedBeforeOpen)
			check.equal(countLines(lines, "audio in a"), 1)

			reference:destroy()
			decoder:destroy()
		end)

		test.case("opening an Opus stream reports isOpus", function()
			local decoder = openedStream(readFixture("tone.opus"))
			local isOpus = decoder.isOpus

			decoder:destroy()

			check.is_true(isOpus)
		end)

		test.case("bytes that are not audio fail the session before it opens", function()
			local decoder = symphonia.decoder.fromStream()

			decoder:push(NOT_AUDIO)
			decoder:finish()
			waitForFailure(decoder)

			local succeeded, failure = pcall(decoder.read, decoder)

			decoder:destroy()

			check.is_true(decoder.failed)
			check.is_true(decoder.failedBeforeOpen)
			check.is_false(decoder.opened)
			check.equal(decoder.state, 3)
			check.equal(
				decoder.failure,
				"not a supported audio file: unsupported feature: core (probe): no suitable format reader found"
			)
			check.is_false(succeeded)
			check.equal(string.sub(tostring(failure), 1, #DECODE_PREFIX), DECODE_PREFIX)
		end)

		test.case("refresh after destroy logs at debug and changes nothing", function()
			local decoder = openedStream(readFixture("tone.wav"))
			local lines = captureLogs(decoder)
			local stateBefore = decoder.state

			decoder:destroy()
			decoder:refresh()

			check.equal(countLines(lines, "refreshed after it was destroyed"), 1)
			check.equal(decoder.state, stateBefore)
		end)

		test.case("read across real dry reads keeps the limiter running to the true end", function()
			local bytes = readFixture("tone.wav")
			local decoder = openedStream(bytes)
			local limiter = decoder.limiter :: symphonia.Limiter
			local chunks = {}
			local offset = OPENING_BYTES + 1
			local finished = false
			local ended = false
			local pcm = decoder:read()

			for _ = 1, MAX_READS do
				if not pcm then
					break
				end

				table.insert(chunks, pcm)

				pcm = decoder:read()
			end

			local dryAfterOpen = not pcm and decoder.dry and decoder.opened and not decoder.ended
			local flushedAfterDry = limiter.flushed

			for _ = 1, MAX_ITERATIONS do
				if offset <= #bytes then
					if decoder:push(string.sub(bytes, offset, offset + SLICE_BYTES - 1)) then
						offset += SLICE_BYTES
					end
				elseif not finished then
					decoder:finish()
					finished = true
				end

				pcm = decoder:read()

				if pcm then
					table.insert(chunks, pcm)
				elseif decoder.ended then
					ended = true

					break
				else
					check.is_false(limiter.flushed)
					stdPolyfills.task.wait(WAIT_SECONDS)
				end
			end

			decoder:destroy()

			check.is_true(dryAfterOpen)
			check.is_false(flushedAfterDry)
			check.is_true(ended)
			check.equal(buffer.len(joinChunks(chunks)) // PCM_BYTES_PER_FRAME, TONE_FRAMES)
			check.is_true(buffer.tostring(joinChunks(chunks)) == buffer.tostring(decodeWhole(bytes)))
		end)

		test.case("an Opus stream passes its packets through as fromBuffer does", function()
			local bytes = readFixture("tone.opus")
			local reference = symphonia.decoder.fromBuffer(bytes)
			local expected = readChunks(function()
				return reference:readPacket()
			end)
			local decoder = symphonia.decoder.fromStream()
			local packets = streamAll(decoder, bytes, function()
				return decoder:readPacket()
			end)

			reference:destroy()
			decoder:destroy()

			check.equal(#packets, #expected)

			for index, packet in expected do
				check.is_true(buffer.tostring(packets[index] or buffer.create(0)) == buffer.tostring(packet))
			end
		end)

		test.case(`{CYCLES} streams destroyed mid-stream return every count to its start`, function()
			local wav = sineWav(FULL_SECONDS)
			local workersBefore = settledWorkerCount()
			local opensBefore = openCount()
			local allocations, frees = countNativeMemory(function()
				for cycle = 1, CYCLES do
					local decoder = symphonia.decoder.fromStream()
					local kind = cycle % 3

					if kind == 1 then
						decoder:push(string.sub(wav, 1, OPENING_BYTES))
						decoder:read()
					elseif kind == 2 then
						for index = 0, MAX_PUSHES do
							if
								not decoder:push(string.sub(wav, index * CHUNK_BYTES + 1, (index + 1) * CHUNK_BYTES))
							then
								break
							end
						end
					end

					decoder:destroy()
				end
			end)

			waitFor("the workers to return to their baseline", function()
				return workerCount() <= workersBefore
			end)

			check.greater(allocations, 0)
			check.equal(frees, allocations)
			check.equal(openCount(), opensBefore)
			check.is_true(workerCount() <= workersBefore)
		end)
	end)
end
