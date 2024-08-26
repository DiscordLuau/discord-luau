--[[
	A very hacky way to get around cyclic dependencies
]]

return function<T>(filePath: string): T
	local requireHook = require :: any

	return requireHook(filePath)
end
