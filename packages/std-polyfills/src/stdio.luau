--[=[
    @class Std.stdio
]=]

local StdIO = {}

setmetatable(StdIO, { __index = require("@lune/stdio") })

return StdIO
