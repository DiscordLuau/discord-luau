--> Task for linting packages using selene

local task = require("./task")

task.new("selene"):addArgument("packages"):execute()
