local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildThread = require("@Objects/BaseGuildThread")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildPrivateThreadChannel

	Represents the implementation of a Discord Private Thread channel.

	=@inherit Objects.BaseGuildThread
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

		return Construct(channelStruct, GuildPrivateThreadChannel.Prototype)
	end)

	return (Extend(self, BaseGuildThread.new(discordClient, channelData)) :: unknown) :: GuildPrivateThreadChannel
end

export type GuildPrivateThreadChannel = BaseGuildThread.BaseGuildThread & typeof(GuildPrivateThreadChannel.Prototype) & {
	discordClient: any,
}

return GuildPrivateThreadChannel.Interface
