--> run a script, scripts can be found under ./lune/scripts

-- scripts are generally just luau files that are quickly put together in order to achieve something quickly -
-- such as automating files

-- NOTE: we're using the `Lune` runtime in the CI/CD environment, so we're not going to be using the `@std-polyfills`
-- package that the discord-luau package uses.

local process = require("@lune/process")
local fs = require("@lune/fs")

local task = require("./task")

local processArguments = table.clone(process.args)
local scriptName = table.remove(processArguments, 1)
local scriptPath = `.lune/scripts/{scriptName}.luau`

assert(fs.isFile(scriptPath), `Script '{scriptName}' not found! Unable to execute script!`)

local taskObject = task.new("lune"):addArgument("run"):addArgument(scriptPath)

for _, argument in processArguments do
	taskObject:addArgument(argument)
end

taskObject:execute()
