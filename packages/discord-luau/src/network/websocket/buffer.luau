local construct = require("@util/construct")

--[=[
	@class Network.WebsocketBuffer

	The `WebsocketBuffer` class manages a buffer for websocket data, allowing for data to be added incrementally and flushed when needed.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to manage websocket buffering.
	:::
]=]
local WebsocketBuffer = {}

WebsocketBuffer.Prototype = {}
WebsocketBuffer.Interface = {}

WebsocketBuffer.Prototype.type = "WebsocketBuffer"

--[=[
	Flushes the buffer, returning all accumulated data and resetting the buffer.
	
	@private
	@method flush
	@param self WebsocketBuffer
	@within Network.WebsocketBuffer
	@return string
]=]
function WebsocketBuffer.Prototype.flush(self: WebsocketBuffer)
	local data = self.data

	self.data = ""

	return data
end

--[=[
	Adds data to the buffer.
	
	@private
	@method add
	@param self WebsocketBuffer
	@within Network.WebsocketBuffer
	@param data string
]=]
function WebsocketBuffer.Prototype.add(self: WebsocketBuffer, data: string)
	self.data ..= data
end

--[=[
	Creates a new instance of `WebsocketBuffer`.
	
	@private
	@function new
	@within Network.WebsocketBuffer
	@return WebsocketBuffer
]=]
function WebsocketBuffer.Interface.new()
	--[=[
		@prop data string
		@within Network.WebsocketBuffer
	]=]

	return construct({
		data = "",
	}, WebsocketBuffer.Prototype)
end

export type WebsocketBuffer = typeof(WebsocketBuffer.Prototype) & {
	data: string,
}

return WebsocketBuffer.Interface
