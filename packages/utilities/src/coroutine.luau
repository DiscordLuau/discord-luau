local co = coroutine

local coroutine = {}

function coroutine.run(func: () -> (), ...)
	local thread = co.create(func)
	local status, result = co.resume(thread, ...)

	if not status then
		error(result)
	end

	return thread
end

return setmetatable(coroutine, { __index = co })
