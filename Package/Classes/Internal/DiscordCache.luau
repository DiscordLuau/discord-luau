local Construct = require("../../Utils/Construct")

--[=[
	@class Internal.DiscordCache

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordCache = {}

DiscordCache.Prototype = {}
DiscordCache.Interface = {}

DiscordCache.Prototype.type = "DiscordCache"

function DiscordCache.Prototype.setData(self: DiscordCache, cacheType: string, uuid: string, data: any)
	self.cache[`{cacheType}-{uuid}`] = data
end

function DiscordCache.Prototype.getData(self: DiscordCache, cacheType: string, uuid: string)
	return self.cache[`{cacheType}-{uuid}`]
end

function DiscordCache.Prototype.getDataOr(self: DiscordCache, cacheType: string, uuid: string, callback: () -> any)
	local data = self:getData(cacheType, uuid)

	if not data then
		data = callback()

		self:setData(cacheType, uuid, data)
	end

	return data
end

function DiscordCache.Interface.new()
	return Construct({
		cache = { } :: { [number]: any }
	}, DiscordCache.Prototype)
end

export type DiscordCache = typeof(DiscordCache.Interface.new())

return DiscordCache.Interface