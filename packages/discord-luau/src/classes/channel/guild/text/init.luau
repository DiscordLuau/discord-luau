local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseGuildTextChannel = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildTextChannel

	Represents the implementation of a Discord Text channel.

	@tag inherit Objects.BaseGuildTextChannel
]=]
local GuildTextChannel = {}

GuildTextChannel.Prototype = {}
GuildTextChannel.Interface = {}

GuildTextChannel.Prototype.type = "GuildTextChannel"

function GuildTextChannel.Interface.new(
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

		return construct(channelStruct, GuildTextChannel.Prototype)
	end)

	return (extend(self, BaseGuildTextChannel.new(discordClient, channelData)) :: unknown) :: GuildTextChannel
end

export type GuildTextChannel = BaseGuildTextChannel.BaseGuildTextChannel & typeof(GuildTextChannel.Prototype) & {
	discordClient: any,
}

return GuildTextChannel.Interface
