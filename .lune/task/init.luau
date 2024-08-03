--> An internal library for lune scripts to execute tasks in CI/CD

-- NOTE: we're using the `Lune` runtime in the CI/CD environment, so we're not going to be using the `@std-polyfills`
-- package that the discord-luau package uses.

local process = require("@lune/process")
local stdio = require("@lune/stdio")

local Task = {}

Task.Prototype = {}
Task.Interface = {}

--[[
	Responsible for adding an argument to the executable.
]]
function Task.Prototype.addArgument(self: Task, argument: string): Task
	table.insert(self.arguments, argument)

	return self
end

--[[
	Responsible for executing the task.

	Will dynamically error the CI/CD environment if the executable fails.
]]
function Task.Prototype.execute(self: Task): process.SpawnResult
	local spawnResult = process.spawn(self.executable, self.arguments)

	if spawnResult.ok then
		print(
			`{stdio.color("green")}Executable '{self.executable}' has passed with the following exit code: '{spawnResult.code}'`
		)
	else
		print(
			`{stdio.color("red")}Executable '{self.executable}' has failed with the following exit code: '{spawnResult.code}', stderr is as follows;`
		)
		print(`{stdio.color("cyan")}{spawnResult.stderr}`)

		process.exit(spawnResult.code)
	end

	return spawnResult
end

--[[
	Constructor for the Task object.
]]
function Task.Interface.new(executable: string): Task
	return setmetatable(
		{
			executable = executable,

			arguments = {},
		} :: Task,
		{
			__index = Task.Prototype,
		}
	)
end

export type Task = typeof(Task.Prototype) & {
	executable: string,
	arguments: { string },
}

return Task.Interface
