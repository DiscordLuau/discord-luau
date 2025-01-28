--> An internal library for lune scripts to execute tasks in CI/CD

-- NOTE: We use the `Lune` runtime in the CI/CD environment, so we're not going to be using the `@std-polyfills`
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
	Responsible for setting the current working directory for this task
]]
function Task.Prototype.setcwd(self: Task, cwd: string): Task
	self.cwd = cwd

	return self
end

--[[
	Responsible for executing the task.

	Inherits the standard IO of the process.
]]
function Task.Prototype.execute(self: Task): process.SpawnResult
	local spawnResult = process.spawn(self.executable, self.arguments, {
		stdio = "forward",
		cwd = self.cwd,
	})

	if not spawnResult.ok then
		print(
			`\n[{stdio.color("red")}error{stdio.color("reset")}] \`{self.executable}\` exited with code {spawnResult.code} `
		)

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
	cwd: string?,
	arguments: { string },
}

return Task.Interface
