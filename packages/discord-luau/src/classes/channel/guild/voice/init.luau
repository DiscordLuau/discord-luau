local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseGuildVoiceChannel = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildVoiceChannel

	Represents the implementation of a Discord Voice channel.

	@tag inherit Objects.BaseGuildVoiceChannel
]=]
local GuildVoiceChannel = {}

GuildVoiceChannel.Prototype = {}
GuildVoiceChannel.Interface = {}

GuildVoiceChannel.Prototype.type = "GuildVoiceChannel"

function GuildVoiceChannel.Interface.new(
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

		return construct(channelStruct, GuildVoiceChannel.Prototype)
	end)

	return (extend(self, BaseGuildVoiceChannel.new(discordClient, channelData)) :: unknown) :: GuildVoiceChannel
end

export type GuildVoiceChannel = BaseGuildVoiceChannel.BaseGuildVoiceChannel & typeof(GuildVoiceChannel.Prototype) & {
	discordClient: any,
}

return GuildVoiceChannel.Interface
