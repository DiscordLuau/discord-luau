--> Task to execute Darklua for bundling the various packages apart of Discord-Luau

local task = require("../../../.lune/task")

task.new("darklua")
	:addArgument("process")
	:addArgument("src/init.luau")
	:addArgument("bundled.luau")
	:addArgument(`-cdarklua.json`)
	:execute()

task.new("stylua"):addArgument("bundled.luau"):execute()
task.new("lune"):addArgument("run"):addArgument("fixTypes"):execute()
task.new("stylua"):addArgument("bundled.luau"):execute()
