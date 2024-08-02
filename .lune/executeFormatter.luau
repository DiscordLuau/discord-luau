--[[
	Responsible for executing the Luau formatter on the Discord-Luau codebase.

	Additional configuration is required to ensure that the formatter does not format the code, but instead errors
		if the code is not formatted correctly.
]]

local task = require("src/task")

task.new("stylua")
	:addArgument("--check")
	:addArgument("--output-format")
	:addArgument("Summary")
	:addArgument("packages")
	:execute()
