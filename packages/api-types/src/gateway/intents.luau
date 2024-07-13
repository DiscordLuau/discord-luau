--[[
	https://discord.com/developers/docs/topics/gateway#list-of-intents
]]

local Intents = table.freeze({
	Guilds = bit32.lshift(1, 0),
	GuildMembers = bit32.lshift(1, 1),
	GuildModeration = bit32.lshift(1, 2),
	GuildBans = bit32.lshift(1, 2),
	GuildEmojisAndStickers = bit32.lshift(1, 3),
	GuildIntegrations = bit32.lshift(1, 4),
	GuildWebhooks = bit32.lshift(1, 5),
	GuildInvites = bit32.lshift(1, 6),
	GuildVoiceStates = bit32.lshift(1, 7),
	GuildPresences = bit32.lshift(1, 8),
	GuildMessages = bit32.lshift(1, 9),
	GuildMessageReactions = bit32.lshift(1, 10),
	GuildMessageTyping = bit32.lshift(1, 11),
	DirectMessages = bit32.lshift(1, 12),
	DirectMessageReactions = bit32.lshift(1, 13),
	DirectMessageTyping = bit32.lshift(1, 14),
	MessageContent = bit32.lshift(1, 15),
	AutoModerationConfiguration = bit32.lshift(1, 20),
	AutoModerationExecution = bit32.lshift(1, 21),
	GuildMessagePolls = bit32.lshift(1, 24),
	DirectMessagePolls = bit32.lshift(1, 25),
})

export type Intent =
	"Guilds"
	| "GuildMembers"
	| "GuildModeration"
	| "GuildBans"
	| "GuildEmojisAndStickers"
	| "GuildIntegrations"
	| "GuildWebhooks"
	| "GuildInvites"
	| "GuildVoiceStates"
	| "GuildPresences"
	| "GuildMessages"
	| "GuildMessageReactions"
	| "GuildMessageTyping"
	| "DirectMessages"
	| "DirectMessageReactions"
	| "DirectMessageTyping"

return Intents
