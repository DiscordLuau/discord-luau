local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseGuildVoiceChannel = require("BaseGuildVoiceChannel")

--[=[
	@class Objects.GuildVoiceChannel
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
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildVoiceChannel.Prototype)

	return (Extend(channelObject, BaseGuildVoiceChannel.new(discordClient, channelData)) :: unknown) :: GuildVoiceChannel
end

export type GuildVoiceChannel = BaseGuildVoiceChannel.BaseGuildVoiceChannel & typeof(GuildVoiceChannel.Prototype) & {
	discordClient: any,
}

return GuildVoiceChannel.Interface
