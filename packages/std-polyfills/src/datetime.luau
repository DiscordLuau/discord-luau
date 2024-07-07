--[=[
    @class Std.DateTime
]=]

local DateTime = {}

setmetatable(DateTime, { __index = require("@lune/datetime") })

return DateTime
