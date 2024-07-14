--> Runs lints on the workspace using selene -- lune run task lint

local process = require("@lune/process")
local shared = require("shared")

local function lint(args: { string }, task: shared.TaskEnv): number
	return task.execute("selene", "packages/", table.unpack(args))
end

return lint
