local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseDiscordChannel = require("../base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildMediaChannel

	Represents the implementation of a Discord Media channel.

	@tag inherit Objects.BaseDiscordChannel
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
	--[=[
		@prop defaultForumLayout number
		@within Objects.GuildMediaChannel
	]=]

	local self = discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient,
		}

		return construct(channelStruct, GuildMediaChannel.Prototype)
	end)

	self.defaultForumLayout = channelData.defaultForumLayout

	return (extend(self, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildMediaChannel
end

export type GuildMediaChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildMediaChannel.Prototype) & {
	discordClient: any,

	defaultForumLayout: number,
}

return GuildMediaChannel.Interface
