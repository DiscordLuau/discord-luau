--[=[
    @class Std.Net
]=]

local Net = {}
local LuneNet = require("@lune/net")

export type WebSocket = LuneNet.WebSocket
export type FetchResponse = LuneNet.FetchResponse

setmetatable(Net, { __index = LuneNet })

return Net
