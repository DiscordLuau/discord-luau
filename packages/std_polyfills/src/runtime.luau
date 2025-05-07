--[=[
	@class StdPolyfills.runtime
]=]

local LUNE_STRING_MATCH = "(Lune) (%d+%.%d+%.%d+.*)+(%d+)"
local ZUNE_STRING_MATCH = "(Zune) (%d+%.%d+%.%d+.*)+(%d+%.%d+)"

local runtime = {}

--[=[
	@within StdPolyfills.runtime

	Will return the Runtime that this code is being executed under.
]=]
function runtime.getRuntime(): RuntimeValue
	local version = _VERSION

	if version == "Luau" then
		-- selene: allow(undefined_variable)
		if game and workspace then
			return "Roblox"
		else
			return "Luau"
		end
	else
		if string.match(version, LUNE_STRING_MATCH) then
			return "Lune"
		elseif string.match(version, ZUNE_STRING_MATCH) then
			return "Zune"
		end
	end

	-- TODO: at some point in the future - figure out how to detect Lute!

	return "Unknown"
end

--[=[
	@within StdPolyfills.runtime

	Will error out if the current Runtime is not supported by Discord-Luau
]=]
function runtime.assertRuntime(): RuntimeValue
	local currentRuntime = runtime.getRuntime()

	if currentRuntime ~= "Lune" then
		error(`Discord-Luau currently doesn't support the '{currentRuntime}' runtime!`)
	end

	return currentRuntime
end

export type RuntimeValue = "Lune" | "Zune" | "Roblox" | "Luau" | "Lute" | "Unknown"
export type Runtime = typeof(runtime)

return runtime
