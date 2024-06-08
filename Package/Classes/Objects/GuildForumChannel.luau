local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseDiscordChannel = require("@Objects/BaseDiscordChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildForumChannel

	Represents the implementation of a Discord Forum channel.

	=@inherit Objects.BaseDiscordChannel
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

		return Construct(channelStruct, GuildForumChannel.Prototype)
	end)

	self.defaultSortOrder = channelData.defaultSortOrder

	return (Extend(self, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildForumChannel
end

export type GuildForumChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildForumChannel.Prototype) & {
	discordClient: any,

	defaultSortOrder: number,
}

return GuildForumChannel.Interface
