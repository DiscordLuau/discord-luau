local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

local DiscordUser = require("DiscordUser")

--[=[
	@class Internal.DiscordChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordChannel = {}

DiscordChannel.Prototype = {}
DiscordChannel.Interface = {}

DiscordChannel.Prototype.type = "DiscordChannel"

function DiscordChannel.Interface.new(discordClient: any, channelData: {
	id: string,
	recipients: { any },
	[any]: any,
})
	return discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient
		}

		for index, value in channelData.recipients do
			channelData.recipients[index] = DiscordUser.new(discordClient, value)
		end

		for index, value in channelData do
			channelStruct[index] = value
		end

		return Construct(channelStruct, DiscordChannel.Prototype)
	end)
end

export type DiscordChannel = typeof(DiscordChannel.Interface.new())

return DiscordChannel.Interface