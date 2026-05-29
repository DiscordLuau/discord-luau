local erxStdio = require("@eryx/stdio")

local stdio = {}

function stdio.write(source: string)
	erxStdio.write(source)
end

function stdio.prompt(message: string?): string
	if message then
		erxStdio.write(message)
	end

	return erxStdio.readline()
end

return stdio
