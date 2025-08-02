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
	end

	error(`Out of reach`)
end

export type OS = "linux" | "macos" | "windows"

return process
