local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseDiscordChannel = require("@Objects/BaseDiscordChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildCategoryChannel

	Represents the implementation of a Discord Category channel.

	@tag inherit Objects.BaseDiscordChannel
]=]
local GuildCategoryChannel = {}

GuildCategoryChannel.Prototype = {}
GuildCategoryChannel.Interface = {}

GuildCategoryChannel.Prototype.type = "GuildCategoryChannel"

function GuildCategoryChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	local channelObject = discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient,
		}

		return Construct(channelStruct, GuildCategoryChannel.Prototype)
	end)

	return (Extend(channelObject, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildCategoryChannel
end

export type GuildCategoryChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildCategoryChannel.Prototype) & {
	discordClient: any,
}

return GuildCategoryChannel.Interface
