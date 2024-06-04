local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseGuildTextChannel = require("BaseGuildTextChannel")

--[=[
	@class Objects.GuildTextChannel

	Represents the implementation of a Discord Text channel.
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
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildTextChannel.Prototype)

	return (Extend(channelObject, BaseGuildTextChannel.new(discordClient, channelData)) :: unknown) :: GuildTextChannel
end

export type GuildTextChannel = BaseGuildTextChannel.BaseGuildTextChannel & typeof(GuildTextChannel.Prototype) & {
	discordClient: any,
}

return GuildTextChannel.Interface
