--> Task to typecheck packages using luau-lsp

local task = require("./task")

task.new("lune"):addArgument("run"):addArgument("bundle"):setcwd("packages/api-types"):execute()
