--[=[
	@class StdPolyfills.runtime
]=]

local LUNE_STRING_MATCH = "(Lune) (%d+%.%d+%.%d+.*)+(%d+)"
local ZUNE_STRING_MATCH = "(zune) (%d+%.%d+%.%d+.*)+(%d+%.%d+)"

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

	if currentRuntime ~= "Lune" and currentRuntime ~= "Zune" and currentRuntime ~= "Roblox" then
		error(`Discord-Luau currently doesn't support the '{currentRuntime}' runtime!`)
	end

	return currentRuntime
end

--[=[
	@within StdPolyfills.runtime

	Returns a table describing which optional capabilities are available on the current runtime.
	Use this to guard features that are not universally supported before attempting to load them.

	```luau
	local caps = stdPolyfills.runtime.capabilities()
	if not caps.ffi then
		-- skip FFI-dependent setup
	end
	```
]=]
function runtime.capabilities(): Capabilities
	local current = runtime.getRuntime()

	if current == "Zune" then
		return {
			ffi = true,
			udp = true,
			onSignal = true,
			compress = true,
			forbidCustomUserAgent = false,
		}
	elseif current == "Lune" then
		return {
			ffi = false,
			udp = false,
			onSignal = false,
			compress = true,
			forbidCustomUserAgent = false,
		}
	end

	return {
		ffi = false,
		udp = false,
		onSignal = false,
		compress = false,
		forbidCustomUserAgent = true,
	}
end

export type Capabilities = {
	ffi: boolean,
	udp: boolean,
	onSignal: boolean,
	compress: boolean,
	forbidCustomUserAgent: boolean,
}

export type RuntimeValue = "Lune" | "Zune" | "Roblox" | "Luau" | "Lute" | "Unknown"
export type Runtime = typeof(runtime)

return runtime
