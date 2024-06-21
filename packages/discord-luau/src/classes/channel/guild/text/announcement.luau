local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseGuildTextChannel = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildAnnouncementChannel

	Represents the implementation of a Discord Announcement channel.

	@tag inherit Objects.BaseGuildTextChannel
]=]
local GuildAnnouncementChannel = {}

GuildAnnouncementChannel.Prototype = {}
GuildAnnouncementChannel.Interface = {}

GuildAnnouncementChannel.Prototype.type = "GuildAnnouncementChannel"

function GuildAnnouncementChannel.Interface.new(
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

		return construct(channelStruct, GuildAnnouncementChannel.Prototype)
	end)

	return (extend(self, BaseGuildTextChannel.new(discordClient, channelData)) :: unknown) :: GuildAnnouncementChannel
end

export type GuildAnnouncementChannel =
	BaseGuildTextChannel.BaseGuildTextChannel
	& typeof(GuildAnnouncementChannel.Prototype)
	& {
		discordClient: any,
	}

return GuildAnnouncementChannel.Interface
