local process = require("@lune/process")
local shared = require("@root/lune/shared")

local function fmt(args: { string }, task: shared.TaskEnv): number
	return task.execute("stylua", "packages/", "-v", table.unpack(args))
end

return fmt
