local Construct = require("../../Utils/Construct")

local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local CacheType = require("../../Enums/CacheType")

local Future = require("../../Vendor/Future")

--[=[
	@class Internal.DiscordInvite

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordInvite = {}

DiscordInvite.Prototype = {}
DiscordInvite.Interface = {}

DiscordInvite.Prototype.type = "DiscordInvite"

function DiscordInvite.Prototype.deleteAsync(self: DiscordInvite)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotDeleteInvite, self.code), { }):await()
	end)
end

function DiscordInvite.Interface.new(discordClient: any, inviteData: {
	code: string,
})
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordInvite, inviteData.code, function()
		return Construct({
			discordClient = discordClient
		}, DiscordInvite.Prototype)
	end)

	if inviteData then
		for index, value in inviteData do
			self[index] = value
		end
	end

	return self
end

export type DiscordInvite = typeof(DiscordInvite.Interface.new())

return DiscordInvite.Interface