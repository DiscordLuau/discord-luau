local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseDiscordChannel = require("BaseDiscordChannel")

--[=[
	@class Objects.GuildForumChannel

	Represents the implementation of a Discord Forum channel.

	=@inherit Objects.BaseDiscordChannel
]=]
local GuildForumChannel = {}

GuildForumChannel.Prototype = {}
GuildForumChannel.Interface = {}

GuildForumChannel.Prototype.type = "GuildForumChannel"

function GuildForumChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildForumChannel.Prototype)

	return (Extend(channelObject, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildForumChannel
end

export type GuildForumChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildForumChannel.Prototype) & {
	discordClient: any,
}

return GuildForumChannel.Interface
