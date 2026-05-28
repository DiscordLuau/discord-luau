-- selene: allow(undefined_variable)
local stdio = {}

function stdio.write(source: string)
	print(source)
end

function stdio.prompt(_message: string?): string
	error("stdio.prompt is not available on Roblox")
end

return stdio
