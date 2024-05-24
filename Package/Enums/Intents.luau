-- https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes

local Intents = {
	GuildMembers = "GuildMembers",
	GuildModeration = "GuildModeration",
	GuildEmojisAndStickers = "GuildEmojisAndStickers",
	GuildIntegrations = "GuildIntegrations",
	GuildWebhooks = "GuildWebhooks",
	GuildInvites = "GuildInvites",
	GuildVoiceState = "GuildVoiceState",
	GuildPresences = "GuildPresences",
	GuildMessage = "GuildMessage",
	GuildMessageReactions = "GuildMessageReactions",
	GuildMessageTyping = "GuildMessageTyping",

	DirectMessage = "DirectMessage",
	DirectMessageReactions = "DirectMessageReactions",
	DirectMessageTyping = "DirectMessageTyping",

	GuildMessageContent = "GuildMessageContent",
	GuildScheduledEvents = "GuildScheduledEvents",
	GuildModerationConfiguration = "GuildModerationConfiguration",
	GuildModerationExecution = "GuildModerationExecution",
}

export type Intents = "GuildMembers"
	| "GuildModeration"
	| "GuildEmojisAndStickers"
	| "GuildIntegrations"
	| "GuildWebhooks"
	| "GuildInvites"
	| "GuildVoiceState"
	| "GuildPresences"
	| "GuildMessage"
	| "GuildMessageReactions"
	| "GuildMessageTyping"
	| "DirectMessage"
	| "DirectMessageReactions"
	| "DirectMessageTyping"
	| "GuildMessageContent"
	| "GuildScheduledEvents"
	| "GuildModerationConfiguration"
	| "GuildModerationExecution"

return Intents
