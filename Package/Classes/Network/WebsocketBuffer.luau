local Construct = require("../../Utils/Construct")

local WebsocketBuffer = {}

WebsocketBuffer.Type = "WebsocketBuffer"

WebsocketBuffer.Prototype = {}
WebsocketBuffer.Interface = {}

function WebsocketBuffer.Prototype.flush(self: WebsocketBuffer)
	local data = self.Data

	self.Data = ""

	return data
end

function WebsocketBuffer.Prototype.add(self: WebsocketBuffer, data: string)
	self.Data ..= data
end

function WebsocketBuffer.Interface.new()
	return Construct({
		Data = ""
	}, WebsocketBuffer.Prototype)
end

export type WebsocketBuffer = typeof(WebsocketBuffer.Interface.new())

return WebsocketBuffer.Interface