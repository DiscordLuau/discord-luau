local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Objects.DiscordEmoji

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordEmoji = {}

DiscordEmoji.Prototype = {}
DiscordEmoji.Interface = {}

DiscordEmoji.Prototype.type = "DiscordEmoji"

function DiscordEmoji.Interface.new(discordClient: any, emojiData: {
	id: string,
	name: string,
	roles: { string },
	requireColons: boolean,
	managed: boolean,
	animated: boolean,
	avaliable: boolean
})
	return discordClient.discordCache:getDataOr(CacheType.DiscordEmoji, emojiData.id, function()
		local emojiStruct = {
			discordClient = discordClient
		}

		for index, value in emojiData do
			emojiStruct[index] = value
		end

		return Construct(emojiStruct, DiscordEmoji.Prototype)
	end)
end

export type DiscordEmoji = typeof(DiscordEmoji.Prototype) & {
	id: string,
	name: string,
	roles: { string },
	requireColons: boolean,
	managed: boolean,
	animated: boolean,
	avaliable: boolean
}

return DiscordEmoji.Interface