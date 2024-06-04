local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseGuildThread = require("BaseGuildThread")

--[=[
	@class Objects.GuildPrivateThreadChannel

	Represents the implementation of a Discord Private Thread channel.

	=@inherit Objects.BaseGuildThread
]=]
local GuildPrivateThreadChannel = {}

GuildPrivateThreadChannel.Prototype = {}
GuildPrivateThreadChannel.Interface = {}

GuildPrivateThreadChannel.Prototype.type = "GuildPrivateThreadChannel"

function GuildPrivateThreadChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildPrivateThreadChannel.Prototype)

	return (
		Extend(channelObject, BaseGuildThread.new(discordClient, channelData)) :: unknown
	) :: GuildPrivateThreadChannel
end

export type GuildPrivateThreadChannel = BaseGuildThread.BaseGuildThread & typeof(GuildPrivateThreadChannel.Prototype) & {
	discordClient: any,
}

return GuildPrivateThreadChannel.Interface
