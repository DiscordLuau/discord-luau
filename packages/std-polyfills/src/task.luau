--[=[
    @class Std.Task
]=]

local Task = {}

setmetatable(Task, { __index = require("@lune/task") })

return Task
