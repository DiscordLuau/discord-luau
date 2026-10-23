local MAX_TAIL_BYTES = 4096
local STDERR_READ_BYTES = 1024

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
	local errorEnded = false
	local tail = ""
	local failures: { string } = {}
	local waiters: { thread } = {}

	zune.task.spawn(function()
		local succeeded, result = pcall(function()
			return child:wait()
		end)

		if succeeded then
			exitCode = result.code
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
	end)

	local function closeStream(stream: ZuneStream, name: string)
		local succeeded, failure = pcall(function()
			stream:close()
		end)

		if not succeeded then
			table.insert(failures, `closing {name} failed: {failure}`)
		end
	end

	local function stopChild()
		closeStream(child.stdout, "stdout")
		closeStream(child.stderr, "stderr")

		local succeeded, failure = pcall(function()
			return child:kill()
		end)

		if not succeeded then
			table.insert(failures, `kill failed: {failure}`)
		end
	end

	local handle = {}

	function handle.read(count: number): buffer?
		local data = child.stdout:read(count, true) :: buffer

		if buffer.len(data) == 0 then
			return
		end

		return data
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

type ZuneChild = {
	stdout: ZuneStream,
	stderr: ZuneStream,
	wait: (ZuneChild) -> { code: number },
	kill: (ZuneChild) -> any,
}

return process
