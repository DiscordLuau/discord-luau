--> Typechecks the workspace using `luau-lsp analyze` -- lune run task analyze

local process = require("@lune/process")
local shared = require("shared")

local function analyze(args: { string }, task: shared.TaskEnv): number
	return task.execute("luau-lsp", "analyze", "--settings=.luau-lsp.json", "packages/", table.unpack(args))
end

return analyze
