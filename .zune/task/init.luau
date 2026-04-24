--> An internal library for zune scripts to execute tasks in CI/CD

local Task = {}

Task.Prototype = {}
Task.Interface = {}

function Task.Prototype.addArgument(self: Task, argument: string): Task
	table.insert(self.arguments, argument)

	return self
end

function Task.Prototype.setcwd(self: Task, cwd: string): Task
	self.cwd = cwd

	return self
end

function Task.Prototype.execute(self: Task)
	local result = zune.process.run(self.executable, self.arguments, {
		stdout = "inherit",
		stderr = "inherit",
		cwd = self.cwd,
	})

	if not result.ok then
		print(`\n[\27[31merror\27[0m] \`{self.executable}\` exited with code {result.code}`)

		zune.process.exit(result.code)
	end
end

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
