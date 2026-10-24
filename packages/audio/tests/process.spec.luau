local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local logger = require("../luau_packages/logger")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local voice = require("../luau_packages/voice")
local websocket = require("../luau_packages/websocket")

local audio = require("../src")

local FIXTURES = "packages/symphonia/tests/fixtures"
local GUILD_ID = "10"
local CHANNEL_ID = "20"
local USER_ID = "1"
local SILENCE = "\248\255\254"
local SAMPLE_RATE = 48000
local WAV_HEADER_BYTES = 44
local WAV_FRAME_BYTES = 4
local TONE_BLOCK_FRAMES = 4800
local TONE_AMPLITUDE = 16384
local HEARTBEAT_MILLISECONDS = 1000
local JOIN_SECONDS = 60
local PLAY_SECONDS = 40
local GATE_SECONDS = 10
local POLL_SECONDS = 0.01
local MAX_READS = 200000
local EXIT_WAIT_SECONDS = 5
local EXIT_SLACK_SECONDS = 0.25
local SPEED_SECONDS = 10
local REAL_TIME_FACTOR = 2
local FLOOD_LINES = 64
local JUNK_LIMIT_BYTES = 64 * 1024 * 1024
local SMALL_JUNK_BYTES = 4096
local OGG_SEGMENT_COUNT_OFFSET = 26
local OGG_HEADER_BYTES = 27
local OGG_CHECKSUM_OFFSET = 22
local OGG_CRC_POLYNOMIAL = 0x04C11DB7
local OGG_FIRST_AUDIO_PAGE = 3
local MISSING_PROGRAM = "discord-luau-no-such-program"
local PRODUCER_LINE = "the producer broke"
local STDOUT_FAILURE = "stdout broke"
local CLOSED_FAILURE = "file closed"
local THROTTLE_WINDOW_SECONDS = 0.3
local THROTTLED_MIN_BYTES = 1024 * 1024
local THROTTLED_BYTES = 512 * 1024
local STOP_SECONDS = 1
local KILL_EXIT_SECONDS = 1
local DECODE_FAILURE = "the decoder broke"
local LAST_STDERR_LINE = "the last stderr line"
local PIPE_PIECE_BYTES = 1024
local RAISE_DELAY_SECONDS = 0.05
local TAIL_LAG_SECONDS = 0.04
local SETTLE_SECONDS = 0.2
local PROMPT_FAILURE_SECONDS = 3
local STDERR_LINES = 256
local FAILED_PREFIX = "audio source failed: "
local NOT_AUDIO_REASON =
	"could not open audio: not a supported audio file: unsupported feature: core (probe): no suitable format reader found"
local CHILD_SCRIPT = [[
local arguments = zune.process.args
local mode = arguments[2]
local JUNK = string.rep("this is not audio at all. ", 2600)

local function writeAll(bytes, pieceBytes)
	for offset = 1, #bytes, pieceBytes do
		zune.io.stdout:write(string.sub(bytes, offset, offset + pieceBytes - 1))
	end
end

local function closeStdout()
	local types = zune.ffi.types
	local library = if zune.platform.os == "macos" then "libSystem.B.dylib" else "libc.so.6"
	local libc = zune.ffi.dlopen(library, { close = { returns = types.i32, args = { types.i32 } } })

	libc.close(1)
end

local function ignoreTerm()
	local types = zune.ffi.types
	local library = if zune.platform.os == "macos" then "libSystem.B.dylib" else "libc.so.6"
	local libc = zune.ffi.dlopen(library, { signal = { returns = types.u64, args = { types.i32, types.u64 } } })

	libc.signal(15, 1)
end

if mode == "exit" then
	zune.process.exit(tonumber(arguments[3]))
elseif mode == "cat" then
	writeAll(zune.fs.readFile(arguments[3]), 65536)

	if arguments[5] then
		zune.io.stderr:write(arguments[5] .. "\n")
	end

	zune.process.exit(tonumber(arguments[4]) or 0)
elseif mode == "junk" then
	zune.io.stdout:write(string.sub(JUNK, 1, tonumber(arguments[3])))
	zune.io.stderr:write(arguments[5] .. "\n")
	zune.process.exit(tonumber(arguments[4]))
elseif mode == "junkforever" then
	local written = 0

	while written < tonumber(arguments[3]) do
		zune.io.stdout:write(JUNK)
		written += #JUNK
		zune.task.wait()
	end
elseif mode == "close" then
	writeAll(zune.fs.readFile(arguments[3]), 65536)
	closeStdout()
	zune.task.wait(30)
elseif mode == "flood" then
	local bytes = zune.fs.readFile(arguments[3])
	local line = string.rep("x", 1023) .. "\n"

	for offset = 1, #bytes, 9600 do
		for _ = 1, tonumber(arguments[4]) do
			zune.io.stderr:write(line)
		end

		zune.io.stdout:write(string.sub(bytes, offset, offset + 9599))
		zune.task.wait(0.025)
	end
elseif mode == "slow" then
	writeAll(string.sub(zune.fs.readFile(arguments[3]), 1, 65536), 65536)
	zune.task.wait(30)
elseif mode == "sleep" then
	zune.task.wait(30)
elseif mode == "stderrexit" then
	local line = string.rep("x", 1023) .. "\n"

	for _ = 1, tonumber(arguments[3]) do
		zune.io.stderr:write(line)
	end

	zune.io.stderr:write(arguments[4] .. "\n")
	zune.process.exit(1)
elseif mode == "stubborn" then
	local wav = zune.fs.readFile(arguments[3])
	local data = string.sub(wav, 45)

	ignoreTerm()
	zune.io.stdout:write(string.sub(wav, 1, 4) .. "\255\255\255\255" .. string.sub(wav, 9, 40) .. "\255\255\255\255")

	while true do
		zune.io.stdout:write(data)
	end
end
]]

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio process sources", function() end)
	end
end

local childFolder: string? = nil
local specLogger = logger.new("AudioProcessSpec")

local function waitUntil(predicate: () -> boolean, seconds: number): boolean
	local deadline = os.clock() + seconds

	while not predicate() do
		if os.clock() >= deadline then
			return false
		end

		stdPolyfills.task.wait(POLL_SECONDS)
	end

	return true
end

local function folder(): string
	local env = stdPolyfills.process.getEnv()
	local path = childFolder or `{env.TMPDIR or env.TEMP or env.TMP or "/tmp"}/discord-luau-audio-process-spec`

	if not childFolder then
		pcall(stdPolyfills.fileSystem.writeDir, path)
		stdPolyfills.fileSystem.writeFile(`{path}/child.luau`, CHILD_SCRIPT)
		childFolder = path
	end

	return path
end

local function writeInput(name: string, bytes: string): string
	local path = `{folder()}/{name}`

	stdPolyfills.fileSystem.writeFile(path, bytes)

	return path
end

local function removeInput(path: string)
	local removed, failure = pcall(stdPolyfills.fileSystem.removeFile, path)

	if not removed then
		specLogger:warn(`could not remove the test input {path}: {failure}`)
	end
end

local function withSpawnWrapper(wrap: (handle: Process) -> Process, work: () -> ())
	local process = stdPolyfills.process
	local originalSpawn = process.spawn
	local ran, failure = pcall(function()
		process.spawn = function(command: string, arguments: { string }): Process
			return wrap(originalSpawn(command, arguments))
		end

		work()
	end)

	process.spawn = originalSpawn

	assert(ran, failure)
end

local function scriptedHandle(real: Process, bytes: string, ending: string): Process
	local offset = 1
	local killed = false

	return {
		read = function(count: number): buffer?
			local piece = string.sub(bytes, offset, offset + math.min(count, PIPE_PIECE_BYTES) - 1)

			offset += #piece

			if #piece > 0 then
				return buffer.fromstring(piece)
			end

			if ending == "raiseLater" then
				stdPolyfills.task.wait(RAISE_DELAY_SECONDS)
			end

			if ending ~= "end" then
				error(STDOUT_FAILURE, 0)
			end

			return
		end,
		wait = real.wait,
		exited = function(): boolean
			return killed or real.exited()
		end,
		kill = function(): boolean
			killed = true

			return real.kill()
		end,
		errorTail = real.errorTail,
		errorEnded = real.errorEnded,
	}
end

local function laggingTailHandle(real: Process): Process
	local exitedAt: number? = nil

	local function caughtUp(): boolean
		local seenAt = exitedAt

		return if seenAt then os.clock() - seenAt >= TAIL_LAG_SECONDS else false
	end

	return {
		read = real.read,
		wait = real.wait,
		exited = function(): boolean
			local exited = real.exited()

			exitedAt = exitedAt or (if exited then os.clock() else nil)

			return exited
		end,
		kill = real.kill,
		errorTail = function(): string
			local tail = real.errorTail()
			local lastLineAt = string.find(tail, LAST_STDERR_LINE, 1, true)

			return if caughtUp() or not lastLineAt then tail else string.sub(tail, 1, lastLineAt - 1)
		end,
		errorEnded = function(): boolean
			return caughtUp() and real.errorEnded()
		end,
	}
end

local function child(...: string): { string }
	return { "run", `{folder()}/child.luau`, ... }
end

local function realZune(): string?
	local env = stdPolyfills.process.getEnv()
	local read, commandLine = pcall(stdPolyfills.fileSystem.readFile, "/proc/self/cmdline")
	local fromProcess = if read then string.match(commandLine, "^([^%z]+)") else nil
	local version = string.match(stdPolyfills.fileSystem.readFile("rokit.toml"), 'zune = "[^"@]*@([^"]+)"')
	local home = env.HOME or env.USERPROFILE
	local fromRokit = if home and version
		then `{home}/.rokit/tool-storage/scythe-technology/zune/{version}/zune`
		else nil
	local candidates = { fromProcess, fromRokit }
	local found: string? = nil

	for _, candidate in candidates :: { string } do
		found = found or (if stdPolyfills.fileSystem.isFile(candidate) then candidate else nil)
	end

	return if stdPolyfills.process.getPlatform() == "windows" then nil else found
end

local function realChildSkipReason(zunePath: string?): string?
	local platform = stdPolyfills.process.getPlatform()
	local requiresFfi = stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI

	assert(
		zunePath or platform ~= "linux" or not requiresFfi,
		"DISCORD_LUAU_REQUIRE_FFI is set but the real zune binary for the close-stdout and SIGTERM cases was not found"
	)

	return if platform == "windows"
		then "the child script cannot close its stdout or ignore SIGTERM on Windows"
		elseif platform == "macos" then "the child's libSystem close and signal calls have not been run on macOS yet"
		elseif not zunePath then "the real zune binary was not found; the Rokit shim holds stdout and catches SIGTERM"
		else nil
end

local function sameHandle(real: Process): Process
	return real
end

local function closedReadHandle(real: Process): Process
	local killed = false

	return {
		read = function(count: number): buffer?
			local data = real.read(count)

			if killed then
				error(CLOSED_FAILURE, 0)
			end

			return data
		end,
		wait = real.wait,
		exited = real.exited,
		kill = function(): boolean
			killed = true

			return real.kill()
		end,
		errorTail = real.errorTail,
		errorEnded = real.errorEnded,
	}
end

local function awaitThrottled(feed: audio.StreamFeed): boolean
	local previousBytes = 0
	local deadline = os.clock() + GATE_SECONDS
	local throttled = false

	while not throttled and os.clock() < deadline do
		stdPolyfills.task.wait(THROTTLE_WINDOW_SECONDS)
		throttled = feed.streamBytes >= THROTTLED_MIN_BYTES and feed.streamBytes - previousBytes < THROTTLED_BYTES
		previousBytes = feed.streamBytes
	end

	return throttled
end

local function sineWav(frames: number): string
	local dataBytes = frames * WAV_FRAME_BYTES
	local wav = buffer.create(WAV_HEADER_BYTES + dataBytes)
	local blockBytes = TONE_BLOCK_FRAMES * WAV_FRAME_BYTES

	buffer.writestring(wav, 0, "RIFF")
	buffer.writeu32(wav, 4, WAV_HEADER_BYTES - 8 + dataBytes)
	buffer.writestring(wav, 8, "WAVE")
	buffer.writestring(wav, 12, "fmt ")
	buffer.writeu32(wav, 16, 16)
	buffer.writeu16(wav, 20, 1)
	buffer.writeu16(wav, 22, 2)
	buffer.writeu32(wav, 24, SAMPLE_RATE)
	buffer.writeu32(wav, 28, SAMPLE_RATE * WAV_FRAME_BYTES)
	buffer.writeu16(wav, 32, WAV_FRAME_BYTES)
	buffer.writeu16(wav, 34, 16)
	buffer.writestring(wav, 36, "data")
	buffer.writeu32(wav, 40, dataBytes)

	for frame = 0, math.min(frames, TONE_BLOCK_FRAMES) - 1 do
		local sample = math.round(math.sin(frame * 440 * 2 * math.pi / SAMPLE_RATE) * TONE_AMPLITUDE)
		local offset = WAV_HEADER_BYTES + frame * WAV_FRAME_BYTES

		buffer.writei16(wav, offset, sample)
		buffer.writei16(wav, offset + 2, sample)
	end

	for blockOffset = blockBytes, dataBytes - 1, blockBytes do
		buffer.copy(
			wav,
			WAV_HEADER_BYTES + blockOffset,
			wav,
			WAV_HEADER_BYTES,
			math.min(blockBytes, dataBytes - blockOffset)
		)
	end

	return buffer.tostring(wav)
end

local function oggCrc(page: buffer, offset: number, length: number): number
	local crc = 0

	for index = offset, offset + length - 1 do
		local value = bit32.lshift(bit32.bxor(bit32.rshift(crc, 24), buffer.readu8(page, index)), 24)

		for _ = 1, 8 do
			value = if bit32.btest(value, 0x80000000)
				then bit32.bxor(bit32.lshift(value, 1), OGG_CRC_POLYNOMIAL)
				else bit32.lshift(value, 1)
		end

		crc = bit32.bxor(bit32.lshift(crc, 8), value)
	end

	return crc
end

local function opusWithInvalidPacket(): string
	local bytes = buffer.fromstring(stdPolyfills.fileSystem.readFile(`{FIXTURES}/tone.opus`))
	local offset = 0

	for _ = 1, OGG_FIRST_AUDIO_PAGE - 1 do
		local segments = buffer.readu8(bytes, offset + OGG_SEGMENT_COUNT_OFFSET)
		local bodyBytes = 0

		for segment = 0, segments - 1 do
			bodyBytes += buffer.readu8(bytes, offset + OGG_HEADER_BYTES + segment)
		end

		offset += OGG_HEADER_BYTES + segments + bodyBytes
	end

	local segments = buffer.readu8(bytes, offset + OGG_SEGMENT_COUNT_OFFSET)
	local body = offset + OGG_HEADER_BYTES + segments
	local pageBytes = OGG_HEADER_BYTES + segments

	for segment = 0, segments - 1 do
		pageBytes += buffer.readu8(bytes, offset + OGG_HEADER_BYTES + segment)
	end

	buffer.writeu8(bytes, body, bit32.bor(buffer.readu8(bytes, body), 3))
	buffer.writeu8(bytes, body + 1, 0)
	buffer.writeu32(bytes, offset + OGG_CHECKSUM_OFFSET, 0)
	buffer.writeu32(bytes, offset + OGG_CHECKSUM_OFFSET, oggCrc(bytes, offset, pageBytes))

	return buffer.tostring(bytes)
end

local function captureLines(source: audio.Source): { string }
	local lines = {}

	source.logger:setLogLevel("Debug")
	source.logger:setSink(function(line: string)
		table.insert(lines, line)
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

local function raises(work: () -> ...any, text: string): boolean
	local succeeded, failure = pcall(work)
	local found = not succeeded and string.find(tostring(failure), text, 1, true)

	return if found then true else false
end

local function feedOf(source: audio.Source): audio.StreamFeed
	return source.feed :: audio.StreamFeed
end

local function pumpDead(source: audio.Source): boolean
	return waitUntil(function()
		local pump = feedOf(source).pump

		return if pump then coroutine.status(pump) == "dead" else false
	end, GATE_SECONDS)
end

local function drain(source: audio.Source): (number, string?)
	local packets = 0

	for _ = 1, MAX_READS do
		local read, packet = pcall(source.read, source)

		if not read then
			return packets, tostring(packet)
		end

		if packet then
			packets += 1
		elseif source.starved then
			source:poll()
			stdPolyfills.task.wait()
		else
			return packets, nil
		end
	end

	error(`the source did not end within {MAX_READS} reads`)
end

local function connectManager(stub: discordStub.DiscordStub, url: string): websocket.Manager
	local manager = websocket.manager.new({
		token = secret.new("stub-token"),
		intents = 0,
		webSocketVersion = 10,
		reconnect = true,
	})

	manager.logger:setLogLevel("Warn")
	manager
		:connectAsync({
			url = url,
			shards = 1,
			session_start_limit = { total = 1000, remaining = 1000, reset_after = 0, max_concurrency = 1 },
		})
		:await()

	assert(
		stub.clock:waitFor(function()
			return manager.ready
		end, JOIN_SECONDS),
		"the gateway never became ready"
	)

	return manager
end

local function teardown(world: World)
	if world.connection then
		world.connection:destroy()
	end

	if world.manager then
		for shardId in world.manager.shards do
			world.manager.shards[shardId]:forceClose()
		end
	end
end

local function recordEvents(world: World, connection: voice.Connection)
	local recorded = connection :: any
	local setSpeakingAsync = connection.setSpeakingAsync
	local sendOpusAsync = connection.sendOpusAsync

	recorded.setSpeakingAsync = function(self: voice.Connection, speakingFlags: number)
		table.insert(world.events, { kind = `speaking {speakingFlags}`, at = os.clock() })

		return setSpeakingAsync(self, speakingFlags)
	end
	recorded.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer)
		table.insert(world.events, {
			kind = if buffer.tostring(audioFrame) == SILENCE then "silence" else "packet",
			at = os.clock(),
		})

		return sendOpusAsync(self, audioFrame)
	end
end

local function onStub(scenario: (world: World, player: audio.Player) -> ())
	local stub = discordStub.new({ clock = "real", polyfills = stdPolyfills })
	local gateway = stub:createWebsocketServer()
	local world: World = { events = {} }

	gateway.heartbeatIntervalMilliseconds = HEARTBEAT_MILLISECONDS
	stub:createVoiceServer({ heartbeatIntervalMilliseconds = HEARTBEAT_MILLISECONDS })

	check.equal(
		stub:runScenario(function()
			world.manager = connectManager(stub, gateway.url)
			world.connection = voice.connection.new({
				shard = (world.manager :: websocket.Manager).shards[1],
				guildId = GUILD_ID,
				channelId = CHANNEL_ID,
				userId = USER_ID,
				logLevel = "Error",
			})

			local connection = world.connection :: voice.Connection

			assert(connection:joinAsync(JOIN_SECONDS):await():isOk(), "the join failed")
			recordEvents(world, connection)
			scenario(world, audio.player.new(connection))
		end, function()
			teardown(world)
		end),
		nil
	)
end

local function play(player: audio.Player, source: audio.Source): Playback
	local playback: Playback = { startedAt = os.clock() }

	stdPolyfills.task.spawn(function()
		playback.result = player:playAsync(source):await()
		playback.endedAt = os.clock()
	end)

	return playback
end

local function finished(playback: Playback): boolean
	return waitUntil(function()
		return if playback.result then true else false
	end, PLAY_SECONDS)
end

local function failureOf(playback: Playback): string
	return if playback.result and playback.result:isErr() then tostring(playback.result:unwrapErr()) else "no error"
end

local function summary(events: { Event }): string
	local runs = {}
	local kind = ""
	local count = 0

	for _, event in events do
		if event.kind ~= kind and count > 0 then
			table.insert(runs, if count == 1 then kind else `{kind} x{count}`)
			count = 0
		end

		kind = event.kind
		count += 1
	end

	if count > 0 then
		table.insert(runs, if count == 1 then kind else `{kind} x{count}`)
	end

	return table.concat(runs, ", ")
end

type Process = typeof(stdPolyfills.process.spawn("", {}))
type Event = { kind: string, at: number }
type World = { manager: websocket.Manager?, connection: voice.Connection?, events: { Event } }
type Playback = { result: any, startedAt: number, endedAt: number? }

return function()
	test.suite("Audio process sources", function()
		test.case("fromProcess checks its program and arguments, and starts nothing at the call", function()
			local source = audio.fromProcess("zune", child("exit", "0"), { bufferSeconds = 0.5 })
			local feed = feedOf(source)

			check.equal(feed.command, "zune")
			check.equal(feed.process, nil)
			check.is_false(feed.started)
			check.is_true(source.starved)
			check.equal(source.bufferSeconds, 0.5)
			check.is_true(raises(function()
				audio.fromProcess(5 :: any)
			end, "audio.fromProcess takes the program to run as a string"))
			check.is_true(raises(function()
				audio.fromProcess("")
			end, "audio.fromProcess takes the program to run as a string"))
			check.is_true(raises(function()
				audio.fromProcess("zune", "run" :: any)
			end, "audio.fromProcess takes the program's arguments as an array of strings"))
			check.is_true(raises(function()
				audio.fromProcess("zune", { 1 } :: any)
			end, "audio.fromProcess takes the program's arguments as an array of strings"))
			check.is_true(raises(function()
				audio.fromProcess("zune", {}, { bufferSeconds = 9 })
			end, "bufferSeconds must be a number from 0.1 to 4"))

			source:destroy()
		end)

		test.case("a missing program fails the playback at once, without Speaking", function()
			onStub(function(world, player)
				local source = audio.fromProcess(MISSING_PROGRAM, {})
				local playback = play(player, source)

				check.is_true(finished(playback))
				check.equal(failureOf(playback), `{FAILED_PREFIX}could not start {MISSING_PROGRAM}: FileNotFound`)
				check.equal(#world.events, 0)
			end)
		end)

		test.case("empty stdout and exit code 1 report the code, without Speaking", function()
			onStub(function(world, player)
				local playback = play(player, audio.fromProcess("zune", child("exit", "1")))

				check.is_true(finished(playback))
				check.equal(failureOf(playback), `{FAILED_PREFIX}zune exited with code 1: no error output`)
				check.equal(#world.events, 0)
			end)
		end)

		test.case("bytes that are not audio, then exit code 1, report the code and the last stderr line", function()
			onStub(function(world, player)
				local source = audio.fromProcess("zune", child("junk", tostring(SMALL_JUNK_BYTES), "1", PRODUCER_LINE))
				local playback = play(player, source)

				check.is_true(finished(playback))
				check.equal(failureOf(playback), `{FAILED_PREFIX}zune exited with code 1: {PRODUCER_LINE}`)
				check.equal(#world.events, 0)
				check.equal(feedOf(source).exitCode, 1)
			end)
		end)

		test.case("a program that exits cleanly without any bytes fails with the 0-byte message", function()
			onStub(function(world, player)
				local playback = play(player, audio.fromProcess("zune", child("exit", "0")))

				check.is_true(finished(playback))
				check.equal(
					failureOf(playback),
					`{FAILED_PREFIX}could not open audio: the stream ended before any audio`
				)
				check.equal(#world.events, 0)
			end)
		end)

		test.case("a program that writes bytes that are not audio forever is killed at once", function()
			onStub(function(world, player)
				local source = audio.fromProcess("zune", child("junkforever", tostring(JUNK_LIMIT_BYTES)))
				local playback = play(player, source)
				local feed = feedOf(source)

				check.is_true(finished(playback))
				check.equal(failureOf(playback), `{FAILED_PREFIX}{NOT_AUDIO_REASON}`)
				check.equal(#world.events, 0)
				check.is_true(feed.killedByUs)
				check.lesser(feed.streamBytes, JUNK_LIMIT_BYTES // 8)
				check.is_true(waitUntil(function()
					local process = feed.process

					return if process then process.exited() else false
				end, GATE_SECONDS))
			end)
		end)

		test.case("a WAV from a program plays to the end, and the clean exit ends the playback", function()
			local path = writeInput("second.wav", sineWav(SAMPLE_RATE))

			onStub(function(world, player)
				local source = audio.fromProcess("zune", child("cat", path, "0"), { bufferSeconds = 0.5 })
				local playback = play(player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), "speaking 1, packet x50, silence x5, speaking 0")
				check.equal(feedOf(source).exitCode, 0)
				check.is_true(pumpDead(source))
			end)

			removeInput(path)
		end)

		test.case("a WAV from a program is read at least twice as fast as it plays", function()
			local path = writeInput("ten.wav", sineWav(SPEED_SECONDS * SAMPLE_RATE))
			local source = audio.fromProcess("zune", child("cat", path, "0"))
			local startedAt = os.clock()
			local packets, failure = drain(source)
			local elapsed = os.clock() - startedAt

			check.equal(failure, nil)
			check.equal(packets, SPEED_SECONDS * 50)
			check.lesser(elapsed, SPEED_SECONDS / REAL_TIME_FACTOR)

			removeInput(path)
		end)

		test.case("a stderr flood does not starve playback", function()
			local path = writeInput("flood.wav", sineWav(2 * SAMPLE_RATE))

			onStub(function(world, player)
				local source =
					audio.fromProcess("zune", child("flood", path, tostring(FLOOD_LINES)), { bufferSeconds = 0.2 })
				local playback = play(player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), "speaking 1, packet x100, silence x5, speaking 0")
			end)

			removeInput(path)
		end)

		local zunePath = realZune()
		local realChildSkip = realChildSkipReason(zunePath)
		local realChildCase = (if realChildSkip then test.skip.case else test.case) :: typeof(test.case)

		if realChildSkip then
			specLogger:warn(`skipping the close-stdout and SIGTERM cases: {realChildSkip}`)
		end

		realChildCase("a program that closes stdout and never exits is killed 5 s later, after one tail", function()
			local path = writeInput("close.wav", sineWav(2 * SAMPLE_RATE))

			onStub(function(world, player)
				local source = audio.fromProcess(zunePath :: string, child("close", path), { bufferSeconds = 0.5 })
				local lines = captureLines(source)
				local playback = play(player, source)

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.lesser_eq(
					(playback.endedAt :: number) - playback.startedAt,
					2 + EXIT_WAIT_SECONDS + EXIT_SLACK_SECONDS
				)
				check.equal(summary(world.events), "speaking 1, packet x100, silence x5, speaking 0")
				check.equal(countLines(lines, "did not exit within 5 s after its output ended; killed it"), 1)
				check.is_true(feedOf(source).killedByUs)
				check.equal(feedOf(source).exitCode, nil)
			end)

			removeInput(path)
		end)

		realChildCase("stop ends a playback at once while its program ignores SIGTERM on a full stdout", function()
			local path = writeInput("stubborn.wav", sineWav(SAMPLE_RATE))

			onStub(function(_world, player)
				local source = audio.fromProcess(zunePath :: string, child("stubborn", path), { bufferSeconds = 0.5 })
				local feed = feedOf(source)
				local playback = play(player, source)

				check.is_true(awaitThrottled(feed))

				local stoppedAt = os.clock()

				player:stop()

				check.is_true(waitUntil(function()
					return if playback.result then true else false
				end, STOP_SECONDS))
				check.equal(if playback.result then playback.result:unwrapOk() else "pending", "stopped")
				check.lesser((playback.endedAt or math.huge) - stoppedAt, STOP_SECONDS)
				check.is_true(feed.killedByUs)
				check.is_true(waitUntil(function()
					local process = feed.process

					return if process then process.exited() else false
				end, KILL_EXIT_SECONDS))
			end)

			removeInput(path)
		end)

		test.case("an invalid Opus packet from a program fails the playback", function()
			local path = writeInput("invalid.opus", opusWithInvalidPacket())

			onStub(function(world, player)
				local playback = play(player, audio.fromProcess("zune", child("cat", path, "0")))

				check.is_true(finished(playback))

				check.equal(
					failureOf(playback),
					`{FAILED_PREFIX}invalid Opus packet from the audio source: invalid Opus packet: code 3 with 0 frames`
				)
				check.equal(#world.events, 0)
			end)

			removeInput(path)
		end)

		test.case("destroy while the program writes kills it, stops the pump and logs no warning", function()
			local path = writeInput("slow.wav", sineWav(2 * SAMPLE_RATE))
			local source = audio.fromProcess("zune", child("slow", path))
			local lines = captureLines(source)
			local feed = feedOf(source)

			check.is_true(waitUntil(function()
				source:poll()

				return feed.streamBytes > 0
			end, GATE_SECONDS))

			source:destroy()

			check.is_true(pumpDead(source))
			check.is_true(feed.killedByUs)
			check.is_true(waitUntil(function()
				local process = feed.process

				return if process then process.exited() else false
			end, GATE_SECONDS))
			check.equal(countLines(lines, "WARN"), 0)

			removeInput(path)
		end)

		test.case("an M4A from a program with its index at the end plays whole", function()
			local m4a = stdPolyfills.fileSystem.readFile(`{FIXTURES}/tone-alac.m4a`)
			local path = writeInput("index-last.m4a", m4a)
			local expected = audio.fromEncoded(m4a)
			local expectedPackets = 0

			for _ = 1, MAX_READS do
				if not expected:read() then
					break
				end

				expectedPackets += 1
			end

			onStub(function(world, player)
				local playback =
					play(player, audio.fromProcess("zune", child("cat", path, "0"), { bufferSeconds = 0.2 }))

				check.is_true(finished(playback))
				check.equal(playback.result:unwrapOk(), "finished")
				check.equal(summary(world.events), `speaking 1, packet x{expectedPackets}, silence x5, speaking 0`)
			end)

			removeInput(path)
		end)

		test.case("a stdout read that raises fails the playback after the queued audio, mid-chunk or first", function()
			local wav = sineWav(SAMPLE_RATE)

			onStub(function(world, player)
				for _, ending in { "raise", "raiseLater" } do
					table.clear(world.events)
					withSpawnWrapper(function(real: Process): Process
						return scriptedHandle(real, wav, ending)
					end, function()
						local source = audio.fromProcess("zune", child("sleep"), { bufferSeconds = 0.2 })
						local lines = captureLines(source)
						local playback = play(player, source)

						check.is_true(finished(playback))
						check.equal(failureOf(playback), `{FAILED_PREFIX}audio stream read failed: {STDOUT_FAILURE}`)
						check.equal(summary(world.events), "speaking 1, packet x50, silence x5, speaking 0")
						check.lesser((playback.endedAt :: number) - playback.startedAt, PROMPT_FAILURE_SECONDS)
						check.equal(countLines(lines, "did not exit within"), 0)
						check.is_true(feedOf(source).killedByUs)
						check.is_true(pumpDead(source))
					end)
				end
			end)
		end)

		test.case("destroy during the exit wait kills the program and leaves its code unrecorded", function()
			local wav = sineWav(SAMPLE_RATE // 2)

			withSpawnWrapper(function(real: Process): Process
				return scriptedHandle(real, wav, "end")
			end, function()
				local source = audio.fromProcess("zune", child("sleep"))
				local lines = captureLines(source)
				local feed = feedOf(source)

				check.is_true(waitUntil(function()
					source:poll()

					return feed.producerEnded
				end, GATE_SECONDS))
				stdPolyfills.task.wait(SETTLE_SECONDS)
				source:destroy()

				check.is_true(pumpDead(source))
				check.is_true(feed.killedByUs)
				check.equal(feed.exitCode, nil)
				check.equal(countLines(lines, "exited with code"), 0)
				check.equal(countLines(lines, "exit was settled while the feed waited for it"), 1)
			end)
		end)

		test.case("a decode failure while a quiet program holds stdout open kills it and surfaces at once", function()
			local path = writeInput("quiet.wav", sineWav(2 * SAMPLE_RATE))

			for _, wrap in { sameHandle, closedReadHandle } do
				withSpawnWrapper(wrap, function()
					local source = audio.fromProcess("zune", child("slow", path))
					local lines = captureLines(source)
					local feed = feedOf(source)
					local failure: string? = nil

					check.is_true(waitUntil(function()
						source:poll()

						return if feed.pipeWaiter then feed.bufferedFrames > 0 else false
					end, GATE_SECONDS))

					local decoder = feed.decoder :: any

					decoder.readFloat = function()
						error(DECODE_FAILURE, 0)
					end

					check.is_true(waitUntil(function()
						local read, packet = pcall(source.read, source)

						failure = if read then nil else tostring(packet)

						if not packet then
							source:poll()
						end

						return not read
					end, PROMPT_FAILURE_SECONDS))
					check.equal(failure, DECODE_FAILURE)
					check.is_true(feed.killedByUs)
					check.equal(feed.exitCode, nil)
					check.is_true(pumpDead(source))
					check.equal(countLines(lines, "did not exit within"), 0)
					check.equal(countLines(lines, "audio stream read failed"), 0)
					check.is_true(waitUntil(function()
						local process = feed.process

						return if process then process.exited() else false
					end, GATE_SECONDS))
				end)
			end

			removeInput(path)
		end)

		test.case("a non-zero exit reports the last line of a long stderr the reader has not caught up with", function()
			onStub(function(world, player)
				withSpawnWrapper(laggingTailHandle, function()
					local source =
						audio.fromProcess("zune", child("stderrexit", tostring(STDERR_LINES), LAST_STDERR_LINE))
					local playback = play(player, source)

					check.is_true(finished(playback))
					check.equal(failureOf(playback), `{FAILED_PREFIX}zune exited with code 1: {LAST_STDERR_LINE}`)
					check.equal(#world.events, 0)
				end)
			end)
		end)

		test.case("a stderr that never ends is waited on for 250 ms, then reported with a warning", function()
			withSpawnWrapper(function(real: Process): Process
				local handle = table.clone(real)

				handle.errorEnded = function(): boolean
					return false
				end

				return handle
			end, function()
				local source = audio.fromProcess("zune", child("stderrexit", "1", LAST_STDERR_LINE))
				local lines = captureLines(source)
				local packets, failure = drain(source)

				check.equal(packets, 0)
				check.equal(failure, `zune exited with code 1: {LAST_STDERR_LINE}`)
				check.equal(countLines(lines, "stderr did not end within 250 ms of its exit"), 1)
			end)
		end)
	end)
end
