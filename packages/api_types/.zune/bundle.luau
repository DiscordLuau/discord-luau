--> Task to execute Darklua for bundling the various packages apart of Discord-Luau

local task = require("../../../.zune/task")

task.new("darklua")
	:addArgument("process")
	:addArgument("src/init.luau")
	:addArgument("bundled.luau")
	:addArgument(`-cdarklua.json`)
	:execute()

task.new("stylua"):addArgument("bundled.luau"):execute()
task.new("zune"):addArgument("run"):addArgument(".zune/fixTypes.luau"):execute()
task.new("stylua"):addArgument("bundled.luau"):execute()
