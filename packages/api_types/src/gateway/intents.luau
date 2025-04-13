--[=[
	@class Types.gateway.intents

	https://discord.com/developers/docs/topics/gateway#list-of-intents
]=]

local Intents = table.freeze({
	Guilds = 0,
	GuildMembers = 1,
	GuildModeration = 2,
	GuildEmojisAndStickers = 3,
	GuildIntegrations = 4,
	GuildWebhooks = 5,
	GuildInvites = 6,
	GuildVoiceStates = 7,
	GuildPresences = 8,
	GuildMessages = 9,
	GuildMessageReactions = 10,
	GuildMessageTyping = 11,
	DirectMessages = 12,
	DirectMessageReactions = 13,
	DirectMessageTyping = 14,
	MessageContent = 15,
	GuildScheduleEvents = 16,
	AutoModerationConfiguration = 20,
	AutoModerationExecution = 21,
	GuildMessagePolls = 24,
	DirectMessagePolls = 25,
})

export type Intent =
	"Guilds"
	| "GuildMembers"
	| "GuildModeration"
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
	| "MessageContent"
	| "GuildScheduleEvents"
	| "AutoModerationConfiguration"
	| "AutoModerationExecution"
	| "GuildMessagePolls"
	| "DirectMessagePolls"

return Intents
