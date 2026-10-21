local luteTask = require("@std/task")

local task = {}

task.spawn = luteTask.spawn
task.defer = luteTask.defer
task.wait = luteTask.wait
task.cancel = luteTask.cancel

function task.delay(duration: number, functionOrThread: thread | (...any) -> ...any, ...: any): thread
	local arguments = table.pack(...)

	return luteTask.spawn(function()
		luteTask.wait(duration)

		if typeof(functionOrThread) == "thread" then
			luteTask.spawn(functionOrThread, table.unpack(arguments, 1, arguments.n))
		else
			functionOrThread(table.unpack(arguments, 1, arguments.n))
		end
	end)
end

return task
