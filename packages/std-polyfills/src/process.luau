--[=[
    @class Std.Process
]=]

local Process = {}

setmetatable(Process, { __index = require("@lune/process") })

return Process
