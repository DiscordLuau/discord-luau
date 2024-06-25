local construct = require("@util/construct")

--[=[
	@class Objects.DiscordCache

	The `DiscordCache` class provides a caching mechanism for storing and retrieving data associated with Discord objects.
]=]

--[=[
	@prop cache { [string]: any },
	@within Objects.DiscordCache
]=]

local DiscordCache = {}

DiscordCache.Prototype = {}
DiscordCache.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordCache
	@readonly

	The type of the DiscordCache. Default is "DiscordCache".
]=]
DiscordCache.Prototype.type = "DiscordCache"

--[=[
	Sets data in the cache.

	@param cacheType string -- The type of the cache.
	@param uuid string -- The unique identifier for the cached data.
	@param data any -- The data to be cached.
	@method setData
	@within Objects.DiscordCache
]=]
function DiscordCache.Prototype.setData(self: DiscordCache, cacheType: string, uuid: string, data: any)
	self.cache[`{cacheType}-{uuid}`] = data
end

--[=[
	Gets data from the cache.

	@param cacheType string -- The type of the cache.
	@param uuid string -- The unique identifier for the cached data.
	@return any -- The cached data, or `nil` if not found.
	@method getData
	@within Objects.DiscordCache
]=]
function DiscordCache.Prototype.getData(self: DiscordCache, cacheType: string, uuid: string)
	return self.cache[`{cacheType}-{uuid}`]
end

--[=[
	Gets data from the cache, or calls a callback to generate and cache the data if not found.

	@param cacheType string -- The type of the cache.
	@param uuid string -- The unique identifier for the cached data.
	@param callback function -- The callback function to generate the data if not found in the cache.
	@return any -- The cached or newly generated data.
	@method getDataOr
	@within Objects.DiscordCache
]=]
function DiscordCache.Prototype.getDataOr(self: DiscordCache, cacheType: string, uuid: string, callback: () -> any)
	local data = self:getData(cacheType, uuid)

	if not data then
		data = callback()

		self:setData(cacheType, uuid, data)
	end

	return data
end

--[=[
	Creates a new DiscordCache instance.

	@function new
	@return DiscordCache
	@within Objects.DiscordCache
]=]
function DiscordCache.Interface.new()
	return construct({
		cache = {},
	}, DiscordCache.Prototype)
end

export type DiscordCache = typeof(DiscordCache.Prototype) & {
	cache: { [string]: any },
}

return DiscordCache.Interface
