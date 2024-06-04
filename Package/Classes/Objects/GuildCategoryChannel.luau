local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseDiscordChannel = require("BaseDiscordChannel")

--[=[
	@class Objects.GuildCategoryChannel

	Represents the implementation of a Discord Category channel.
]=]
local GuildCategoryChannel = {}

GuildCategoryChannel.Prototype = {}
GuildCategoryChannel.Interface = {}

GuildCategoryChannel.Prototype.type = "GuildCategoryChannel"

function GuildCategoryChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, GuildCategoryChannel.Prototype)

	return (Extend(channelObject, BaseDiscordChannel.new(discordClient, channelData)) :: unknown) :: GuildCategoryChannel
end

export type GuildCategoryChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(GuildCategoryChannel.Prototype) & {
	discordClient: any,
}

return GuildCategoryChannel.Interface
