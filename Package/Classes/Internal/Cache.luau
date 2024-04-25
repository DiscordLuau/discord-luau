local Task = require("../../Std/Task")

local Construct = require("../../Utils/Construct")

--[=[
	@class Internal.Cache

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local Cache = {}

Cache.Prototype = {}
Cache.Interface = {}

Cache.Prototype.type = "Cache"

function Cache.Prototype.setExpiry(self: Cache, seconds: number)
	self.expiry = seconds
end

function Cache.Prototype.set(self: Cache, value: any)
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

function Cache.Prototype.get(self: Cache)
	return self.data
end

function Cache.Interface.new(expiryTime: number?)
	return Construct({
		expiry = expiryTime or 5
	}, Cache.Prototype)
end

export type Cache = typeof(Cache.Interface.new())

return Cache.Interface