local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseDiscordChannel = require("../base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildForumChannel

	Represents the implementation of a Discord Forum channel.

	@tag inherit Objects.BaseDiscordChannel
]=]

--[=[
	@prop defaultSortOrder number
	@within Objects.GuildForumChannel
]=]

local GuildForumChannel = {}

GuildForumChannel.Prototype = {}
GuildForumChannel.Interface = {}

GuildForumChannel.Prototype.type = "GuildForumChannel"

function GuildForumChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient,
		}

		return construct(channelStruct, GuildForumChannel.Prototype)
	end)

	self.defaultSortOrder = channelData.defaultSortOrder

	return (extend(self, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildForumChannel
end

export type GuildForumChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildForumChannel.Prototype) & {
	discordClient: any,

	defaultSortOrder: number,
}

return GuildForumChannel.Interface
