--[=[
	@class StdPolyfills.stdio
]=]

local runtime = require("./runtime")

local stdio = {}

--[=[
	@within StdPolyfills.stdio

	Reads text in from the terminal
]=]
function stdio.prompt(message: string?): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/stdio").prompt(message)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.stdio

	Writes text to stdout
]=]
function stdio.write(source: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/stdio").write(source)
	end

	error(`Out of reach`)
end

return stdio
