--[=[
	@class StdPolyfills.io
]=]

local runtime = require("./runtime")

local io = {}

io.terminal = {
	enableRawMode = function()
		local target = runtime.assertRuntime()

		if target == "Lune" then
			return require("./lune/io").terminal.enableRawMode()
		elseif target == "Zune" then
			return require("./zune/io").terminal.enableRawMode()
		end

		error(`Out of reach`)
	end,
	restoreMode = function()
		local target = runtime.assertRuntime()

		if target == "Lune" then
			return require("./lune/io").terminal.restoreMode()
		elseif target == "Zune" then
			return require("./zune/io").terminal.restoreMode()
		end

		error(`Out of reach`)
	end,
	getSize = function(): (number?, number?)
		local target = runtime.assertRuntime()

		if target == "Lune" then
			return require("./lune/io").terminal.getSize()
		elseif target == "Zune" then
			return require("./zune/io").terminal.getSize()
		end

		error(`Out of reach`)
	end,
}

--[=[
	@within StdPolyfills.io

	Writes data to stdout.
]=]
function io.stdoutWrite(data: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/io").stdoutWrite(data)
	elseif target == "Zune" then
		return require("./zune/io").stdoutWrite(data)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.io

	Writes data to stderr.
]=]
function io.stderrWrite(data: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/io").stderrWrite(data)
	elseif target == "Zune" then
		return require("./zune/io").stderrWrite(data)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.io

	Reads up to `amount` bytes from stdin as a string.
]=]
function io.stdinRead(amount: number?): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/io").stdinRead(amount)
	elseif target == "Zune" then
		return require("./zune/io").stdinRead(amount)
	end

	error(`Out of reach`)
end

return io
