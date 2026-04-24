-- selene: allow(undefined_variable)
local io = {}

io.terminal = {
	enableRawMode = function()
		return zune.io.terminal.enableRawMode()
	end,
	restoreMode = function()
		return zune.io.terminal.restoreMode()
	end,
	getSize = function(): (number?, number?)
		return zune.io.terminal.getSize()
	end,
}

function io.stdoutWrite(data: string)
	zune.io.stdout:writeSync(data)
end

function io.stderrWrite(data: string)
	zune.io.stderr:writeSync(data)
end

function io.stdinRead(amount: number?): string
	return zune.io.stdin:read(amount, false)
end

return io
