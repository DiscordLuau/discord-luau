--[=[
	@function Utilities.coroutineRun
	@within Utilities

	Creates a thread, resumes that thread - and handles errors if this resumed thread fails.

	Will return the thread spawned.

	@return thread
]=]
return function(func: () -> (), ...)
	local thread = coroutine.create(func)
	local status, result = coroutine.resume(thread, ...)

	if not status then
		error(result)
	end

	return thread
end
