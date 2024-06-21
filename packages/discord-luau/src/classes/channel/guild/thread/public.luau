local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseGuildThread = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildPublicThreadChannel

	Represents the implementation of a Discord Public Thread channel.

	@tag inherit Objects.BaseGuildThread
]=]
local GuildPublicThreadChannel = {}

GuildPublicThreadChannel.Prototype = {}
GuildPublicThreadChannel.Interface = {}

GuildPublicThreadChannel.Prototype.type = "GuildPublicThreadChannel"

function GuildPublicThreadChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient,
		}

		return construct(channelStruct, GuildPublicThreadChannel.Prototype)
	end)

	return (extend(self, BaseGuildThread.new(discordClient, channelData)) :: unknown) :: GuildPublicThreadChannel
end

export type GuildPublicThreadChannel = BaseGuildThread.BaseGuildThread & typeof(GuildPublicThreadChannel.Prototype) & {
	discordClient: any,
}

return GuildPublicThreadChannel.Interface
