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
	end

	error(`Out of reach`)
end

export type OS = "linux" | "macos" | "windows"

return process
