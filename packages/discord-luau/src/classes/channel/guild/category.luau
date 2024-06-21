local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseDiscordChannel = require("../base")

local CacheType = require("@enums/cacheType")

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

		return construct(channelStruct, GuildCategoryChannel.Prototype)
	end)

	return (extend(channelObject, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildCategoryChannel
end

export type GuildCategoryChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildCategoryChannel.Prototype) & {
	discordClient: any,
}

return GuildCategoryChannel.Interface
