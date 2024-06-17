local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildThread = require("@Objects/BaseGuildThread")

local CacheType = require("@Enums/CacheType")

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

		return Construct(channelStruct, GuildAnnouncementThreadChannel.Prototype)
	end)

	return (Extend(self, BaseGuildThread.new(discordClient, channelData)) :: unknown) :: GuildAnnouncementThreadChannel
end

export type GuildAnnouncementThreadChannel =
	BaseGuildThread.BaseGuildThread
	& typeof(GuildAnnouncementThreadChannel.Prototype)
	& {
		discordClient: any,
	}

return GuildAnnouncementThreadChannel.Interface
