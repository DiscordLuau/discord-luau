-- Internal cache keys, cache registers key in the following format `{CacheType}-{Id}`, though this is not strict,
-- 		so some cache's may differ from this format.

local CacheType = {
	Application = "Application",
	GuildPreview = "GuildPreview",
	DiscordEmoji = "DiscordEmoji",
	DiscordMember = "DiscordMember",
	DiscordSticker = "DiscordSticker",
	DiscordGuild = "DiscordGuild",
	DiscordIntegration = "DiscordIntegration",
	DiscordInvite = "DiscordInvite",
	DiscordGuildRole = "DiscordGuildRole",
	AutoModeration = "AutoModeration",
	DiscordUser = "DiscordUser",
	DiscordChannel = "DiscordChannel",
	DiscordMessage = "DiscordMessage",
}

export type CacheType =
	"Application"
	| "GuildPreview"
	| "DiscordMember"
	| "DiscordEmoji"
	| "DiscordSticker"
	| "AutoModeration"
	| "DiscordIntegration"
	| "DiscordGuild"
	| "DiscordInvite"
	| "DiscordGuildRole"
	| "DiscordUser"
	| "DiscordChannel"
	| "DiscordMessage"

return CacheType
