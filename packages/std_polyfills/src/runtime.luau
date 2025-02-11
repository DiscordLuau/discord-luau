--[=[
    @class Std.Runtime
]=]

local LUNE_STRING_MATCH = "(Lune) (%d+%.%d+%.%d+.*)+(%d+)"
local ZUNE_STRING_MATCH = "(Zune) (%d+%.%d+%.%d+.*)+(%d+%.%d+)"

local Runtime = {}

function Runtime.GetRuntime(_: Runtime): RuntimeValue
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

function Runtime.AssertRuntime(self: Runtime): RuntimeValue
	local currentRuntime = self:GetRuntime()

	if currentRuntime ~= "Lune" then
		error(`Discord-Luau currently doesn't support the '{currentRuntime}' runtime!`)
	end

	return currentRuntime
end

export type RuntimeValue = "Lune" | "Zune" | "Roblox" | "Luau" | "Lute" | "Unknown"
export type Runtime = typeof(Runtime)

return Runtime
