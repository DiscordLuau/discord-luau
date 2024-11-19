--[=[
    @class Std.Net
]=]

local Net = {}
local LuneNet = require("@lune/net")

export type WebSocket = LuneNet.WebSocket
export type FetchResponse = LuneNet.FetchResponse
export type FetchParams = LuneNet.FetchParams

setmetatable(Net, { __index = LuneNet })

return Net
