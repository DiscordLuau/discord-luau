local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildThread = require("@Objects/BaseGuildThread")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildPublicThreadChannel

	Represents the implementation of a Discord Public Thread channel.

	@tag inherit Objects.BaseGuildThread
]=]
local GuildPublicThreadChannel = {}

GuildPublicThreadChannel.Prototype = {}
GuildPublicThreadChannel.Interface = {}

GuildPublicThreadChannel.Prototype.type = "GuildPublicThreadChannel"

function GuildPublicThreadChannel.Interface.new(
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

		return Construct(channelStruct, GuildPublicThreadChannel.Prototype)
	end)

	return (Extend(self, BaseGuildThread.new(discordClient, channelData)) :: unknown) :: GuildPublicThreadChannel
end

export type GuildPublicThreadChannel = BaseGuildThread.BaseGuildThread & typeof(GuildPublicThreadChannel.Prototype) & {
	discordClient: any,
}

return GuildPublicThreadChannel.Interface
