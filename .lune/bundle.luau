--> Task to typecheck packages using luau-lsp

local task = require("./task")

task.new("pesde"):addArgument("install"):setcwd("packages/api_types"):execute()
task.new("lune"):addArgument("run"):addArgument("bundle"):setcwd("packages/api_types"):execute()
