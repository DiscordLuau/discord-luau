local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Internal.DiscordMessage

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordMessage = {}

DiscordMessage.Prototype = {}
DiscordMessage.Interface = {}

DiscordMessage.Prototype.type = "DiscordMessage"

function DiscordMessage.Interface.new(discordClient: any, messageData: {
	id: string,
	[any]: any,
})
	return discordClient.discordCache:getDataOr(CacheType.DiscordMessage, messageData.id, function()
		local messageStruct = {
			discordClient = discordClient
		}

		for index, value in messageData do
			messageStruct[index] = value
		end

		return Construct(messageStruct, DiscordMessage.Prototype)
	end)
end

export type DiscordMessage = typeof(DiscordMessage.Interface.new())

return DiscordMessage.Interface