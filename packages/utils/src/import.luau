--[[
	A very hacky way to get around cyclic dependencies..

	we don't talk about it.
]]

return function<T>(filePath: string): T
	local requireHook = require :: any

	return requireHook(filePath)
end
