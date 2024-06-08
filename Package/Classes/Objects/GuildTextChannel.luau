local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildTextChannel = require("@Objects/BaseGuildTextChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildTextChannel

	Represents the implementation of a Discord Text channel.

	=@inherit Objects.BaseGuildTextChannel
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

		return Construct(channelStruct, GuildTextChannel.Prototype)
	end)

	return (Extend(self, BaseGuildTextChannel.new(discordClient, channelData)) :: unknown) :: GuildTextChannel
end

export type GuildTextChannel = BaseGuildTextChannel.BaseGuildTextChannel & typeof(GuildTextChannel.Prototype) & {
	discordClient: any,
}

return GuildTextChannel.Interface
