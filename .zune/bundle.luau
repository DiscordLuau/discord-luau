--> Task to typecheck packages using luau-lsp

local task = require("./task")

task.new("pesde"):addArgument("install"):setcwd("packages/api_types"):execute()
task.new("zune"):addArgument("run"):addArgument(".zune/bundle.luau"):setcwd("packages/api_types"):execute()
