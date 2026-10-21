local luteIo = require("@lute/io")

local io = {}

io.terminal = {
	enableRawMode = function()
		error("Terminal raw mode is not supported on Lute")
	end,
	restoreMode = function()
		error("Terminal raw mode is not supported on Lute")
	end,
	getSize = function(): (number?, number?)
		return nil, nil
	end,
}

function io.stdoutWrite(data: string)
	luteIo.write(data)
end

function io.stderrWrite(data: string)
	luteIo.write(data)
end

function io.stdinRead(amount: number?): string
	return luteIo.read(amount)
end

return io
