local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseGuildThread = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildPrivateThreadChannel

	Represents the implementation of a Discord Private Thread channel.

	@tag inherit Objects.BaseGuildThread
]=]
local GuildPrivateThreadChannel = {}

GuildPrivateThreadChannel.Prototype = {}
GuildPrivateThreadChannel.Interface = {}

GuildPrivateThreadChannel.Prototype.type = "GuildPrivateThreadChannel"

function GuildPrivateThreadChannel.Interface.new(
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

		return construct(channelStruct, GuildPrivateThreadChannel.Prototype)
	end)

	return (extend(self, BaseGuildThread.new(discordClient, channelData)) :: unknown) :: GuildPrivateThreadChannel
end

export type GuildPrivateThreadChannel = BaseGuildThread.BaseGuildThread & typeof(GuildPrivateThreadChannel.Prototype) & {
	discordClient: any,
}

return GuildPrivateThreadChannel.Interface
