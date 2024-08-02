--[[
	Responsible for executing the Luau linter on the Discord-Luau codebase.

	No additional configuration is required.
]]

local task = require("src/task")

task.new("selene"):addArgument("packages"):execute()
