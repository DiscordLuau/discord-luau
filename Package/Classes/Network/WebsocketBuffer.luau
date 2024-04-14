local Construct = require("../../Utils/Construct")

--[=[
	@class Internal.WebsocketBuffer

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local WebsocketBuffer = {}

WebsocketBuffer.Prototype = {}
WebsocketBuffer.Interface = {}

WebsocketBuffer.Prototype.type = "WebsocketBuffer"

function WebsocketBuffer.Prototype.flush(self: WebsocketBuffer)
	local data = self.data

	self.data = ""

	return data
end

function WebsocketBuffer.Prototype.add(self: WebsocketBuffer, data: string)
	self.data ..= data
end

function WebsocketBuffer.Interface.new()
	return Construct({
		data = ""
	}, WebsocketBuffer.Prototype)
end

export type WebsocketBuffer = typeof(WebsocketBuffer.Interface.new())

return WebsocketBuffer.Interface