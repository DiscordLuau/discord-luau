--> Task to typecheck packages using luau-lsp

local task = require("./task")

task.new("luau-lsp")
	:addArgument("analyze")
	:addArgument("--base-luaurc=.luaurc")
	:addArgument("--settings=.vscode/settings.json")
	:addArgument("--defs=globalTypes.d.luau")
	:addArgument("--ignore=**/luau_packages/**")
	:addArgument("--ignore=**/lune_packages/**")
	:addArgument("--ignore=**/.lune**")
	:addArgument("--ignore=**/bundled.luau")
	:addArgument("packages")
	:execute()
