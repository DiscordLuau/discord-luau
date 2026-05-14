--[=[
	@function Utilities.coroutineRun
	@within Utilities

	Creates a thread, resumes that thread - and handles errors if this resumed thread fails.

	Will return the thread spawned.

	@return thread
]=]
return function(callback: () -> (), ...)
	local thread = coroutine.create(callback)
	local success, errorMessage = coroutine.resume(thread, ...)

	if not success then
		error(errorMessage, 0)
	end

	return thread
end
