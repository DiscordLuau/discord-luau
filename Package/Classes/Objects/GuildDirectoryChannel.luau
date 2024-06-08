local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildTextChannel = require("@Objects/BaseGuildTextChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildDirectoryChannel

	Represents the implementation of a Discord Directory channel.

	=@inherit Objects.BaseGuildTextChannel
]=]
local GuildDirectoryChannel = {}

GuildDirectoryChannel.Prototype = {}
GuildDirectoryChannel.Interface = {}

GuildDirectoryChannel.Prototype.type = "GuildDirectoryChannel"

function GuildDirectoryChannel.Interface.new(
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

		return Construct(channelStruct, GuildDirectoryChannel.Prototype)
	end)

	return (Extend(self, BaseGuildTextChannel.new(discordClient, channelData)) :: unknown) :: GuildDirectoryChannel
end

export type GuildDirectoryChannel = BaseGuildTextChannel.BaseGuildTextChannel & typeof(GuildDirectoryChannel.Prototype) & {
	discordClient: any,
}

return GuildDirectoryChannel.Interface
