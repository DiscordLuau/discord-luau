local erxStdio = require("@eryx/stdio")

local io = {}

io.terminal = {
	enableRawMode = function()
		erxStdio.setRawMode(true)
	end,
	restoreMode = function()
		erxStdio.setRawMode(false)
	end,
	getSize = function(): (number?, number?)
		local size = erxStdio.terminalSize()

		if not size then
			return nil, nil
		end

		return size.columns, size.rows
	end,
}

function io.stdoutWrite(data: string)
	erxStdio.write(data)
end

function io.stderrWrite(data: string)
	erxStdio.writeerr(data)
end

function io.stdinRead(amount: number?): string
	if amount then
		return erxStdio.read(amount)
	end

	return erxStdio.readline()
end

return io
