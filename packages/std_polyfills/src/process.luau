--[=[
    @class Std.Process
]=]

local Runtime = require("runtime")

local Process = {}

function Process.getPlatform(): OS
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/process").os
	end

	error(`Out of reach`)
end

export type OS = "linux" | "macos" | "windows"

return Process
