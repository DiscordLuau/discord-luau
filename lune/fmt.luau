--> Formats source code using Stylua -- lune run task fmt

local process = require("@lune/process")
local shared = require("shared")

local function fmt(args: { string }, task: shared.TaskEnv): number
	return task.execute("stylua", "packages/", "-v", table.unpack(args))
end

return fmt
