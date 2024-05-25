--[[
	Imports a Standard runtime library, in this case we're using Lune - but if we wanted to hop into another Runtime..
		theoretically, we could - we'd just need to emulate the lune runtime.
]]

return setmetatable({}, {
	__index = require("@lune/datetime"),
})
