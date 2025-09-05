local task = require("@lune/task")
local stdio = setmetatable({}, { __index = require("@lune/stdio") })

local prompt = stdio.prompt

stdio.prompt = function(message: string?)
	task.defer(function()
		stdio.write("\r\x1b[2K")

		if message then
			stdio.write(message)
		end
	end)

	local content = prompt("text") :: string

	stdio.write("\x1b[1A\x1b[2K")

	return content
end

return stdio
