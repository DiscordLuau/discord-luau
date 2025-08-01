--[=[
	@class StdPolyfills.task
]=]

local runtime = require("@self/runtime")

local task = {}

--[=[
	@within StdPolyfills.task

	Stops a currently scheduled thread from resuming.
]=]
function task.cancel(thread: thread)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/task").cancel(thread)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.task

	Defers a thread or function to run at the end of the current task queue.
]=]
function task.defer<T...>(functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/task").defer(functionOrThread, ...)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.task

	Delays a thread or function to run after duration seconds.
]=]
function task.delay<T...>(duration: number, functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/task").delay(duration, functionOrThread, ...)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.task
	
	Instantly runs a thread or function.

	If the spawned task yields, the thread that spawned the task will resume, letting the spawned task run in the
		background.
]=]
function task.spawn<T...>(functionOrThread: thread | (T...) -> ...any, ...: T...): thread
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/task").spawn(functionOrThread, ...)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.task

	Waits for at least the given amount of time.

	The minimum wait time possible when using task.wait is limited by the underlying OS sleep implementation. For most
		systems this means task.wait is accurate down to about 5 milliseconds or less.
]=]
function task.wait(duration: number?): number
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/task").wait(duration)
	end

	error(`Out of reach`)
end

export type OS = "linux" | "macos" | "windows"

return task
