--# selene: allow(bad_string_escape)
-- selene: allow(undefined_variable)
local stdio = {}

function stdio.write(source: string)
	zune.io.stdout:write(source)
end

function stdio.prompt(message: string?): string
	zune.task.defer(function()
		zune.io.stdout:write("\r\x1b[2K")

		if message then
			zune.io.stdout:write(message)
		end
	end)

	local content = zune.io.stdin:read() :: string

	content = string.gsub(content, "\r?\n$", "")

	zune.io.stdout:write("\x1b[1A\x1b[2K")

	return content
end

return stdio
