--[[
    std.task
]]

local runtime = require("runtime")

local task = {}

function task.cancel(thread: thread)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/task").cancel(thread)
	end

	error(`Out of reach`)
end

function task.defer<T...>(functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/task").defer(functionOrThread, ...)
	end

	error(`Out of reach`)
end

function task.delay<T...>(duration: number, functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/task").delay(duration, functionOrThread, ...)
	end

	error(`Out of reach`)
end

function task.spawn<T...>(functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/task").spawn(functionOrThread, ...)
	end

	error(`Out of reach`)
end

function task.wait(duration: number?): number
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/task").wait(duration)
	end

	error(`Out of reach`)
end

export type OS = "linux" | "macos" | "windows"

return task
