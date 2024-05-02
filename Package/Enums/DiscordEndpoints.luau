return {
	BotGateway = "gateway/bot",

	BotGetGuild = "guilds/%s",

	BotGetChannel = "channels/%s",
	BotCreateMessage = "channels/%s/messages",
	BotGetChannelMessages = "channels/%s/messages",
	BotGetChannelMessage = "channels/%s/messages/%s",
	BotDeleteMessage = "channels/%s/messages/%s",
	BotEditMessage = "channels/%s/messages/%s",

	BotCreateReaction = "channels/%s/messages/%s/reactions/%s/@me",
	BotDeleteReaction = "channels/%s/messages/%s/reactions/%s/@me",
	BotDeleteUserReaction = "channels/%s/messages/%s/reactions/%s/%s",
	BotGetReactions = "channels/%s/messages/%s/reactions/%s",
	BotDeleteAllReactions = "channels/%s/messages/%s/reactions",
	BotDeleteAllReactionsForEmoji = "channels/%s/messages/%s/reactions/%s",

	BotDeleteChannel = "channels/%s",
	BotModifyChannel = "channels/%s",
	BotPinMessage = "channels/%s/pins/%s",
	BotUnpinMessage = "channels/%s/pins/%s",
	BotTriggerTypingChannel = "channels/%s/typing",
	BotGetPinnedMessages = "channels/%s/pins",
	BotEditChannelPermissions = "channels/%s",

	BotBulkDeleteMessages = "channels/%s/messages/bulk-delete",

	CreateGlobalApplicationCommand = "applications/%s/commands",
	EditGlobalApplicationCommand = "applications/%s/commands/%s",
	GetGlobalApplicationCommands = "applications/%s/commands",
	GetGlobalApplicationCommand = "applications/%s/commands/%s",
	DeleteGlobalApplicationCommand = "applications/%s/commands/%s",

	GetGuildAuditLogs = "guilds/%s/audit-logs",

	CreateGuildApplicationCommand = "applications/%s/guilds/%s/commands",
	EditGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",
	GetGuildApplicationCommands = "applications/%s/guilds/%s/commands",
	GetGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",
	DeleteGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",

	CreateInteractionResponse = "interactions/%s/%s/callback",
	EditOriginalInteractionResponse = "webhooks/%s/%s/messages/@original",
}