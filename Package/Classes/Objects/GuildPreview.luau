local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

local DiscordEmoji = require("DiscordEmoji")
local DiscordSticker = require("DiscordSticker")

--[=[
	@class Objects.GuildPreview

	GuildPreview represents a user on Discord, encapsulating user data such as username, avatar, and various flags.
]=]
local GuildPreview = {}

GuildPreview.Prototype = {}
GuildPreview.Interface = {}

GuildPreview.Prototype.type = "GuildPreview"

--[=[
	Creates a new instance of GuildPreview.
	
	@function new
	@param discordClient any
	@param guildPreview { ... }
	@within Objects.GuildPreview
	@return GuildPreview
]=]
function GuildPreview.Interface.new(
	discordClient: any,
	guildPreview: {
		id: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.GuildPreview, guildPreview.id, function()
		return Construct({
			id = guildPreview.id,

			discordClient = discordClient,
		}, GuildPreview.Prototype)
	end)

	for index, value in guildPreview do
		self[index] = value
	end

	return self
end

export type GuildPreview = typeof(GuildPreview.Prototype) & {
	id: string,
	name: string,
	icon: string?,
	splash: string?,
	discoverySplash: string?,
	emojis: { DiscordEmoji.DiscordEmoji },
	features: { string },
	approximateMemberCount: number,
	approximatePresenceCount: number,
	description: string?,
	stickers: { DiscordSticker.DiscordSticker },
}

return GuildPreview.Interface
