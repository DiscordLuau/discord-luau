local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseDiscordChannel = require("BaseDiscordChannel")

--[=[
	@class Objects.GuildMediaChannel
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
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildMediaChannel.Prototype)

	return (Extend(channelObject, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildMediaChannel
end

export type GuildMediaChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildMediaChannel.Prototype) & {
	discordClient: any,
}

return GuildMediaChannel.Interface
