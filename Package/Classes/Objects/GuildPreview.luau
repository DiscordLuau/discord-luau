local Construct = require("@Utils/Construct")

local DiscordEmoji = require("@Objects/DiscordEmoji")
local DiscordSticker = require("@Objects/DiscordSticker")

local CacheType = require("@Enums/CacheType")

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
	--[=[
		@prop id string
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop name string
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop icon string?
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop splash string?
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop discoverySplash string?
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop emojis { Objects.DiscordEmoji }
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop features { string }
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop approximateMemberCount number
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop approximatePresenceCount number
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop description string?
		@within Objects.GuildPreview
	]=]

	--[=[
		@prop stickers { Objects.DiscordSticker }
		@within Objects.GuildPreview
	]=]

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
