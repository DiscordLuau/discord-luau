local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseGuildVoiceChannel = require("BaseGuildVoiceChannel")

--[=[
	@class Objects.GuildStageVoiceChannel
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
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildStageVoiceChannel.Prototype)

	return (
		Extend(channelObject, BaseGuildVoiceChannel.new(discordClient, channelData)) :: unknown
	) :: GuildStageVoiceChannel
end

export type GuildStageVoiceChannel =
	BaseGuildVoiceChannel.BaseGuildVoiceChannel
	& typeof(GuildStageVoiceChannel.Prototype)
	& {
		discordClient: any,
	}

return GuildStageVoiceChannel.Interface
