local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildTextChannel = require("@Objects/BaseGuildTextChannel")

local CacheType = require("@Enums/CacheType")

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

		return Construct(channelStruct, GuildAnnouncementChannel.Prototype)
	end)

	return (Extend(self, BaseGuildTextChannel.new(discordClient, channelData)) :: unknown) :: GuildAnnouncementChannel
end

export type GuildAnnouncementChannel =
	BaseGuildTextChannel.BaseGuildTextChannel
	& typeof(GuildAnnouncementChannel.Prototype)
	& {
		discordClient: any,
	}

return GuildAnnouncementChannel.Interface
