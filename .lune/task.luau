--> Runs the requested task -- lune run task {TASK_NAME}

local process = require("@lune/process")
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local stdio = require("@lune/stdio")

local shared = require("shared")
local logger = require("logger")

local function envExecute(program: string, ...)
	local command = process.spawn(program, table.pack(...), {
		stdio = "forward",
		shell = true,
	})

	return command.code
end

function main(args: { string })
	local taskName = table.remove(args, 1) or "main"
	local exists, taskSrc = pcall(fs.readFile, ".lune/" .. taskName .. ".luau")

	if not exists then
		logger.error(`Task "{taskName}" not found.`)
		return 1
	end

	local runTask: (args: { string }, env: shared.TaskEnv) -> number = luau.load(taskSrc, {
		environment = {
			-- NOTE: Requires via relative paths break without this
			require = function<T>(path: any)
				return require(path) :: T
			end,
		},
		debugName = taskName,
		codegenEnabled = true,
	})()
	local result = runTask(args, {
		logger = logger,
		execute = envExecute,
	})

	if result ~= 0 then
		stdio.write("\n")
		logger.error(`Task "{taskName}" failed.`)
	end

	return result
end

return process.exit(main(table.clone(process.args)))
