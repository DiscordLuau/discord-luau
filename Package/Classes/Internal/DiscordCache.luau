local Construct = require("../../Utils/Construct")

--[=[
	@class Internal.DiscordCache

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordCache = {}

DiscordCache.Prototype = {}
DiscordCache.Interface = {}

DiscordCache.Prototype.type = "DiscordCache"

function DiscordCache.Prototype.setData(self: DiscordCache, uuid: string, data: any)
	self.cache[uuid] = data
end

function DiscordCache.Prototype.getData(self: DiscordCache, uuid: string)
	return self.cache[uuid]
end

function DiscordCache.Prototype.getDataOr(self: DiscordCache, uuid: string, callback: () -> any)
	local data = self:getData(uuid)

	if not data then
		data = callback()

		self:setData(uuid, data)
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