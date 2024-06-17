local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildVoiceChannel = require("@Objects/BaseGuildVoiceChannel")

local CacheType = require("@Enums/CacheType")

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

		return Construct(channelStruct, GuildVoiceChannel.Prototype)
	end)

	return (Extend(self, BaseGuildVoiceChannel.new(discordClient, channelData)) :: unknown) :: GuildVoiceChannel
end

export type GuildVoiceChannel = BaseGuildVoiceChannel.BaseGuildVoiceChannel & typeof(GuildVoiceChannel.Prototype) & {
	discordClient: any,
}

return GuildVoiceChannel.Interface
