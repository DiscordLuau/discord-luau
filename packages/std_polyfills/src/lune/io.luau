local io = {}

io.terminal = {
	enableRawMode = function()
		error("Lune does not support raw terminal mode")
	end,
	restoreMode = function()
		error("Lune does not support raw terminal mode")
	end,
	getSize = function()
		error("Lune does not support terminal size queries")
	end,
}

function io.stdoutWrite(_data: string)
	error("Lune does not support raw stdout stream access")
end

function io.stderrWrite(_data: string)
	error("Lune does not support raw stderr stream access")
end

function io.stdinRead(_amount: number?): string
	error("Lune does not support raw stdin stream access")
end

return io
