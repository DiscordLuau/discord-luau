local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local symphonia = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local MAX_READS = 200
local WAV_HEADER_BYTES = 44
local WAV_DATA_BYTES = 4000
local WAV_PCM_FORMAT = 1
local WAV_CHANNELS = 2
local WAV_BYTES_PER_FRAME = 4
local WAV_BITS_PER_SAMPLE = 16
local QUICK_OPEN_SECONDS = 1
local TRUNCATED_MP3_BYTES = 2048
local CORRUPTION_BYTES = 64
local LOAD_TIMEOUT_SECONDS = 30
local UNKNOWN_CHUNK_SIZE = 0xFFFFFFFF
local ENDED_EARLY_WARNING = "the audio ended early, short of the length the file states; it may be truncated or damaged"

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Symphonia failures", function() end)
		test.skip.suite("Symphonia loading", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function readFrames(decoder: symphonia.Decoder): number
	local byteCount = 0
	local readCount = 1
	local chunk = decoder:read()

	while chunk do
		if readCount >= MAX_READS then
			error(`the decoder did not end within {MAX_READS} reads`)
		end

		byteCount += buffer.len(chunk)
		chunk = decoder:read()
		readCount += 1
	end

	return byteCount // WAV_BYTES_PER_FRAME
end

local function raisedMessage(work: () -> ...any): string?
	local succeeded, failure = pcall(work)

	return if succeeded then nil else tostring(failure)
end

local function wavWithRate(sampleRate: number): buffer
	local wav = buffer.create(WAV_HEADER_BYTES + WAV_DATA_BYTES)

	buffer.writestring(wav, 0, "RIFF")
	buffer.writeu32(wav, 4, WAV_HEADER_BYTES - 8 + WAV_DATA_BYTES)
	buffer.writestring(wav, 8, "WAVE")
	buffer.writestring(wav, 12, "fmt ")
	buffer.writeu32(wav, 16, 16)
	buffer.writeu16(wav, 20, WAV_PCM_FORMAT)
	buffer.writeu16(wav, 22, WAV_CHANNELS)
	buffer.writeu32(wav, 24, sampleRate)
	buffer.writeu32(wav, 28, (sampleRate * WAV_BYTES_PER_FRAME) % 2 ^ 32)
	buffer.writeu16(wav, 32, WAV_BYTES_PER_FRAME)
	buffer.writeu16(wav, 34, WAV_BITS_PER_SAMPLE)
	buffer.writestring(wav, 36, "data")
	buffer.writeu32(wav, 40, WAV_DATA_BYTES)

	return wav
end

local function corrupted(bytes: string, fractions: { number }): buffer
	local damaged = buffer.fromstring(bytes)

	for _, fraction in fractions do
		local start = math.floor(buffer.len(damaged) * fraction)

		for offset = start, start + CORRUPTION_BYTES - 1 do
			buffer.writeu8(damaged, offset, (offset * 37) % 256)
		end
	end

	return damaged
end

local function streamingWav(bytes: string): buffer
	local wav = buffer.fromstring(bytes)
	local dataChunk = string.find(bytes, "data", 13, true) :: number

	buffer.writeu32(wav, 4, UNKNOWN_CHUNK_SIZE)
	buffer.writeu32(wav, dataChunk + 3, UNKNOWN_CHUNK_SIZE)

	return wav
end

local function captureLogs(decoder: symphonia.Decoder): { string }
	local lines = {}

	decoder.logger:setLogLevel("Debug")
	decoder.logger:setSink(function(message: string)
		table.insert(lines, message)
	end)

	return lines
end

local function countLines(lines: { string }, level: string, text: string): number
	local count = 0

	for _, line in lines do
		if string.find(line, `[{level}]`, 1, true) and string.find(line, text, 1, true) then
			count += 1
		end
	end

	return count
end

local function checkRateRefused(sampleRate: number)
	local startedAt = os.clock()
	local message = raisedMessage(function()
		symphonia.decoder.fromBuffer(wavWithRate(sampleRate))
	end)

	check.equal(message, `could not open audio: the sample rate of {sampleRate} Hz is outside 1000 to 384000 Hz`)
	check.lesser(os.clock() - startedAt, QUICK_OPEN_SECONDS)
end

local function swapLoader(openLibrary: () -> symphonia.Lib, work: () -> ())
	local sys = symphonia.sys
	local loaded = sys.load()
	local originalOpenLibrary = sys.openLibrary
	local loaderThreads: { thread } = {}
	local succeeded, failure = pcall(function()
		sys.library = nil
		sys.openLibrary = function()
			table.insert(loaderThreads, coroutine.running())

			return openLibrary()
		end

		work()
	end)

	for _, loaderThread in loaderThreads do
		if coroutine.status(loaderThread) == "suspended" then
			stdPolyfills.task.cancel(loaderThread)
		end
	end

	sys.openLibrary = originalOpenLibrary
	sys.library = loaded
	sys.loading = false
	sys.waitingThreads = {}

	assert(succeeded, failure)
end

local function startThread(work: () -> ()): thread
	local thread = coroutine.create(work)
	local resumed, resumeError = coroutine.resume(thread)

	assert(resumed, resumeError)

	return thread
end

local function runDeferredThreads()
	stdPolyfills.task.wait()
end

local function resumeIfSuspended(thread: thread?)
	if thread and coroutine.status(thread) == "suspended" then
		local resumed, resumeError = coroutine.resume(thread)

		assert(resumed, resumeError)
	end
end

local function loadInThread(): LoadAttempt
	local attempt: LoadAttempt = { finished = false }
	local deadline = os.clock() + LOAD_TIMEOUT_SECONDS

	startThread(function()
		local succeeded, result = pcall(symphonia.load)

		attempt.library = if succeeded then result else nil
		attempt.message = if succeeded then nil else tostring(result)
		attempt.finished = true
	end)

	while not attempt.finished and os.clock() < deadline do
		runDeferredThreads()
	end

	return attempt
end

local function captureSysLogs(work: () -> ()): { string }
	local sysLogger = symphonia.sys.logger
	local originalSink = sysLogger.sink
	local originalLevel = sysLogger.logLevel
	local lines = {}
	local succeeded, failure = pcall(function()
		sysLogger:setLogLevel("Debug")
		sysLogger:setSink(function(message: string)
			table.insert(lines, message)
		end)

		work()
	end)

	sysLogger:setSink(originalSink)
	sysLogger.logLevel = originalLevel

	assert(succeeded, failure)

	return lines
end

type LoadAttempt = {
	finished: boolean,
	library: symphonia.Lib?,
	message: string?,
}

return function()
	test.suite("Symphonia failures", function()
		test.case("loads libsymphonia with ABI version 3", function()
			check.equal(symphonia.load().symphonia_abi_version(), 3)
		end)

		test.case("garbage fails to open", function()
			local message = raisedMessage(function()
				symphonia.decoder.fromBuffer(string.rep("not audio ", 100))
			end)

			check.not_nil(message)
			check.equal(string.find(message :: string, "could not open audio: ", 1, true), 1)
		end)

		test.case("an empty buffer fails to open", function()
			local message = raisedMessage(function()
				symphonia.decoder.fromBuffer(buffer.create(0))
			end)

			check.equal(message, "could not open audio: the audio is empty")
		end)

		test.case("a missing file fails to open", function()
			local message = raisedMessage(function()
				symphonia.decoder.fromFile(`{FIXTURES}/missing.mp3`)
			end)

			check.not_nil(message)
			check.equal(string.find(message :: string, "could not open audio: ", 1, true), 1)
			check.not_nil((string.find(message :: string, "missing.mp3", 1, true)))
		end)

		test.case("a WAV claiming 2147483647 Hz is refused quickly at open", function()
			checkRateRefused(2147483647)
		end)

		test.case("a WAV claiming 1 Hz is refused quickly at open", function()
			checkRateRefused(1)
		end)

		test.case("a truncated MP3 decodes to its end cleanly, and ends early against its Xing length", function()
			local decoder = symphonia.decoder.fromBuffer(string.sub(readFixture("tone.mp3"), 1, TRUNCATED_MP3_BYTES))
			local lines = captureLogs(decoder)
			local frames = readFrames(decoder)

			check.greater(frames, 0)
			check.lesser(frames, 24000)
			check.equal(decoder.durationSeconds, 0.5)
			check.is_true(decoder.ended)
			check.is_true(decoder.endedEarly)
			check.equal(countLines(lines, "WARN", ENDED_EARLY_WARNING), 1)

			decoder:destroy()
		end)

		test.case("a WAV cut short reads the audio it holds, then ends early with one warning", function()
			local bytes = readFixture("tone.wav")
			local decoder = symphonia.decoder.fromBuffer(string.sub(bytes, 1, #bytes * 6 // 10))
			local lines = captureLogs(decoder)
			local frames = readFrames(decoder)

			check.greater(frames, 0)
			check.lesser(frames, 24000)
			check.is_true(decoder.ended)
			check.is_true(decoder.endedEarly)
			check.equal(decoder:read(), nil)
			check.equal(countLines(lines, "WARN", ENDED_EARLY_WARNING), 1)

			decoder:destroy()
		end)

		test.case("a FLAC cut short ends early with one warning", function()
			local bytes = readFixture("tone.flac")
			local decoder = symphonia.decoder.fromBuffer(string.sub(bytes, 1, #bytes * 6 // 10))
			local lines = captureLogs(decoder)
			local frames = readFrames(decoder)

			check.lesser(frames, 24000)
			check.is_true(decoder.ended)
			check.is_true(decoder.endedEarly)
			check.equal(countLines(lines, "WARN", ENDED_EARLY_WARNING), 1)

			decoder:destroy()
		end)

		test.case("a WAV that states no length plays to its end without ending early", function()
			local decoder = symphonia.decoder.fromBuffer(streamingWav(readFixture("tone.wav")))
			local lines = captureLogs(decoder)
			local frames = readFrames(decoder)

			check.equal(frames, 24000)
			check.is_true(decoder.ended)
			check.is_false(decoder.endedEarly)
			check.equal(countLines(lines, "WARN", "ended early"), 0)

			decoder:destroy()
		end)

		test.case("a whole file does not end early", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local lines = captureLogs(decoder)

			readFrames(decoder)

			check.is_true(decoder.ended)
			check.is_false(decoder.endedEarly)
			check.equal(countLines(lines, "WARN", "ended early"), 0)

			decoder:destroy()
		end)

		test.case("read after the end returns nil again", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.caf"))

			readFrames(decoder)

			check.equal(decoder:read(), nil)
			check.equal(decoder:read(), nil)

			decoder:destroy()
		end)

		test.case("read and readPacket raise after destroy, and a second destroy logs at debug", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.wav"))
			local lines = captureLogs(decoder)

			decoder:destroy()

			check.is_true(decoder.destroyed)
			check.is_true(decoder.ended)
			check.equal(
				raisedMessage(function()
					decoder:read()
				end),
				"decoder has been destroyed"
			)
			check.equal(
				raisedMessage(function()
					decoder:readPacket()
				end),
				"decoder has been destroyed"
			)
			check.equal(countLines(lines, "DEBUG", "already destroyed"), 0)

			decoder:destroy()

			check.equal(countLines(lines, "DEBUG", "already destroyed"), 1)
		end)

		test.case("the first skipped packet is warned and later skips are logged at debug", function()
			local decoder = symphonia.decoder.fromBuffer(corrupted(readFixture("tone.aac"), { 0.3, 0.7 }))
			local lines = captureLogs(decoder)

			readFrames(decoder)

			check.equal(decoder.skippedPackets, 2)
			check.equal(countLines(lines, "WARN", "skipped an undecodable packet; later skips are logged at debug"), 1)
			check.equal(countLines(lines, "WARN", "skipped"), 1)
			check.equal(countLines(lines, "DEBUG", "skipped 1 more undecodable packet"), 1)

			decoder:destroy()
		end)
	end)

	test.suite("Symphonia loading", function()
		test.case("loads libsymphonia with ABI version 3", function()
			check.equal(symphonia.load().symphonia_abi_version(), 3)
			check.equal(symphonia.load(), symphonia.sys.load())
		end)

		test.case("a failed load is not cached, so the next call retries", function()
			local loaded = symphonia.load()
			local attempts = 0
			local first: LoadAttempt?
			local second: LoadAttempt?

			swapLoader(function()
				attempts += 1

				if attempts == 1 then
					error("simulated download failure", 0)
				end

				return loaded
			end, function()
				first = loadInThread()
				second = loadInThread()
			end)

			check.is_true((first :: LoadAttempt).finished)
			check.equal((first :: LoadAttempt).message, "simulated download failure")
			check.is_true((second :: LoadAttempt).finished)
			check.equal((second :: LoadAttempt).library, loaded)
			check.equal(attempts, 2)
		end)

		test.case("callers during a load wait for it and share its one result", function()
			local loaded = symphonia.load()
			local attempts = 0
			local loaderThread: thread?
			local results: { symphonia.Lib } = {}

			swapLoader(function()
				attempts += 1
				loaderThread = coroutine.running()
				coroutine.yield()

				return loaded
			end, function()
				for index = 1, 3 do
					startThread(function()
						results[index] = symphonia.load()
					end)
				end

				runDeferredThreads()

				check.equal(attempts, 1)
				check.equal(results[1], nil)
				check.equal(#symphonia.sys.waitingThreads, 3)

				resumeIfSuspended(loaderThread)
			end)

			check.equal(attempts, 1)
			check.equal(results[1], loaded)
			check.equal(results[2], loaded)
			check.equal(results[3], loaded)
		end)

		test.case("a caller cancelled while a load is in flight does not strand the others", function()
			local loaded = symphonia.load()
			local loaderThread: thread?
			local results: { symphonia.Lib } = {}
			local stillLoading: boolean?
			local lines = captureSysLogs(function()
				swapLoader(function()
					loaderThread = coroutine.running()
					coroutine.yield()

					return loaded
				end, function()
					local firstCaller = startThread(function()
						results[1] = symphonia.load()
					end)

					for index = 2, 3 do
						startThread(function()
							results[index] = symphonia.load()
						end)
					end

					runDeferredThreads()
					stdPolyfills.task.cancel(firstCaller)
					resumeIfSuspended(loaderThread)

					stillLoading = symphonia.sys.loading
				end)
			end)

			check.equal(stillLoading, false)
			check.equal(results[1], nil)
			check.equal(results[2], loaded)
			check.equal(results[3], loaded)
			check.equal(countLines(lines, "WARN", ""), 0)
			check.equal(countLines(lines, "DEBUG", "skipped a thread waiting for libsymphonia"), 1)
		end)

		test.case("callers during a failed load all raise its error, and the next call retries", function()
			local loaded = symphonia.load()
			local attempts = 0
			local loaderThread: thread?
			local messages: { string } = {}
			local waitingAfterFailure: number?
			local retried: LoadAttempt?

			swapLoader(function()
				attempts += 1

				if attempts == 1 then
					loaderThread = coroutine.running()
					coroutine.yield()
					error("simulated download failure", 0)
				end

				return loaded
			end, function()
				for index = 1, 3 do
					startThread(function()
						messages[index] = raisedMessage(function()
							symphonia.load()
						end) or "no error"
					end)
				end

				runDeferredThreads()
				resumeIfSuspended(loaderThread)

				waitingAfterFailure = #symphonia.sys.waitingThreads
				retried = loadInThread()
			end)

			check.equal(messages[1], "simulated download failure")
			check.equal(messages[2], "simulated download failure")
			check.equal(messages[3], "simulated download failure")
			check.equal(waitingAfterFailure, 0)
			check.is_true((retried :: LoadAttempt).finished)
			check.equal((retried :: LoadAttempt).library, loaded)
			check.equal(attempts, 2)
		end)

		test.case("a library with another ABI version is refused", function()
			local ffi = stdPolyfills.ffi :: any
			local originalDlopen = ffi.dlopen
			local attempt: LoadAttempt?

			swapLoader(symphonia.sys.openLibrary, function()
				local succeeded, failure = pcall(function()
					ffi.dlopen = function()
						return {
							symphonia_abi_version = function()
								return 1
							end,
						}
					end
					attempt = loadInThread()
				end)

				ffi.dlopen = originalDlopen

				assert(succeeded, failure)
			end)

			check.is_true((attempt :: LoadAttempt).finished)
			check.equal(
				(attempt :: LoadAttempt).message,
				"libsymphonia ABI version 1 does not match 3; update the symphonia package"
			)
		end)
	end)
end
