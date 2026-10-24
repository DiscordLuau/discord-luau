local MAX_TAIL_BYTES = 4096
local STDERR_READ_BYTES = 1024
local SIGTERM = 15
local TERMINATED_EXIT_CODE = 1
local HANDLE_ADDRESS_BYTES = 8
local LIBC_BY_OS: { [string]: string } = { linux = "libc.so.6", macos = "libSystem.B.dylib" }

local libc: Libc?
local kernel32: Kernel32?

-- selene: allow(undefined_variable)
local process = {}

process.os = zune.platform.os
process.arch = zune.platform.cpu.arch
-- Zune includes the script path as args[1]; strip it to match Lune's convention
local rawArgs = zune.process.args
process.args = table.move(rawArgs, 2, #rawArgs, 1, {})
process.env = zune.process.env
process.cwd = zune.process.cwd()

function process.run(exec: string, args: { string }?, opts: { cwd: string?, env: { [string]: string }? }?)
	return zune.process.run(exec, args, opts :: any)
end

--[=[
	@private

	Builds the `Process` handle around a running child. It exists so the specs can inject fake children, because
	`zune.process` is readonly and a real child cannot fail on demand.
]=]
function process.wrap(child: ZuneChild): ProcessHandle
	local exited = false
	local exitCode = 0
	local killed = false
	local signalled = false
	local errorEnded = false
	local stdoutReading = false
	local tail = ""
	local failures: { string } = {}
	local waiters: { thread } = {}

	local function closeStream(stream: ZuneStream, name: string)
		local succeeded, failure = pcall(function()
			stream:close()
		end)

		if not succeeded then
			table.insert(failures, `closing {name} failed: {failure}`)
		end
	end

	zune.task.spawn(function()
		local succeeded, result = pcall(function()
			return child:wait()
		end)

		if succeeded then
			exitCode = if signalled then SIGTERM else result.code
		else
			exitCode = -1
			table.insert(failures, `exit watcher failed: {result}`)
		end

		exited = true

		for _, waiter in table.clone(waiters) do
			local woken, wakeFailure = pcall(zune.task.spawn, waiter)

			if not woken then
				table.insert(failures, `exit watcher could not wake a waiter: {wakeFailure}`)
			end
		end

		table.clear(waiters)
	end)

	zune.task.spawn(function()
		local succeeded, failure = pcall(function()
			while not killed do
				local data = child.stderr:read(STDERR_READ_BYTES, false)

				if #data == 0 then
					break
				end

				tail = string.sub(tail .. data, -MAX_TAIL_BYTES)
				zune.task.wait()
			end
		end)

		if not succeeded and not killed then
			table.insert(failures, `stderr reader failed: {failure}`)
		end

		errorEnded = true

		if killed then
			closeStream(child.stderr, "stderr")
		end
	end)

	-- Zune's `kill` adds a second wait on the program. On macOS it takes the program's one kqueue exit event from the
	-- exit watcher, which then never wakes. On Windows it never completes while the exit watcher waits, and now and then
	-- it corrupts the IOCP loop, so Zune spins after the script ends. So Linux and macOS send SIGTERM through libc, and
	-- Windows calls TerminateProcess through kernel32 on the handle Zune's `pid` holds there, with the exit code Zune's
	-- `kill` used. The program is stopped only while its exit is unrecorded, since another program may own the pid after
	-- that. On Linux and macOS the exit code then reads SIGTERM, as it does after Zune's `kill`.
	local function terminate()
		print(`[trace {string.format("%.3f", os.clock())}] proc terminate, exited={exited}`)
		local library = LIBC_BY_OS[process.os]
		local pid = child.pid
		local onWindows = process.os == "windows"

		if not pid or not zune.ffi or not (library or onWindows) then
			child:kill()
		elseif exited then
			return
		elseif library then
			local types = zune.ffi.types
			local loaded = libc
				or zune.ffi.dlopen(library, { kill = { returns = types.i32, args = { types.i32, types.i32 } } }) :: any

			libc = loaded
			assert(loaded.kill(pid, SIGTERM) == 0, `kill({pid}, SIGTERM) failed`)
			signalled = true
		else
			local types = zune.ffi.types
			local loaded = kernel32
				or zune.ffi.dlopen("kernel32.dll", {
					TerminateProcess = { returns = types.i32, args = { types.pointer, types.u32 } },
				}) :: any
			local handleAddress = buffer.create(HANDLE_ADDRESS_BYTES)

			kernel32 = loaded
			buffer.writeu32(handleAddress, 0, pid)
			assert(
				loaded.TerminateProcess(zune.ffi.ptrFromAddress(handleAddress), TERMINATED_EXIT_CODE) ~= 0,
				"TerminateProcess failed"
			)
		end
	end

	-- On kqueue (macOS) and epoll, Zune 0.5.9 reads a pipe on a thread-pool worker that closing the pipe cannot stop:
	-- the close frees the pending read, and the worker's late result frees it again. So a stream is closed here only
	-- while no read waits on it; otherwise the thread reading it closes it once that read returns.
	local function stopChild()
		if not stdoutReading then
			closeStream(child.stdout, "stdout")
		end

		if errorEnded then
			closeStream(child.stderr, "stderr")
		end

		local succeeded, failure = pcall(function()
			terminate()
		end)

		if not succeeded then
			table.insert(failures, `kill failed: {failure}`)
		end
	end

	local handle = {}

	function handle.read(count: number): buffer?
		local succeeded: boolean, data: any

		if killed then
			print(`[trace {string.format("%.3f", os.clock())}] proc stdout read after the kill raises file closed`)
			error("file closed", 0)
		end

		stdoutReading = true
		succeeded, data = pcall(function()
			return child.stdout:read(count, true)
		end)
		stdoutReading = false
		print(`[trace {string.format("%.3f", os.clock())}] proc stdout read returned ok={succeeded} killed={killed} {if succeeded then `{buffer.len(data)}B` else tostring(data)}`)

		if killed then
			closeStream(child.stdout, "stdout")
		elseif not succeeded then
			error(data, 0)
		end

		return if not killed and buffer.len(data) > 0 then data else nil
	end

	function handle.wait(): number
		if not exited then
			table.insert(waiters, coroutine.running())
			coroutine.yield()
		end

		return exitCode
	end

	function handle.exited(): boolean
		return exited
	end

	function handle.kill(): boolean
		local first = not killed and not exited

		if first then
			killed = true
			zune.task.spawn(stopChild)
		end

		return not exited
	end

	function handle.errorTail(): string
		local text = tail

		for _, failure in failures do
			text ..= `{if text == "" then "" else "\n"}{failure}`
		end

		return text
	end

	function handle.errorEnded(): boolean
		return errorEnded
	end

	return handle
end

function process.spawn(command: string, arguments: { string })
	local created, child = pcall(
		zune.process.create,
		command,
		arguments,
		{
			stdout = "pipe",
			stderr = "pipe",
			stdin = "ignore",
		} :: any
	)

	if not created then
		error(`could not start {command}: {child}`, 0)
	end

	return process.wrap(child :: any)
end

function process.onSignal(signal: string, callback: () -> ())
	zune.process.onSignal(signal :: "INT", callback)
end

type ProcessHandle = {
	read: (count: number) -> buffer?,
	wait: () -> number,
	exited: () -> boolean,
	kill: () -> boolean,
	errorTail: () -> string,
	errorEnded: () -> boolean,
}

type ZuneStream = {
	read: (ZuneStream, amount: number, bytes: boolean) -> any,
	close: (ZuneStream) -> (),
}

type Libc = {
	kill: (pid: number, signal: number) -> number,
}

type Kernel32 = {
	TerminateProcess: (handle: any, exitCode: number) -> number,
}

type ZuneChild = {
	pid: number?,
	stdout: ZuneStream,
	stderr: ZuneStream,
	wait: (ZuneChild) -> { code: number },
	kill: (ZuneChild) -> any,
}

return process
