--[[
	Cache class, responsible for storing the cache of the bot, as well as removing keys/values
	from the cache when they are no longer needed.

	each key and value has a lifetime value assigned to them, this is used to determine
	when a key/value should be removed from the cache.

	when a key/value has been updated or requested, the lifetime is reset to the current time +
	the lifetime value.
]]

local stdPolyfills = require("../lune_packages/std_polyfills")

local Cache = {}

Cache.Interface = {}
Cache.Prototype = {}

--[[
	Sets a key-value pair in the cache. This will additionally call 'createThreadLoop' to ensure
	that there's a thread available to remove expired keys/values from the cache.
]]
function Cache.Prototype.set<K, V>(self: Cache<K, V>, key: K, value: V)
	self.store[key] = value
end

--[[
	Fetches a key-value pair from the cache.
]]
function Cache.Prototype.get<K, V>(self: Cache<K, V>, key: K): V
	return self.store[key]
end

--[[
	Responsible for creating a thread loop that will remove expired keys/values from the cache.

	This thread will die when the cache is empty, which requires any further additions to the cache
	to call this function again in order to create a new thread.
]]
function Cache.Prototype.createThreadLoop<K, V>(self: Cache<K, V>)
	if self.thread then
		return
	end

	self.thread = stdPolyfills.task.spawn(function()
		while true do
			if #self.store == 0 then
				self.thread = nil

				return
			end

			stdPolyfills.task.wait(self.rate or 60)

			local now = os.clock()

			for key in self.store do
				if now > self.lifetimes[key] + self.expiry then
					self.store[key] = nil
					self.lifetimes[key] = nil
				end
			end
		end
	end)
end

--[[
	Constructor for the Cache class.
]]
function Cache.Interface.new<K, V>(expiry: number, rate: number?): Cache<K, V>
	-- fixme: hack for luau's type system, apparently it doesn't want 'store' calling 'createThreadLoop' ?
	local self: any

	local lifetimes = {}
	local store = setmetatable({}, {
		__index = function(storeSelf, key: K)
			rawset(lifetimes, key, os.clock())

			return rawget(storeSelf, key)
		end,
		__newindex = function(storeSelf, key: K, value: V)
			rawset(lifetimes, key, os.clock())
			rawset(storeSelf, key, value)

			self:createThreadLoop()
		end,
	}) :: any

	self = setmetatable(
		{
			store = store :: { [K]: V },
			lifetimes = lifetimes,

			expiry = expiry,
			rate = rate,
		} :: Cache<K, V>,
		{
			__index = Cache.Prototype,
		}
	)

	return self :: Cache<K, V>
end

export type Cache<K, V> = typeof(Cache.Prototype) & {
	store: { [K]: V },
	lifetimes: { [K]: number },
	expiry: number,
	rate: number?,

	thread: thread?,
}

return Cache.Interface
