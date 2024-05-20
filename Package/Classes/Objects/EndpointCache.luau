local Task = require("../../Std/Task")

local Construct = require("../../Utils/Construct")

--[=[
	@class Objects.EndpointCache

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local EndpointCache = {}

EndpointCache.Prototype = {}
EndpointCache.Interface = {}

EndpointCache.Prototype.type = "EndpointCache"

function EndpointCache.Prototype.setExpiry(self: EndpointCache, seconds: number)
	self.expiry = seconds
end

function EndpointCache.Prototype.set(self: EndpointCache, value: any)
	self.data = value

	if self.expiryThread then
		Task.cancel(self.expiryThread)
	end

	self.expiryThread = Task.spawn(function()
		Task.wait(self.expiry)

		self.data = nil
		self.expiryThread = nil
	end)
end

function EndpointCache.Prototype.get(self: EndpointCache)
	return self.data
end

function EndpointCache.Interface.new(expiryTime: number?)
	return Construct({
		expiry = expiryTime or 5
	}, EndpointCache.Prototype)
end

export type EndpointCache = typeof(EndpointCache.Prototype) & {
	expiry: number,

	data: any?,
	expiryThread: thread?
}

return EndpointCache.Interface