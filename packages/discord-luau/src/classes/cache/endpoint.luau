local Task = require("@std/task")

local construct = require("@util/construct")

--[=[
	@class Objects.EndpointCache

	EndpointCache is a caching mechanism designed to store data temporarily with an expiration time.
]=]
local EndpointCache = {}

EndpointCache.Prototype = {}
EndpointCache.Interface = {}

EndpointCache.Prototype.type = "EndpointCache"

--[=[
	Sets the expiry time for the cache.
	
	@method setExpiry
	@within Objects.EndpointCache
	@param seconds number -- The number of seconds before the cached data expires.
]=]
function EndpointCache.Prototype.setExpiry(self: EndpointCache, seconds: number)
	self.expiry = seconds
end

--[=[
	Sets the value in the cache and starts the expiry timer.
	
	@method set
	@within Objects.EndpointCache
	@param value any -- The value to be cached.
]=]
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

--[=[
	Gets the current value from the cache.
	
	@method get
	@within Objects.EndpointCache
	@return any -- The cached value, or nil if the cache is empty or expired.
]=]
function EndpointCache.Prototype.get(self: EndpointCache)
	return self.data
end

--[=[
	
	Creates a new instance of EndpointCache.
	
	@function new
	@param expiryTime number? -- (Optional) The expiry time for the cache in seconds. Defaults to 5 seconds if not provided.
	@within Objects.EndpointCache
	@return EndpointCache -- A new instance of EndpointCache.
]=]
function EndpointCache.Interface.new(expiryTime: number?)
	return construct({
		--[=[
			@prop expiry number
			@within Objects.EndpointCache
		]=]

		expiry = expiryTime or 5,
	}, EndpointCache.Prototype)
end

export type EndpointCache = typeof(EndpointCache.Prototype) & {
	expiry: number,

	data: any?,
	expiryThread: thread?,
}

return EndpointCache.Interface
