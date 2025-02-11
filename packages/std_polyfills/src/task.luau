--[=[
    @class Std.Task
]=]

local Runtime = require("runtime")

local Task = {}

function Task.cancel(thread: thread)
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/task").cancel(thread)
	end

	error(`Out of reach`)
end

function Task.defer<T...>(functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/task").defer(functionOrThread, ...)
	end

	error(`Out of reach`)
end

function Task.delay<T...>(duration: number, functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/task").delay(duration, functionOrThread, ...)
	end

	error(`Out of reach`)
end

function Task.spawn<T...>(functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/task").spawn(functionOrThread, ...)
	end

	error(`Out of reach`)
end

function Task.wait(duration: number?): number
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/task").wait(duration)
	end

	error(`Out of reach`)
end

export type OS = "linux" | "macos" | "windows"

return Task
