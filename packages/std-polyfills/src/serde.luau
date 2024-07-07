--[=[
    @class Std.Serde
]=]

local Serde = {}

setmetatable(Serde, { __index = require("@lune/serde") })

return Serde
