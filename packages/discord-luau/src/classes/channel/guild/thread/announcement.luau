local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseGuildThread = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildAnnouncementThreadChannel

	Represents the implementation of a Discord Announcement thread channel.

	@tag inherit Objects.BaseGuildThread
]=]
local GuildAnnouncementThreadChannel = {}

GuildAnnouncementThreadChannel.Prototype = {}
GuildAnnouncementThreadChannel.Interface = {}

GuildAnnouncementThreadChannel.Prototype.type = "GuildAnnouncementThreadChannel"

function GuildAnnouncementThreadChannel.Interface.new(
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

		return construct(channelStruct, GuildAnnouncementThreadChannel.Prototype)
	end)

	return (extend(self, BaseGuildThread.new(discordClient, channelData)) :: unknown) :: GuildAnnouncementThreadChannel
end

export type GuildAnnouncementThreadChannel =
	BaseGuildThread.BaseGuildThread
	& typeof(GuildAnnouncementThreadChannel.Prototype)
	& {
		discordClient: any,
	}

return GuildAnnouncementThreadChannel.Interface
