--[=[
	@class StdPolyfills.process
]=]

local runtime = require("./runtime")

local process = {}

--[=[
	@within StdPolyfills.process

	Returns the current OS thats being used
]=]
function process.getPlatform(): OS
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/process").os :: OS
	elseif target == "Zune" then
		return require("./zune/process").os :: OS
	elseif target == "Roblox" then
		return require("./roblox/process").os :: OS
	elseif target == "Eryx" then
		return require("./eryx/process").os :: OS
	elseif target == "Lute" then
		return require("./lute/process").os :: OS
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.process

	Returns the arguments passed into the current program
]=]
function process.getArgs(): { string }
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/process").args :: { string }
	elseif target == "Zune" then
		return require("./zune/process").args :: { string }
	elseif target == "Roblox" then
		return require("./roblox/process").args :: { string }
	elseif target == "Eryx" then
		return require("./eryx/process").args :: { string }
	elseif target == "Lute" then
		return require("./lute/process").args :: { string }
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.process

	Returns the environment the current process is executing under
]=]
function process.getEnv(): { [string]: string }
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/process").env :: { [string]: string }
	elseif target == "Zune" then
		return require("./zune/process").env :: { [string]: string }
	elseif target == "Roblox" then
		return require("./roblox/process").env :: { [string]: string }
	elseif target == "Eryx" then
		return require("./eryx/process").env :: { [string]: string }
	elseif target == "Lute" then
		return require("./lute/process").env :: { [string]: string }
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.process

	Returns the current working directory for this process
]=]
function process.getCwd(): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/process").cwd :: string
	elseif target == "Zune" then
		return require("./zune/process").cwd :: string
	elseif target == "Roblox" then
		return require("./roblox/process").cwd :: string
	elseif target == "Eryx" then
		return require("./eryx/process").cwd :: string
	elseif target == "Lute" then
		return require("./lute/process").cwd() :: string
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.process

	Runs a subprocess and returns the result. Only supported on Zune; calling from
	Lune will raise an error explaining the requirement.
]=]
function process.run(exec: string, args: { string }?, opts: { cwd: string?, env: { [string]: string }? }?): RunResult
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/process").exec(exec, args, opts) :: RunResult
	elseif target == "Zune" then
		return require("./zune/process").run(exec, args, opts) :: RunResult
	elseif target == "Roblox" then
		error(`process.run is not available on Roblox`)
	elseif target == "Eryx" then
		return require("./eryx/process").run(exec, args, opts) :: RunResult
	elseif target == "Lute" then
		return require("./lute/process").run(exec, args, opts) :: RunResult
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.process

	Starts a program directly, without a shell, with stdout and stderr piped and stdin ignored. Only supported on Zune;
	other runtimes raise `process.spawn is not supported on this runtime`. Raises `could not start <command>: <reason>`
	when the program cannot start.
]=]
function process.spawn(command: string, arguments: { string }): Process
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/process").spawn(command, arguments) :: Process
	end

	error(`process.spawn is not supported on this runtime`)
end

--[=[
	@within StdPolyfills.process

	Returns the CPU architecture the current process is executing on
]=]
function process.getArch(): Arch
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/process").arch :: Arch
	elseif target == "Zune" then
		return require("./zune/process").arch :: Arch
	elseif target == "Roblox" then
		error(`process.getArch is not available on Roblox`)
	elseif target == "Eryx" then
		return require("./eryx/process").arch :: Arch
	elseif target == "Lute" then
		return require("./lute/process").arch :: Arch
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.process

	Registers a callback to be invoked when the process receives an OS signal (e.g. `"INT"` for SIGINT).
	Only supported on Zune; on Lune this is a no-op with a warning.
]=]
function process.onSignal(signal: Signal, callback: () -> ())
	if not runtime.capabilities().onSignal then
		return
	end

	local target = runtime.assertRuntime()

	if target == "Zune" then
		require("./zune/process").onSignal(signal, callback)
	elseif target == "Lute" then
		require("./lute/process").onSignal(signal, callback)
	end
end

export type Signal = "INT"
export type OS = "linux" | "macos" | "windows"
export type Arch = "x86_64" | "aarch64"

export type RunResult = {
	ok: boolean,
	code: number,
	stdout: string,
	stderr: string,
}

--[=[
	@interface Process
	@within StdPolyfills.process
	.read (count: number) -> buffer? -- up to `count` bytes of stdout (at most 1024 on Zune), or nil at the end; after `kill`, a read in flight returns nil and a new read raises
	.wait () -> number -- the exit code
	.exited () -> boolean
	.kill () -> boolean -- never yields: closes stdout and stderr, so a program blocked writing to them can exit, and stops the program in the background (SIGTERM, or TerminateProcess on Windows); false when the exit was already recorded
	.errorTail () -> string -- the last 4 KiB of stderr, then any failed background thread
	.errorEnded () -> boolean -- true once stderr is read to its end, or its reader stopped after a kill or failed; at the end of stderr `errorTail` holds its last line, after a kill only what was read so far
]=]
export type Process = {
	read: (count: number) -> buffer?,
	wait: () -> number,
	exited: () -> boolean,
	kill: () -> boolean,
	errorTail: () -> string,
	errorEnded: () -> boolean,
}

return process
