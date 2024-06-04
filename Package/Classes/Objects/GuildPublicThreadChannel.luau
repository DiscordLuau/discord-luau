local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseGuildThread = require("BaseGuildThread")

--[=[
	@class Objects.GuildPublicThreadChannel

	Represents the implementation of a Discord Public Thread channel.

	=@inherit Objects.BaseGuildThread
]=]
local GuildPublicThreadChannel = {}

GuildPublicThreadChannel.Prototype = {}
GuildPublicThreadChannel.Interface = {}

GuildPublicThreadChannel.Prototype.type = "GuildPublicThreadChannel"

function GuildPublicThreadChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildPublicThreadChannel.Prototype)

	return (
		Extend(channelObject, BaseGuildThread.new(discordClient, channelData)) :: unknown
	) :: GuildPublicThreadChannel
end

export type GuildPublicThreadChannel = BaseGuildThread.BaseGuildThread & typeof(GuildPublicThreadChannel.Prototype) & {
	discordClient: any,
}

return GuildPublicThreadChannel.Interface
