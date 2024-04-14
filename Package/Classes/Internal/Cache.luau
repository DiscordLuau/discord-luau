local Task = require("@lune/task")

local Construct = require("../../Utils/Construct")

local Cache = {}

Cache.Type = "Cache"

Cache.Prototype = {}
Cache.Interface = {}

function Cache.Prototype.setExpiry(self: Cache, seconds: number)
	self.Expiry = seconds
end

function Cache.Prototype.set(self: Cache, value: any)
	self.Data = value

	if self.ExpiryThread then
		Task.cancel(self.ExpiryThread)
	end

	self.ExpiryThread = Task.spawn(function()
		Task.wait(self.Expiry)

		self.Data = nil
		self.ExpiryThread = nil
	end)
end

function Cache.Prototype.get(self: Cache)
	return self.Data
end

function Cache.Interface.new(expiryTime: number?)
	return Construct({
		Expiry = expiryTime or 5
	}, Cache.Prototype)
end

export type Cache = typeof(Cache.Interface.new())

return Cache.Interface