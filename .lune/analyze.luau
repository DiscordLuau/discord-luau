--> Task to typecheck packages using luau-lsp

local task = require("task")

task.new("luau-lsp")
	:addArgument("analyze")
	:addArgument("--base-luaurc=.luaurc")
	:addArgument("--settings=.luau-analyze")
	:addArgument("packages")
	:execute()
