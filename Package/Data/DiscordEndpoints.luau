--[[
	Maps a key to a API path, allowing us to map out the Discord REST API

	These API Paths adhere sto the luau string formatting, where '%s' is replaced with a different value.
]]

return {
	BotGateway = "gateway/bot",

	BotGetGuild = "guilds/%s",

	BotGetChannel = "channels/%s",
	BotCreateMessage = "channels/%s/messages",
	BotGetChannelMessages = "channels/%s/messages",
	BotGetChannelMessage = "channels/%s/messages/%s",
	BotDeleteMessage = "channels/%s/messages/%s",
	BotEditMessage = "channels/%s/messages/%s",
	BotCrosspostMessage = "channels/%s/messages/%s/crosspost",
	BotCreateThreadFromMessage = "channels/%s/messages/%s/threads",
	BotCreateThread = "channels/%s/threads",

	BotGetInvites = "channels/%s/invites",
	BotDeleteInvite = "invites/%s",

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
	BotEditChannelPermissions = "channels/%s/permissions/%s",
	BotDeleteChannelPermission = "channels/%s/permissions/%s",
	BotGetPinnedMessages = "channels/%s/pins",
	BotFollowAnnouncementChannel = "channels/%s/followers",

	BotGetThreadMembers = "channels/%s/thread-members",
	BotJoinThreadChannel = "channels/%s/thread-members/@me",
	BotAddMemberToThreadChannel = "channels/%s/thread-members/%s",
	BotLeaveThreadChannel = "channels/%s/thread-members/@me",
	BotRemoveMemberFromThreadChannel = "channels/%s/thread-members/%s",

	BotBulkDeleteMessages = "channels/%s/messages/bulk-delete",

	CreateGlobalApplicationCommand = "applications/%s/commands",
	EditGlobalApplicationCommand = "applications/%s/commands/%s",
	GetGlobalApplicationCommands = "applications/%s/commands",
	GetGlobalApplicationCommand = "applications/%s/commands/%s",
	DeleteGlobalApplicationCommand = "applications/%s/commands/%s",

	GetGuildAuditLogs = "guilds/%s/audit-logs",
	BotModifyGuild = "guilds/%s",
	BotDeleteGuild = "guilds/%s",
	BotGetGuildChannels = "guilds/%s/channels",
	BotGetGuildMember = "guilds/%s/members/%s",
	BotGetGuildMembers = "guilds/%s/members?limit=%s&after=%s",
	BotBanGuildMember = "guilds/%s/members/%s",
	BotRemoveGuildMember = "guilds/%s/members/%s",
	BotRemoveGuildMemberBan = "guilds/%s/bans/%s",
	BotAddGuildMemberRole = "guilds/%s/members/%s/roles/%s",
	BotRemoveGuildMemberRole = "guilds/%s/members/%s/roles/%s",
	BotModifyGuildMember = "guilds/%s/members/%s",
	BotSearchGuildMembers = "guilds/%s/members/search?query=%s&limit=%s",
	BotModifyGuildChannelPosition = "channels/%s/channels",

	BotListAutomoderationRules = "guilds/%s/auto-moderation/rules",
	BotGetAutomoderationRule = "guilds/%s/auto-moderation/rules/%s",
	BotCreateAutomoderationRule = "guilds/%s/auto-moderation/rules",
	BotModifyAutomoderationRule = "guilds/%s/auto-moderation/rules/%s",
	BotDeleteAutomoderationRule = "guilds/%s/auto-moderation/rules/%s",

	CreateGuildApplicationCommand = "applications/%s/guilds/%s/commands",
	EditGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",
	GetGuildApplicationCommands = "applications/%s/guilds/%s/commands",
	GetGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",
	DeleteGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",

	CreateInteractionResponse = "interactions/%s/%s/callback",
	EditOriginalInteractionResponse = "webhooks/%s/%s/messages/@original",
}
