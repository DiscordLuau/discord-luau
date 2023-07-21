local Task = require("@lune/task")

local Cache = {}

Cache.Type = "Cache"

Cache.Internal = {}
Cache.Prototype = {
	Internal = Cache.Internal,
}
Cache.Interface = {
	Internal = Cache.Internal,
}

function Cache.Prototype:SetExpiry(seconds)
	self.Expiry = seconds
end

function Cache.Prototype:Set(value)
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

function Cache.Prototype:Get()
	return self.Data
end

function Cache.Prototype:ToString()
	return `{Cache.Type}<"{self.Data}">`
end

function Cache.Interface.new(expiryTime)
	return setmetatable({
		Expiry = expiryTime or 5
	}, {
		__index = Cache.Prototype,
		__type = Cache.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return Cache.Interface
