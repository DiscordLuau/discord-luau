-- Internal cache keys, cache registers key in the following format `{CacheType}-{Id}`, though this is not strict,
-- 		so some cache's may differ from this format.

local CacheType = {
	Application = "Application",
	DiscordEmoji = "DiscordEmoji",
	DiscordGuild = "DiscordGuild",
	DiscordGuildRole = "DiscordGuildRole",
	DiscordUser = "DiscordUser",
	DiscordChannel = "DiscordChannel",
	DiscordTextChannel = "DiscordTextChannel",
	DiscordVoiceChannel = "DiscordVoiceChannel",
	DiscordAnnouncementChannel = "DiscordAnnouncementChannel",
	DiscordMessage = "DiscordMessage",
	DiscordMember = "DiscordMember",
	DiscordInvite = "DiscordInvite",
	AutoModeration = "AutoModeration",
	DiscordThreadChannel = "DiscordThreadChannel",
}

export type CacheType =
	"Application"
	| "DiscordEmoji"
	| "DiscordGuilded"
	| "DiscordGuildRole"
	| "DiscordUser"
	| "DiscordChannel"
	| "DiscordTextChannel"
	| "DiscordAnnouncementChannel"
	| "DiscordVoiceChannel"
	| "DiscordMessage"
	| "DiscordMember"
	| "DiscordInvite"
	| "AutoModeration"
	| "DiscordThreadChannel"

return CacheType
