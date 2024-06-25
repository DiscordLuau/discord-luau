local process = require("@lune/process")
local shared = require("@root/lune/shared")

local function lint(args: { string }, task: shared.TaskEnv): number
	return task.execute("selene", "packages/", table.unpack(args))
end

return lint
