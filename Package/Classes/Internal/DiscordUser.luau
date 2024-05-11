local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Internal.DiscordUser

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordUser = {}

DiscordUser.Prototype = {}
DiscordUser.Interface = {}

DiscordUser.Prototype.type = "DiscordUser"

function DiscordUser.Interface.new(discordClient: any, partialUserData: {
	username: string?,
	flags: number?,
	mfaEnabled: boolean?,
	avatar: string?,
	id: string,
	bot: boolean?,
	verified: boolean?,
	discriminator: string?
})	
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordUser, partialUserData.id, function()
		return Construct({
			id = partialUserData.id,
	
			discordClient = discordClient
		}, DiscordUser.Prototype)
	end)

	if partialUserData then
		for index, value in partialUserData do
			self[index] = value
		end
	end

	return self
end

export type DiscordUser = typeof(DiscordUser.Prototype) & {
	username: string?,
	flags: number?,
	mfaEnabled: boolean?,
	avatar: string?,
	id: string,
	bot: boolean?,
	verified: boolean?,
	discriminator: string?
}

return DiscordUser.Interface