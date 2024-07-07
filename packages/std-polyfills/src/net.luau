--[=[
    @class Std.Net
]=]

local Net = {}

setmetatable(Net, { __index = require("@lune/net") })

return Net
