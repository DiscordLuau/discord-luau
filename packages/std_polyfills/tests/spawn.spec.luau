local frktest = require("../../../luau_packages/frktest")

local stdPolyfills = require("../src")

local READ_COUNT = 65536
local MAX_READS = 20000
local MAX_TAIL_BYTES = 4096
local FLOOD_BYTES = 3 * 1024 * 1024
local TICK_SECONDS = 0.02
local MAX_TICK_GAP_SECONDS = 0.1
local WATCHDOG_SECONDS = 20
local POLL_SECONDS = 0.01
local MAX_POLLS = 200
local FAKE_STDERR_READS = 50
local DRIP_LINES = 5
local BLOCK_SECONDS = 0.3
local KILL_EXIT_SECONDS = 1
local STUBBORN_SLEEP_SECONDS = 1
local SLEEP_EXIT_SECONDS = 3
local SCRIPT = [[
local mode = zune.process.args[2]
local amount = tonumber(zune.process.args[3])

local function ignoreTerm()
	local types = zune.ffi.types
	local library = if zune.platform.os == "macos" then "libSystem.B.dylib" else "libc.so.6"
	local libc = zune.ffi.dlopen(library, { signal = { returns = types.u64, args = { types.i32, types.u64 } } })

	libc.signal(15, 1)
end

if mode == "bytes" then
	for index = 1, 3 do
		zune.io.stdout:write(string.rep(string.char(64 + index), 10))
		zune.task.wait(0.05)
	end
elseif mode == "exit" then
	zune.process.exit(amount)
elseif mode == "flood" then
	local line = string.rep("x", 1023) .. "\n"
	local count = amount // #line
	for index = 1, count do
		zune.io.stderr:write(line)
	end
	zune.io.stderr:write("last-line-marker\n")
	zune.io.stdout:write("flooded")
elseif mode == "hang" then
	zune.io.stdout:write("a")
	zune.task.wait(60)
elseif mode == "drip" then
	for index = 1, amount do
		zune.io.stderr:write(`line {index}\n`)
		zune.task.wait(0.05)
	end
	zune.io.stderr:write("last-line-marker\n")
elseif mode == "stubborn" then
	local block = string.rep("x", 65536)

	ignoreTerm()

	while true do
		zune.io.stdout:write(block)
	end
elseif mode == "stubbornsleep" then
	ignoreTerm()
	zune.task.wait(amount)
end
]]

local test = frktest.test
local check = frktest.assert.check
local task = stdPolyfills.task

if stdPolyfills.runtime.getRuntime() ~= "Zune" then
	return function()
		test.skip.suite("process.spawn", function() end)
	end
end

local scriptPath: string?

local function getScriptPath(): string
	if scriptPath then
		return scriptPath
	end

	local folder = `{stdPolyfills.process.getEnv().TMPDIR or "/tmp"}/discord-luau-spawn-spec`
	stdPolyfills.fileSystem.writeDir(folder)
	local path = `{folder}/child.luau`
	stdPolyfills.fileSystem.writeFile(path, SCRIPT)
	scriptPath = path

	return path
end

local function start(mode: string, amount: number?): (stdPolyfills.Process, thread)
	local running = stdPolyfills.process.spawn("zune", { "run", getScriptPath(), mode, tostring(amount or 0) })
	local watchdog = task.delay(WATCHDOG_SECONDS, function()
		running.kill()
	end)

	return running, watchdog
end

local function readAll(running: stdPolyfills.Process): (string, boolean)
	local pieces = {}

	for _ = 1, MAX_READS do
		local data = running.read(READ_COUNT)

		if not data then
			return table.concat(pieces), true
		end

		check.is_true(buffer.len(data) <= 1024)
		table.insert(pieces, buffer.tostring(data))
	end

	return table.concat(pieces), false
end

local function pollUntil(condition: () -> boolean): boolean
	for _ = 1, MAX_POLLS do
		if condition() then
			return true
		end

		task.wait(POLL_SECONDS)
	end

	return condition()
end

local function pollWithin(condition: () -> boolean, seconds: number): boolean
	local deadline = os.clock() + seconds

	while not condition() and os.clock() < deadline do
		task.wait(POLL_SECONDS)
	end

	return condition()
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

	return found
end

local function stubbornSkipReason(zunePath: string?): string?
	local platform = stdPolyfills.process.getPlatform()
	local requiresFfi = stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI

	assert(
		zunePath or platform ~= "linux" or not requiresFfi,
		"DISCORD_LUAU_REQUIRE_FFI is set but the real zune binary for the SIGTERM cases was not found"
	)

	return if platform == "windows"
		then "a program cannot ignore TerminateProcess, so there is nothing to test on Windows"
		elseif platform == "macos" then "the child's libSystem signal call has not been run on macOS yet"
		elseif not zunePath then "the real zune binary was not found; the Rokit shim kills its child on SIGTERM itself"
		else nil
end

local function killInCoroutine(running: stdPolyfills.Process): (boolean, boolean)
	local killer = coroutine.create(running.kill)
	local resumed, killed = coroutine.resume(killer)

	return resumed and coroutine.status(killer) == "dead", killed == true
end

local function wrapFake(child: any): stdPolyfills.Process
	-- the adapter reads the zune global when it loads, so it can only load on Zune
	return require("../src/zune/process").wrap(child)
end

local function contains(text: string, needle: string): boolean
	return if string.find(text, needle, 1, true) then true else false
end

local function emptyHandle(): any
	return {
		read = function()
			return ""
		end,
	}
end

return function()
	test.suite("process.spawn", function()
		test.case("reads the bytes the program writes, then nil at the end", function()
			local running, watchdog = start("bytes")
			local text, ended = readAll(running)

			task.cancel(watchdog)
			check.equal(text, string.rep("A", 10) .. string.rep("B", 10) .. string.rep("C", 10))
			check.is_true(ended)
			check.equal(running.wait(), 0)
		end)

		test.case("wait returns the exit code, zero and non-zero", function()
			local zeroRunning, zeroWatchdog = start("exit", 0)
			local sevenRunning, sevenWatchdog = start("exit", 7)

			check.equal(zeroRunning.wait(), 0)
			check.equal(sevenRunning.wait(), 7)
			task.cancel(zeroWatchdog)
			task.cancel(sevenWatchdog)
		end)

		test.case("exited is false while running and true once the exit is recorded", function()
			local running, watchdog = start("hang")

			check.is_false(running.exited())
			check.is_true(running.kill())
			running.wait()
			task.cancel(watchdog)
			check.is_true(running.exited())
			check.is_true(pollUntil(running.errorEnded))
		end)

		test.case("errorEnded is false while the program writes stderr and true once stderr is drained", function()
			local running, watchdog = start("drip", DRIP_LINES)

			check.is_true(pollUntil(function()
				return contains(running.errorTail(), "line 1")
			end))
			check.is_false(running.exited())
			check.is_false(running.errorEnded())
			check.equal(running.wait(), 0)
			check.is_true(pollUntil(running.errorEnded))
			task.cancel(watchdog)
			check.is_true(contains(running.errorTail(), "last-line-marker"))
		end)

		test.case("kill in the middle of a read returns true and ends the read", function()
			local running, watchdog = start("hang")
			local first = running.read(READ_COUNT)

			check.not_nil(first)

			local killReturned = false
			local killed = false
			task.delay(0.1, function()
				killed = running.kill()
				killReturned = true
			end)

			local second = running.read(READ_COUNT)

			check.is_true(pollUntil(function()
				return killReturned
			end))
			task.cancel(watchdog)
			check.equal(second, nil)
			check.is_true(killed)
			check.is_true(pollUntil(running.exited))
		end)

		test.case("kill after a zero exit returns false", function()
			local running, watchdog = start("exit", 0)

			running.wait()
			task.cancel(watchdog)
			check.is_false(running.kill())
		end)

		test.case("kill after a non-zero exit returns false", function()
			local running, watchdog = start("exit", 3)

			check.equal(running.wait(), 3)
			task.cancel(watchdog)
			check.is_false(running.kill())
		end)

		test.case("a stderr flood keeps a 20 ms ticker within 100 ms and errorTail ends with the last line", function()
			local running, watchdog = start("flood", FLOOD_BYTES)
			local worstGap = 0
			local ticking = true

			task.spawn(function()
				local last = os.clock()

				while ticking do
					task.wait(TICK_SECONDS)

					local now = os.clock()
					worstGap = math.max(worstGap, now - last)
					last = now
				end
			end)

			local text, ended = readAll(running)

			check.equal(running.wait(), 0)
			check.is_true(pollUntil(running.errorEnded))
			ticking = false
			task.cancel(watchdog)

			local tail = running.errorTail()

			check.equal(text, "flooded")
			check.is_true(ended)
			check.is_true(worstGap < MAX_TICK_GAP_SECONDS)
			check.is_true(#tail <= MAX_TAIL_BYTES)
			check.is_true(#tail > MAX_TAIL_BYTES - 1100)
			check.equal(string.sub(tail, -#"last-line-marker\n"), "last-line-marker\n")
		end)

		test.case("a missing program raises could not start with the reason", function()
			local started, message = pcall(stdPolyfills.process.spawn, "discord-luau-no-such-program", {})

			check.is_false(started)
			check.is_true(contains(tostring(message), "could not start discord-luau-no-such-program: FileNotFound"))
		end)

		test.case("a failing exit watcher ends wait and is reported in errorTail", function()
			local running = wrapFake({
				stdout = emptyHandle(),
				stderr = emptyHandle(),
				wait = function()
					error("watch boom")
				end,
				kill = function()
					return { ok = true, code = 0 }
				end,
			})
			local finished = false

			task.spawn(function()
				running.wait()
				finished = true
			end)

			check.is_true(pollUntil(function()
				return finished
			end))
			check.is_true(contains(running.errorTail(), "exit watcher failed:"))
			check.is_true(contains(running.errorTail(), "watch boom"))
		end)

		test.case("the stderr reader yields after every read, even when data is always ready", function()
			local reads = 0
			local running = wrapFake({
				stdout = emptyHandle(),
				stderr = {
					read = function()
						reads += 1

						return if reads <= FAKE_STDERR_READS then "x" else ""
					end,
				},
				wait = function()
					return { ok = true, code = 0 }
				end,
				kill = function()
					return { ok = true, code = 0 }
				end,
			})

			check.is_true(reads <= 1)
			check.is_true(pollUntil(function()
				return #running.errorTail() == FAKE_STDERR_READS
			end))
		end)

		test.case("a failing stderr reader is reported in errorTail", function()
			local running = wrapFake({
				stdout = emptyHandle(),
				stderr = {
					read = function()
						error("read boom")
					end,
				},
				wait = function()
					return { ok = true, code = 0 }
				end,
				kill = function()
					return { ok = true, code = 0 }
				end,
			})

			check.is_true(pollUntil(function()
				return contains(running.errorTail(), "stderr reader failed:")
			end))
			check.is_true(contains(running.errorTail(), "read boom"))
			check.is_true(running.errorEnded())
		end)

		local onWindows = stdPolyfills.process.getPlatform() == "windows"
		local pendingReadCase = (if onWindows then test.skip.case else test.case) :: typeof(test.case)

		pendingReadCase("kill with a stdout read and the stderr reader pending leaves Zune running", function()
			local env = table.clone(stdPolyfills.process.getEnv())

			env.ZUNE_ASYNC_BACKEND = "epoll"

			local result = stdPolyfills.process.run(
				"zune",
				{ "run", "packages/std_polyfills/tests/killPendingRead.luau" },
				{ env = env }
			)

			check.equal(result.code, 0)
			check.is_true(contains(result.stdout, "kill with pending reads finished: killed true, exited true"))
		end)

		local zunePath = realZune()
		local stubbornSkip = stubbornSkipReason(zunePath)
		local stubbornCase = (if stubbornSkip then test.skip.case else test.case) :: typeof(test.case)

		if stubbornSkip then
			stdPolyfills.stdio.write(`process.spawn: skipping the SIGTERM-ignoring kill cases: {stubbornSkip}\n`)
		end

		stubbornCase("kill returns at once and ends a program ignoring SIGTERM on a full stdout", function()
			local running = stdPolyfills.process.spawn(zunePath :: string, { "run", getScriptPath(), "stubborn", "0" })

			task.wait(BLOCK_SECONDS)

			local returned, killed = killInCoroutine(running)

			check.is_true(returned)
			check.is_true(killed)
			check.is_true(pollWithin(running.exited, KILL_EXIT_SECONDS))
			check.is_true(pollWithin(running.errorEnded, KILL_EXIT_SECONDS))
			check.is_false(contains(running.errorTail(), "failed"))
		end)

		stubbornCase("kill returns at once for a program that ignores SIGTERM and does not write", function()
			local running = stdPolyfills.process.spawn(
				zunePath :: string,
				{ "run", getScriptPath(), "stubbornsleep", tostring(STUBBORN_SLEEP_SECONDS) }
			)

			task.wait(BLOCK_SECONDS)

			local returned, killed = killInCoroutine(running)

			check.is_true(returned)
			check.is_true(killed)
			check.is_false(running.exited())
			check.is_true(pollWithin(running.exited, SLEEP_EXIT_SECONDS))
			check.is_false(running.kill())
		end)
	end)
end
