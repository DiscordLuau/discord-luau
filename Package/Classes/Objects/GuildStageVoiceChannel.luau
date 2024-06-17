local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseGuildVoiceChannel = require("@Objects/BaseGuildVoiceChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildStageVoiceChannel

	Represents the implementation of a Discord Stage channel.
	
	@tag inherit Objects.BaseGuildVoiceChannel
]=]
local GuildStageVoiceChannel = {}

GuildStageVoiceChannel.Prototype = {}
GuildStageVoiceChannel.Interface = {}

GuildStageVoiceChannel.Prototype.type = "GuildStageVoiceChannel"

function GuildStageVoiceChannel.Interface.new(
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

		return Construct(channelStruct, GuildStageVoiceChannel.Prototype)
	end)

	return (Extend(self, BaseGuildVoiceChannel.new(discordClient, channelData)) :: unknown) :: GuildStageVoiceChannel
end

export type GuildStageVoiceChannel =
	BaseGuildVoiceChannel.BaseGuildVoiceChannel
	& typeof(GuildStageVoiceChannel.Prototype)
	& {
		discordClient: any,
	}

return GuildStageVoiceChannel.Interface
