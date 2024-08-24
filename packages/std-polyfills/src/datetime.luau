--[=[
    @class Std.DateTime
]=]

local DateTime = {}
local LuneDateTime = require("@lune/datetime")

export type DateTime = LuneDateTime.DateTime

setmetatable(DateTime, { __index = LuneDateTime })

return DateTime
