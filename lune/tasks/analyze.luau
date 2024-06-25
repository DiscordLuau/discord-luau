local process = require("@lune/process")
local shared = require("@root/lune/shared")

local function analyze(args: { string }, task: shared.TaskEnv): number
	return task.execute("luau-lsp", "analyze", "--settings=.luau-lsp.json", "packages/", table.unpack(args))
end

return analyze
