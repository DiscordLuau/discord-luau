--[=[
	@class Types.gateway.receiveEvents

	https://discord.com/developers/docs/topics/gateway-events#receive-events

	these enums map to the `T` event name given in a Discord payload; 
		https://discord.com/developers/docs/topics/gateway-events#payload-structure
]=]

local ReceiveEvents = table.freeze({
	Hello = "HELLO",
	Ready = "READY",
	Resumed = "RESUMED",
	Reconnect = "RECONNECT",
	InvalidSession = "INVALID_SESSION",
	ApplicationCommandPermissionsUpdate = "APPLICATION_COMMAND_PERMISSIONS_UPDATE",
	AutoModerationRuleCreate = "AUTO_MODERATION_RULE_CREATE",
	AutoModerationRuleUpdate = "AUTO_MODERATION_RULE_UPDATE",
	AutoModerationRuleDelete = "AUTO_MODERATION_RULE_DELETE",
	AutoModerationActionExecution = "AUTO_MODERATION_ACTION_EXECUTION",
	ChannelCreate = "CHANNEL_CREATE",
	ChannelUpdate = "CHANNEL_UPDATE",
	ChannelDelete = "CHANNEL_DELETE",
	ChannelPinsUpdate = "CHANNEL_PINS_UPDATE",
	ThreadCreate = "THREAD_CREATE",
	ThreadUpdate = "THREAD_UPDATE",
	ThreadDelete = "THREAD_DELETE",
	ThreadListSync = "THREAD_LIST_SYNC",
	ThreadMemberUpdate = "THREAD_MEMBER_UPDATE",
	ThreadMembersUpdate = "THREAD_MEMBERS_UPDATE",
	EntitlementCreate = "ENTITLEMENT_CREATE",
	EntitlementUpdate = "ENTITLEMENT_UPDATE",
	EntitlementDelete = "ENTITLEMENT_DELETE",
	GuildCreate = "GUILD_CREATE",
	GuildUpdate = "GUILD_UPDATE",
	GuildDelete = "GUILD_DELETE",
	GuildAuditLogEntryCreate = "GUILD_AUDIT_LOG_ENTRY_CREATE",
	GuildBanAdd = "GUILD_BAN_ADD",
	GuildBanRemove = "GUILD_BAN_REMOVE",
	GuildEmojisUpdate = "GUILD_EMOJIS_UPDATE",
	GuildStickersUpdate = "GUILD_STICKERS_UPDATE",
	GuildIntegrationsUpdate = "GUILD_INTEGRATIONS_UPDATE",
	GuildMemberAdd = "GUILD_MEMBER_ADD",
	GuildMemberRemove = "GUILD_MEMBER_REMOVE",
	GuildMemberUpdate = "GUILD_MEMBER_UPDATE",
	GuildMembersChunk = "GUILD_MEMBERS_CHUNK",
	GuildRoleCreate = "GUILD_ROLE_CREATE",
	GuildRoleDelete = "GUILD_ROLE_DELETE",
	GuildRoleUpdate = "GUILD_ROLE_UPDATE",
	GuildScheduledEventCreate = "GUILD_SCHEDULED_EVENT_CREATE",
	GuildScheduledEventUpdate = "GUILD_SCHEDULED_EVENT_UPDATE",
	GuildScheduledEventDelete = "GUILD_SCHEDULED_EVENT_DELETE",
	GuildScheduledEventUserAdd = "GUILD_SCHEDULED_EVENT_USER_ADD",
	GuildScheduledEventUserRemove = "GUILD_SCHEDULED_EVENT_USER_REMOVE",
	IntegrationCreate = "INTEGRATION_CREATE",
	IntegrationUpdate = "INTEGRATION_UPDATE",
	IntegrationDelete = "INTEGRATION_DELETE",
	InteractionCreate = "INTERACTION_CREATE",
	InviteCreate = "INVITE_CREATE",
	InviteDelete = "INVITE_DELETE",
	MessageCreate = "MESSAGE_CREATE",
	MessageUpdate = "MESSAGE_UPDATE",
	MessageDelete = "MESSAGE_DELETE",
	MessageDeleteBulk = "MESSAGE_DELETE_BULK",
	MessageReactionAdd = "MESSAGE_REACTION_ADD",
	MessageReactionRemove = "MESSAGE_REACTION_REMOVE",
	MessageReactionRemoveAll = "MESSAGE_REACTION_REMOVE_ALL",
	MessageReactionRemoveEmoji = "MESSAGE_REACTION_REMOVE_EMOJI",
	PresenceUpdate = "PRESENCE_UPDATE",
	StageInstanceCreate = "STAGE_INSTANCE_CREATE",
	StageInstanceUpdate = "STAGE_INSTANCE_UPDATE",
	StageInstanceDelete = "STAGE_INSTANCE_DELETE",
	TypingStart = "TYPING_START",
	UserUpdate = "USER_UPDATE",
	VoiceStateUpdate = "VOICE_STATE_UPDATE",
	VoiceServerUpdate = "VOICE_SERVER_UPDATE",
	WebhooksUpdate = "WEBHOOKS_UPDATE",
	MessagePollVoteAdd = "MESSAGE_POLL_VOTE_ADD",
	MessagePollVoteRemove = "MESSAGE_POLL_VOTE_REMOVE",
})

export type ReceiveEvent =
	"Hello"
	| "Ready"
	| "Resumed"
	| "Reconnect"
	| "InvalidSession"
	| "ApplicationCommandPermissionsUpdate"
	| "AutoModerationRuleCreate"
	| "AutoModerationRuleUpdate"
	| "AutoModerationRuleDelete"
	| "AutoModerationActionExecution"
	| "ChannelCreate"
	| "ChannelUpdate"
	| "ChannelDelete"
	| "ChannelPinsUpdate"
	| "ThreadCreate"
	| "ThreadUpdate"
	| "ThreadDelete"
	| "ThreadListSync"
	| "ThreadMemberUpdate"
	| "ThreadMembersUpdate"
	| "EntitlementCreate"
	| "EntitlementUpdate"
	| "EntitlementDelete"
	| "GuildCreate"
	| "GuildUpdate"
	| "GuildDelete"
	| "GuildAuditLogEntryCreate"
	| "GuildBanAdd"
	| "GuildBanRemove"
	| "GuildEmojisUpdate"
	| "GuildStickersUpdate"
	| "GuildIntegrationsUpdate"
	| "GuildMemberAdd"
	| "GuildMemberRemove"
	| "GuildMemberUpdate"
	| "GuildMembersChunk"
	| "GuildRoleCreate"
	| "GuildRoleDelete"
	| "GuildRoleUpdate"
	| "GuildScheduledEventCreate"
	| "GuildScheduledEventUpdate"
	| "GuildScheduledEventDelete"
	| "GuildScheduledEventUserAdd"
	| "GuildScheduledEventUserRemove"
	| "IntegrationCreate"
	| "IntegrationUpdate"
	| "IntegrationDelete"
	| "InteractionCreate"
	| "InviteCreate"
	| "InviteDelete"
	| "MessageCreate"
	| "MessageUpdate"
	| "MessageDelete"
	| "MessageDeleteBulk"
	| "MessageReactionAdd"
	| "MessageReactionRemove"
	| "MessageReactionRemoveAll"
	| "MessageReactionRemoveEmoji"
	| "PresenceUpdate"
	| "StageInstanceCreate"
	| "StageInstanceUpdate"
	| "StageInstanceDelete"
	| "TypingStart"
	| "UserUpdate"
	| "VoiceStateUpdate"
	| "VoiceServerUpdate"
	| "WebhooksUpdate"
	| "MessagePollVoteAdd"
	| "MessagePollVoteRemove"

return ReceiveEvents
