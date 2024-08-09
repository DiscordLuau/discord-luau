--> Task to typecheck packages using luau-lsp

local task = require("task")

task.new("luau-lsp")
	:addArgument("analyze")
	:addArgument("--base-luaurc=.luaurc")
	:addArgument("--settings=.vscode/settings.json")
	:addArgument("packages")
	:execute()
