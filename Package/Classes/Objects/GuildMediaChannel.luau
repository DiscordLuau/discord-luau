local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseDiscordChannel = require("@Objects/BaseDiscordChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildMediaChannel

	Represents the implementation of a Discord Media channel.

	=@inherit Objects.BaseDiscordChannel
]=]
local GuildMediaChannel = {}

GuildMediaChannel.Prototype = {}
GuildMediaChannel.Interface = {}

GuildMediaChannel.Prototype.type = "GuildMediaChannel"

function GuildMediaChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient,
		}

		return Construct(channelStruct, GuildMediaChannel.Prototype)
	end)

	self.defaultForumLayout = channelData.defaultForumLayout

	return (Extend(self, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildMediaChannel
end

export type GuildMediaChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildMediaChannel.Prototype) & {
	discordClient: any,

	defaultForumLayout: number,
}

return GuildMediaChannel.Interface
