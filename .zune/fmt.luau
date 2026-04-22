--> Task to execute StyLua for checking validity of formatting

local task = require("./task")

task.new("stylua")
	:addArgument("--check")
	:addArgument("--output-format")
	:addArgument("Summary")
	:addArgument("packages")
	:execute()
