--[=[
    @class Std.Net
]=]

local Net = {}
local LuneNet = require("@lune/net")

export type WebSocket = LuneNet.WebSocket

setmetatable(Net, { __index = LuneNet })

return Net
