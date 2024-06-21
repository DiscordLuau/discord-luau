local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseGuildTextChannel = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildDirectoryChannel

	Represents the implementation of a Discord Directory channel.

	@tag inherit Objects.BaseGuildTextChannel
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

		return construct(channelStruct, GuildDirectoryChannel.Prototype)
	end)

	return (extend(self, BaseGuildTextChannel.new(discordClient, channelData)) :: unknown) :: GuildDirectoryChannel
end

export type GuildDirectoryChannel = BaseGuildTextChannel.BaseGuildTextChannel & typeof(GuildDirectoryChannel.Prototype) & {
	discordClient: any,
}

return GuildDirectoryChannel.Interface
