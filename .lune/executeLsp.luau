--[[
	Responsible for typechecking the Discord-Luau codebase using the Luau LSP.

	Additional arguments are required to ensure that the LSP has context on the codebase's aliases
		and other settings.
]]

local task = require("src/task")

task.new("luau-lsp")
	:addArgument("analyze")
	:addArgument("--base-luaurc=.luaurc")
	:addArgument("--settings=.luau-analyze")
	:addArgument("packages")
	:execute()
