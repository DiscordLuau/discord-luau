-- selene: allow(undefined_variable)
local zuneTask = zune.task
local zuneIo = zune.io

local stdio = {}

function stdio.write(source: string)
	zuneIo.stdout:write(source)
end

function stdio.prompt(message: string?): string
	zuneTask.defer(function()
		zuneIo.stdout:write("\r\x1b[2K")

		if message then
			zuneIo.stdout:write(message)
		end
	end)

	local content = zuneIo.stdin:read() :: string

	content = string.gsub(content, "\r?\n$", "")

	zuneIo.stdout:write("\x1b[1A\x1b[2K")

	return content
end

return stdio
