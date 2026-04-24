--> run a script, scripts can be found under .zune/scripts

local task = require("./task")

local processArguments = table.clone(zune.process.args)
table.remove(processArguments, 1)
local scriptName = table.remove(processArguments, 1)
local scriptPath = `.zune/scripts/{scriptName}.luau`

local ok, stat = pcall(zune.fs.stat, scriptPath)
assert(ok and stat.kind == "file", `Script '{scriptName}' not found! Unable to execute script!`)

local taskObject = task.new("zune"):addArgument("run"):addArgument(scriptPath)

for _, argument in processArguments do
	taskObject:addArgument(argument)
end

taskObject:execute()
