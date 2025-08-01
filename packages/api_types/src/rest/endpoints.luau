--[=[
	@class StdPolyfills.rest.endpoints

	Mapping out all discord V10 endpoints.
]=]

local endpoints = table.freeze({
	-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-interaction-response
	CreateInteractionResponse = "/interactions/%s/%s/callback",

	-- https://discord.com/developers/docs/interactions/receiving-and-responding#get-original-interaction-response
	GetOriginalInteractionResponse = "/webhooks/%s/%s/messages/@original",

	-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-original-interaction-response
	EditOriginalInteractionResponse = "/webhooks/%s/%s/messages/@original",

	-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-original-interaction-response
	DeleteOriginalInteractionResponse = "/webhooks/%s/%s/messages/@original",

	-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
	CreateFollowupMessage = "/webhooks/%s/%s",

	-- https://discord.com/developers/docs/interactions/receiving-and-responding#get-followup-message
	GetFollowupMessage = "/webhooks/%s/%s/messages/%s",

	-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
	EditFollowupMessage = "/webhooks/%s/%s/messages/%s",

	-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
	DeleteFollowupMessage = "/webhooks/%s/%s/messages/%s",

	-- https://discord.com/developers/docs/interactions/application-commands#get-global-application-commands
	GetGlobalApplicationCommands = "/applications/%s/commands",

	-- https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
	CreateGlobalApplicationCommand = "/applications/%s/commands",

	-- https://discord.com/developers/docs/interactions/application-commands#get-global-application-command
	GetGlobalApplicationCommand = "/applications/%s/commands/%s",

	-- https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
	EditGlobalApplicationCommand = "/applications/%s/commands/%s",

	-- https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command
	DeleteGlobalApplicationCommand = "/applications/%s/commands/%s",

	-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
	BulkOverwriteGlobalApplicationCommands = "/applications/%s/commands",

	-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands
	GetGuildApplicationCommands = "/applications/%s/guilds/%s/commands",

	-- https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
	CreateGuildApplicationCommand = "/applications/%s/guilds/%s/commands",

	-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command
	GetGuildApplicationCommand = "/applications/%s/guilds/%s/commands/%s",

	-- https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
	EditGuildApplicationCommand = "/applications/%s/guilds/%s/commands/%s",

	-- https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command
	DeleteGuildApplicationCommand = "/applications/%s/guilds/%s/commands/%s",

	-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
	BulkOverwriteGuildApplicationCommands = "/applications/%s/guilds/%s/commands",

	-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
	GetGuildApplicationCommandPermissions = "/applications/%s/guilds/%s/commands/permissions",

	-- https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
	GetApplicationCommandPermissions = "/applications/%s/guilds/%s/commands/%s/permissions",

	-- https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
	EditApplicationCommandPermissions = "/applications/%s/guilds/%s/commands/%s/permissions",

	-- https://discord.com/developers/docs/resources/application#get-current-application
	GetCurrentApplication = "/applications/@me",

	-- https://discord.com/developers/docs/resources/application#edit-current-application
	EditCurrentApplication = "/applications/@me",

	-- https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
	GetApplicationRoleConnectionMetadataRecords = "/applications/%s/role-connections/metadata",

	-- https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
	UpdateApplicationRoleConnectionMetadataRecords = "/applications/%s/role-connections/metadata",

	-- https://discord.com/developers/docs/resources/audit-log#get-guild-audit-log
	GetGuildAuditLog = "/guilds/%s/audit-logs",

	-- https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
	ListAutoModerationRulesForGuild = "/guilds/%s/auto-moderation/rules",

	-- https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
	GetAutoModerationRule = "/guilds/%s/auto-moderation/rules/%s",

	-- https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
	CreateAutoModerationRule = "/guilds/%s/auto-moderation/rules",

	-- https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule
	ModifyAutoModerationRule = "/guilds/%s/auto-moderation/rules/%s",

	-- https://discord.com/developers/docs/resources/auto-moderation#delete-auto-moderation-rule
	DeleteAutoModerationRule = "/guilds/%s/auto-moderation/rules/%s",

	-- https://discord.com/developers/docs/resources/channel#get-channel
	GetChannel = "/channels/%s",

	-- https://discord.com/developers/docs/resources/channel#modify-channel
	ModifyChannel = "/channels/%s",

	-- https://discord.com/developers/docs/resources/channel#deleteclose-channel
	DeleteOrCloseChannel = "/channels/%s",

	-- https://discord.com/developers/docs/resources/channel#get-channel-messages
	GetChannelMessages = "/channels/%s/messages",

	-- https://discord.com/developers/docs/resources/channel#get-channel-message
	GetChannelMessage = "/channels/%s/messages/%s",

	-- https://discord.com/developers/docs/resources/channel#get-channel-message
	CreateMessage = "/channels/%s/messages",

	-- https://discord.com/developers/docs/resources/channel#crosspost-message
	CrosspostMessage = "/channels/%s/messages/%s/crosspost",

	-- https://discord.com/developers/docs/resources/channel#create-reaction
	CreateReaction = "/channels/%s/messages/%s/reactions/%s/@me",

	-- https://discord.com/developers/docs/resources/channel#delete-own-reaction
	DeleteOwnReaction = "/channels/%s/messages/%s/reactions/%s/@me",

	-- https://discord.com/developers/docs/resources/channel#delete-user-reaction
	DeleteUserReaction = "/channels/%s/messages/%s/reactions/%s/%s",

	-- https://discord.com/developers/docs/resources/channel#get-reactions
	GetReactions = "/channels/%s/messages/%s/reactions/%s",

	-- https://discord.com/developers/docs/resources/channel#delete-all-reactions
	DeleteAllReactions = "/channels/%s/messages/%s/reactions",

	-- https://discord.com/developers/docs/resources/channel#delete-all-reactions-for-emoji
	DeleteAllReactionsForEmoji = "/channels/%s/messages/%s/reactions/%s",

	-- https://discord.com/developers/docs/resources/channel#edit-message
	EditMessage = "/channels/%s/messages/%s",

	-- https://discord.com/developers/docs/resources/channel#delete-message
	DeleteMessage = "/channels/%s/messages/%s",

	-- https://discord.com/developers/docs/resources/channel#bulk-delete-messages
	BulkDeleteMessages = "/channels/%s/messages/bulk-delete",

	-- https://discord.com/developers/docs/resources/channel#edit-channel-permissions
	EditChannelPermissions = "/channels/%s/permissions/%s",

	-- https://discord.com/developers/docs/resources/channel#get-channel-invites
	GetChannelInvites = "/channels/%s/invites",

	-- https://discord.com/developers/docs/resources/channel#create-channel-invite
	CreateChannelInvite = "/channels/%s/invites",

	-- https://discord.com/developers/docs/resources/channel#delete-channel-permission
	DeleteChannelPermission = "/channels/%s/permissions/%s",

	-- https://discord.com/developers/docs/resources/channel#follow-announcement-channel
	FollowAnnouncementChannel = "/channels/%s/followers",

	-- https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
	TriggerTypingChannel = "/channels/%s/typing",

	-- https://discord.com/developers/docs/resources/channel#get-pinned-messages
	GetPinnedMessages = "/channels/%s/pins",

	-- https://discord.com/developers/docs/resources/channel#get-pinned-messages
	PinMessage = "/channels/%s/pins/%s",

	-- https://discord.com/developers/docs/resources/channel#unpin-message
	UnpinMessage = "/channels/%s/pins/%s",

	-- https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
	GroupDMAddRecipient = "/channels/%s/recipients/%s",

	-- https://discord.com/developers/docs/resources/channel#group-dm-remove-recipient
	GroupDMRemoveRecipient = "/channels/%s/recipients/%s",

	-- https://discord.com/developers/docs/resources/channel#start-thread-from-message
	StartThreadFromMessage = "/channels/%s/messages/%s/threads",

	-- https://discord.com/developers/docs/resources/channel#start-thread-without-message
	StartThreadWithoutMessage = "/channels/%s/threads",

	-- https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
	StartThreadInForumOrMediaChannel = "/channels/%s/threads",

	-- https://discord.com/developers/docs/resources/channel#join-thread
	JoinThread = "/channels/%s/thread-members/@me",

	-- https://discord.com/developers/docs/resources/channel#add-thread-member
	AddThreadMember = "/channels/%s/thread-members/%s",

	-- https://discord.com/developers/docs/resources/channel#leave-thread
	LeaveThread = "/channels/%s/thread-members/@me",

	-- https://discord.com/developers/docs/resources/channel#remove-thread-member
	RemoveThreadMember = "/channels/%s/thread-members/%s",

	-- https://discord.com/developers/docs/resources/channel#get-thread-member
	GetThreadMember = "/channels/%s/thread-members/%s",

	-- https://discord.com/developers/docs/resources/channel#list-thread-members
	ListThreadMembers = "/channels/%s/thread-members",

	-- https://discord.com/developers/docs/resources/channel#list-public-archived-threads
	ListPublicArchivedThreads = "/channels/%s/threads/archived/public",

	-- https://discord.com/developers/docs/resources/channel#list-public-archived-threads
	ListPrivateArchivedThreads = "/channels/%s/threads/archived/private",

	-- https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
	ListJoinedPrivateArchivedThreads = "/channels/%s/users/@me/threads/archived/private",

	-- https://discord.com/developers/docs/resources/emoji#list-guild-emojis
	ListGuildEmojis = "/guilds/%s/emojis",

	-- https://discord.com/developers/docs/resources/emoji#get-guild-emoji
	GetGuildEmoji = "/guilds/%s/emojis/%s",

	-- https://discord.com/developers/docs/resources/emoji#create-guild-emoji
	CreateGuildEmoji = "/guilds/%s/emojis",

	-- https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
	ModifyGuildEmoji = "/guilds/%s/emojis/%s",

	-- https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
	DeleteGuildEmoji = "/guilds/%s/emojis/%s",

	-- https://discord.com/developers/docs/resources/guild#create-guild
	CreateGuild = "/guilds",

	-- https://discord.com/developers/docs/resources/guild#get-guild
	GetGuild = "/guilds/%s",

	-- https://discord.com/developers/docs/resources/guild#get-guild-preview
	GetGuildPreview = "/guilds/%s/preview",

	-- https://discord.com/developers/docs/resources/guild#modify-guild
	ModifyGuild = "/guilds/%s",

	-- https://discord.com/developers/docs/resources/guild#delete-guild
	DeleteGuild = "/guilds/%s",

	-- https://discord.com/developers/docs/resources/guild#get-guild-channels
	GetGuildChannels = "/guilds/%s/channels",

	-- https://discord.com/developers/docs/resources/guild#create-guild-channel
	CreateGuildChannel = "/guilds/%s/channels",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
	ModifyGuildChannelPositions = "/guilds/%s/channels",

	-- https://discord.com/developers/docs/resources/guild#list-active-guild-threads
	ListActiveGuildThreads = "/guilds/%s/threads/active",

	-- https://discord.com/developers/docs/resources/guild#get-guild-member
	GetGuildMember = "/guilds/%s/members/%s",

	-- https://discord.com/developers/docs/resources/guild#list-guild-members
	ListGuildMembers = "/guilds/%s/members",

	-- https://discord.com/developers/docs/resources/guild#search-guild-members
	SearchGuildMembers = "/guilds/%s/members/search",

	-- https://discord.com/developers/docs/resources/guild#add-guild-member
	AddGuildMember = "/guilds/%s/members/%s",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-member
	ModifyGuildMember = "/guilds/%s/members/%s",

	-- https://discord.com/developers/docs/resources/guild#modify-current-member
	ModifyCurrentMember = "/guilds/%s/members/@me",

	-- https://discord.com/developers/docs/resources/guild#add-guild-member-role
	AddGuildMemberRole = "/guilds/%s/members/%s/roles/%s",

	-- https://discord.com/developers/docs/resources/guild#remove-guild-member-role
	RemoveGuildMemberRole = "/guilds/%s/members/%s/roles/%s",

	-- https://discord.com/developers/docs/resources/guild#remove-guild-member
	RemoveGuildMember = "/guilds/%s/members/%s",

	-- https://discord.com/developers/docs/resources/guild#get-guild-bans
	GetGuildBans = "/guilds/%s/bans",

	-- https://discord.com/developers/docs/resources/guild#get-guild-ban
	GetGuildBan = "/guilds/%s/bans/%s",

	-- https://discord.com/developers/docs/resources/guild#create-guild-ban
	CreateGuildBan = "/guilds/%s/bans/%s",

	-- https://discord.com/developers/docs/resources/guild#remove-guild-ban
	RemoveGuildBan = "/guilds/%s/bans/%s",

	-- https://discord.com/developers/docs/resources/guild#bulk-guild-ban
	BulkGuildBan = "/guilds/%s/bulk-ban",

	-- https://discord.com/developers/docs/resources/guild#get-guild-roles
	GetGuildRoles = "/guilds/%s/roles",

	-- https://discord.com/developers/docs/resources/guild#get-guild-role
	GetGuildRole = "/guilds/%s/roles/%s",

	-- https://discord.com/developers/docs/resources/guild#create-guild-role
	CreateGuildRole = "/guilds/%s/roles",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
	ModifyGuildRolePositions = "/guilds/%s/roles",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-role
	ModifyGuildRole = "/guilds/%s/roles/%s",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
	ModifyGuildMFALevel = "/guilds/%s/mfa",

	-- https://discord.com/developers/docs/resources/guild#delete-guild-role
	DeleteGuildRole = "/guilds/%s/roles/%s",

	-- https://discord.com/developers/docs/resources/guild#get-guild-prune-count
	GetGuildPruneCount = "/guilds/%s/prune",

	-- https://discord.com/developers/docs/resources/guild#begin-guild-prune
	BeginGuildPrune = "/guilds/%s/prune",

	-- https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
	GetGuildVoiceRegions = "/guilds/%s/regions",

	-- https://discord.com/developers/docs/resources/guild#get-guild-invites
	GetGuildInvites = "/guilds/%s/invites",

	-- https://discord.com/developers/docs/resources/guild#get-guild-integrations
	GetGuildIntegrations = "/guilds/%s/integrations",

	-- https://discord.com/developers/docs/resources/guild#delete-guild-integration
	DeleteGuildIntegration = "/guilds/%s/integrations/%s",

	-- https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
	GetGuildWidgetSettings = "/guilds/%s/widget",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-widget
	ModifyGuildWidget = "/guilds/%s/widget",

	-- https://discord.com/developers/docs/resources/guild#get-guild-widget
	GetGuildWidget = "/guilds/%s/widget.json",

	-- https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
	GetGuildVanityURL = "/guilds/%s/vanity-url",

	-- https://discord.com/developers/docs/resources/guild#get-guild-widget-image
	GetGuildWidgetImage = "/guilds/%s/widget.png",

	-- https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
	GetGuildWelcomeScreen = "/guilds/%s/welcome-screen",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
	ModifyGuildWelcomeScreen = "/guilds/%s/welcome-screen",

	-- https://discord.com/developers/docs/resources/guild#get-guild-onboarding
	GetGuildOnboarding = "/guilds/%s/onboarding",

	-- https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
	ModifyGuildOnboarding = "/guilds/%s/onboarding",

	-- https://discord.com/developers/docs/resources/guild#modify-current-user-voice-state
	ModifyCurrentUserVoiceState = "/guilds/%s/voice-states/@me",

	-- https://discord.com/developers/docs/resources/guild#modify-user-voice-state
	ModifyUserVoiceState = "/guilds/%s/voice-states/%s",

	-- https://discord.com/developers/docs/resources/guild-scheduled-event#list-scheduled-events-for-guild
	ListGuildScheduledForEvents = "/guilds/%s/scheduled-events",

	-- https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event
	CreateGuildScheduledEvent = "/guilds/%s/scheduled-events",

	-- https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event
	GetGuildScheduledEvent = "/guilds/%s/scheduled-events/%s",

	-- https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event
	ModifyGuildScheduledEvent = "/guilds/%s/scheduled-events/%s",

	-- https://discord.com/developers/docs/resources/guild-scheduled-event#delete-guild-scheduled-event
	DeleteGuildScheduledEvent = "/guilds/%s/scheduled-events/%s",

	-- https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event-users
	GetGuildScheduledEventUsers = "/guilds/%s/scheduled-events/%s/users",

	-- https://discord.com/developers/docs/resources/guild-template#get-guild-template
	GetGuildTemplate = "/guilds/templates/%s",

	-- https://discord.com/developers/docs/resources/guild-template#create-guild-from-guild-template
	CreateGuildFromTemplate = "/guilds/templates/%s",

	-- https://discord.com/developers/docs/resources/guild-template#get-guild-templates
	GetGuildTemplates = "/guilds/%s/templates",

	-- https://discord.com/developers/docs/resources/guild-template#create-guild-template
	CreateGuildTemplate = "/guilds/%s/templates",

	-- https://discord.com/developers/docs/resources/guild-template#sync-guild-template
	SyncGuildTemplate = "/guilds/%s/templates/%s",

	-- https://discord.com/developers/docs/resources/guild-template#modify-guild-template
	ModifyGuildTemplate = "/guilds/%s/templates/%s",

	-- https://discord.com/developers/docs/resources/guild-template#delete-guild-template
	DeleteGuildTemplate = "/guilds/%s/templates/%s",

	-- https://discord.com/developers/docs/resources/invite#get-invite
	GetInvite = "/invites/%s",

	-- https://discord.com/developers/docs/resources/invite#delete-invite
	DeleteInvite = "/invites/%s",

	-- https://discord.com/developers/docs/resources/poll#get-answer-voters
	GetAnswerVoters = "/channels/%s/polls/%s/answers/%s",

	-- https://discord.com/developers/docs/resources/poll#end-poll
	EndPoll = "/channels/%s/polls/%s/expire",

	-- https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
	CreateStageInstance = "/stage-instances",

	-- https://discord.com/developers/docs/resources/stage-instance#get-stage-instance
	GetStageInstance = "/stage-instances/%s",

	-- https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
	ModifyStageInstance = "/stage-instances/%s",

	-- https://discord.com/developers/docs/resources/stage-instance#delete-stage-instance
	DeleteStageInstance = "/stage-instances/%s",

	-- https://discord.com/developers/docs/resources/sticker#get-sticker
	GetSticker = "/stickers/%s",

	-- https://discord.com/developers/docs/resources/sticker#list-sticker-packs
	ListStickerPacks = "/sticker-packs",

	-- https://discord.com/developers/docs/resources/sticker#list-guild-stickers
	ListGuildStickers = "/guilds/%s/stickers",

	-- https://discord.com/developers/docs/resources/sticker#get-guild-sticker
	GetGuildSticker = "/guilds/%s/stickers/%s",

	-- https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
	GetCurrentUserVoiceState = "/guilds/%s/voice-states/@me",

	-- https://discord.com/developers/docs/resources/voice#get-user-voice-state
	GetUserVoiceState = "/guilds/%s/voice-states/%s",

	-- https://discord.com/developers/docs/resources/sticker#create-guild-sticker
	CreateGuildSticker = "/guilds/%s/stickers",

	-- https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
	ModifyGuildSticker = "/guilds/%s/stickers/%s",

	-- https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
	DeleteGuildSticker = "/guilds/%s/stickers/%s",

	-- https://discord.com/developers/docs/resources/user#get-current-user
	GetCurrentUser = "/users/@me",

	-- https://discord.com/developers/docs/resources/user#get-user
	GetUser = "/users/%s",

	-- https://discord.com/developers/docs/resources/user#modify-current-user
	ModifyCurrentUser = "/users/@me",

	-- https://discord.com/developers/docs/resources/user#get-current-user-guilds
	GetCurrentUserGuilds = "/users/@me/guilds",

	-- https://discord.com/developers/docs/resources/user#get-current-user-guild-member
	GetCurrentUserGuildMember = "/users/@me/guilds/%s/member",

	-- https://discord.com/developers/docs/resources/user#leave-guild
	LeaveGuild = "/users/@me/guilds/%s",

	-- https://discord.com/developers/docs/resources/user#create-dm
	CreateDM = "/users/@me/channels",

	-- https://discord.com/developers/docs/resources/user#create-group-dm
	CreateGroupDM = "/users/@me/channels",

	-- https://discord.com/developers/docs/resources/user#get-current-user-connections
	GetCurrentUserConnections = "/users/@me/connections",

	-- https://discord.com/developers/docs/resources/user#get-current-user-application-role-connection
	GetCurrentUserApplicationRolConnections = "/users/@me/applications/%s/role-connections",

	-- https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
	UpdateCurrentUserApplicationRoleConnection = "/users/@me/applications/%s/role-connections/%s",

	-- https://discord.com/developers/docs/resources/voice#list-voice-regions
	ListVoiceRegions = "/voice/regions",

	-- https://discord.com/developers/docs/resources/webhook#create-webhook
	CreateWebhook = "/channels/%s/webhooks",

	-- https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
	GetChannelWebhooks = "/channels/%s/webhooks",

	-- https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
	GetGuildWebhooks = "/guilds/%s/webhooks",

	-- https://discord.com/developers/docs/resources/webhook#get-webhook
	GetWebhook = "/webhooks/%s",

	-- https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
	GetWebhookWithToken = "/webhooks/%s/%s",

	-- https://discord.com/developers/docs/resources/webhook#modify-webhook
	ModifyWebhook = "/webhooks/%s",

	-- https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
	ModifyWebhookWithToken = "/webhooks/%s/%s",

	-- https://discord.com/developers/docs/resources/webhook#delete-webhook
	DeleteWebhook = "/webhooks/%s",

	-- https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
	DeleteWebhookWithToken = "/webhooks/%s/%s",

	-- https://discord.com/developers/docs/resources/webhook#execute-webhook
	ExecuteWebhook = "/webhooks/%s/%s",

	-- https://discord.com/developers/docs/resources/webhook#execute-slackcompatible-webhook
	ExecuteSlackCompatibleWebhook = "/webhooks/%s/%s/slack",

	-- https://discord.com/developers/docs/resources/webhook#execute-githubcompatible-webhook
	ExecuteGithubCompatibleWebhook = "/webhooks/%s/%s/github",

	-- https://discord.com/developers/docs/resources/webhook#get-webhook-message
	GetWebhookMessage = "/webhooks/%s/%s/messages/%s",

	-- https://discord.com/developers/docs/resources/webhook#edit-webhook-message
	EditWebhookMessage = "/webhooks/%s/%s/messages/%s",

	-- https://discord.com/developers/docs/resources/webhook#delete-webhook-message
	DeleteWebhookMessage = "/webhooks/%s/%s/messages/%s",

	-- https://discord.com/developers/docs/topics/gateway#get-gateway
	GetGateway = "/gateway",

	-- https://discord.com/developers/docs/topics/gateway#get-gateway-bot
	GetGatewayBot = "/gateway/bot",

	-- https://discord.com/developers/docs/topics/oauth2#get-current-bot-application-information
	GetCurrentBotApplicationInformation = "/oauth2/applications/@me",

	-- https://discord.com/developers/docs/topics/oauth2#get-current-authorization-information
	GetCurrentAuthorizationInformation = "/oauth2/@me",
})

export type Endpoint =
	"CreateInteractionResponse"
	| "GetOriginalInteractionResponse"
	| "EditOriginalInteractionResponse"
	| "DeleteOriginalInteractionResponse"
	| "CreateFollowupMessage"
	| "GetFollowupMessage"
	| "EditFollowupMessage"
	| "DeleteFollowupMessage"
	| "GetGlobalApplicationCommands"
	| "CreateGlobalApplicationCommand"
	| "GetGlobalApplicationCommand"
	| "EditGlobalApplicationCommand"
	| "DeleteGlobalApplicationCommand"
	| "BulkOverwriteGlobalApplicationCommands"
	| "GetGuildApplicationCommands"
	| "CreateGuildApplicationCommand"
	| "GetGuildApplicationCommand"
	| "EditGuildApplicationCommand"
	| "DeleteGuildApplicationCommand"
	| "BulkOverwriteGuildApplicationCommands"
	| "GetGuildApplicationCommandPermissions"
	| "GetApplicationCommandPermissions"
	| "EditApplicationCommandPermissions"
	| "GetCurrentApplication"
	| "EditCurrentApplication"
	| "GetApplicationRoleConnectionMetadataRecords"
	| "UpdateApplicationRoleConnectionMetadataRecords"
	| "GetGuildAuditLog"
	| "BatchEditApplicationCommandPermissions"
	| "ListAutoModerationRulesForGuild"
	| "GetAutoModerationRule"
	| "CreateAutoModerationRule"
	| "ModifyAutoModerationRule"
	| "DeleteAutoModerationRule"
	| "GetChannel"
	| "ModifyChannel"
	| "DeleteOrCloseChannel"
	| "GetChannelMessages"
	| "GetChannelMessage"
	| "CreateMessage"
	| "CrosspostMessage"
	| "CreateReaction"
	| "DeleteOwnReaction"
	| "DeleteUserReaction"
	| "GetReactions"
	| "DeleteAllReactions"
	| "DeleteAllReactionsForEmoji"
	| "EditMessage"
	| "DeleteMessage"
	| "BulkDeleteMessages"
	| "EditChannelPermissions"
	| "GetChannelInvites"
	| "CreateChannelInvite"
	| "DeleteChannelPermission"
	| "FollowAnnouncementChannel"
	| "TriggerTypingChannel"
	| "GetPinnedMessages"
	| "PinMessage"
	| "UnpinMessage"
	| "GroupDMAddRecipient"
	| "GroupDMRemoveRecipient"
	| "StartThreadFromMessage"
	| "StartThreadWithoutMessage"
	| "StartThreadInForumOrMediaChannel"
	| "JoinThread"
	| "AddThreadMember"
	| "LeaveThread"
	| "RemoveThreadMember"
	| "GetThreadMember"
	| "ListThreadMembers"
	| "ListPublicArchivedThreads"
	| "ListPrivateArchivedThreads"
	| "ListJoinedPrivateArchivedThreads"
	| "ListGuildEmojis"
	| "GetGuildEmoji"
	| "CreateGuildEmoji"
	| "ModifyGuildEmoji"
	| "DeleteGuildEmoji"
	| "CreateGuild"
	| "GetGuild"
	| "GetGuildPreview"
	| "ModifyGuild"
	| "DeleteGuild"
	| "GetGuildChannels"
	| "CreateGuildChannel"
	| "ModifyGuildChannelPositions"
	| "ListActiveGuildThreads"
	| "GetGuildMember"
	| "ListGuildMembers"
	| "SearchGuildMembers"
	| "AddGuildMember"
	| "ModifyGuildMember"
	| "ModifyCurrentMember"
	| "ModifyCurrentUserNick"
	| "AddGuildMemberRole"
	| "RemoveGuildMemberRole"
	| "RemoveGuildMember"
	| "GetGuildBans"
	| "GetGuildBan"
	| "CreateGuildBan"
	| "RemoveGuildBan"
	| "BulkGuildBan"
	| "GetGuildRoles"
	| "CreateGuildRole"
	| "ModifyGuildRolePositions"
	| "ModifyGuildRole"
	| "ModifyGuildMFALevel"
	| "DeleteGuildRole"
	| "GetGuildPruneCount"
	| "BeginGuildPrune"
	| "GetGuildVoiceRegions"
	| "GetGuildInvites"
	| "GetGuildIntegrations"
	| "DeleteGuildIntegration"
	| "GetGuildWidgetSettings"
	| "ModifyGuildWidget"
	| "GetGuildWidget"
	| "GetGuildVanityURL"
	| "GetGuildWidgetImage"
	| "GetGuildWelcomeScreen"
	| "ModifyGuildWelcomeScreen"
	| "GetGuildOnboarding"
	| "ModifyGuildOnboarding"
	| "ModifyCurrentUserVoiceState"
	| "ModifyUserVoiceState"
	| "ListGuildScheduledForEvents"
	| "CreateGuildScheduledEvent"
	| "GetGuildScheduledEvent"
	| "ModifyGuildScheduledEvent"
	| "DeleteGuildScheduledEvent"
	| "GetGuildScheduledEventUsers"
	| "GetGuildTemplate"
	| "CreateGuildFromTemplate"
	| "GetGuildTemplates"
	| "CreateGuildTemplate"
	| "SyncGuildTemplate"
	| "ModifyGuildTemplate"
	| "DeleteGuildTemplate"
	| "GetInvite"
	| "DeleteInvite"
	| "GetAnswerVoters"
	| "EndPoll"
	| "CreateStageInstance"
	| "GetStageInstance"
	| "ModifyStageInstance"
	| "DeleteStageInstance"
	| "GetSticker"
	| "ListStickerPacks"
	| "ListGuildStickers"
	| "GetGuildSticker"
	| "CreateGuildSticker"
	| "ModifyGuildSticker"
	| "DeleteGuildSticker"
	| "GetCurrentUser"
	| "GetUser"
	| "ModifyCurrentUser"
	| "GetCurrentUserGuilds"
	| "GetCurrentUserGuildMember"
	| "LeaveGuild"
	| "CreateDM"
	| "CreateGroupDM"
	| "GetCurrentUserConnections"
	| "GetCurrentUserApplicationRolConnections"
	| "UpdateCurrentUserApplicationRoleConnection"
	| "ListVoiceRegions"
	| "CreateWebhook"
	| "GetChannelWebhooks"
	| "GetGuildWebhooks"
	| "GetWebhook"
	| "GetWebhookWithToken"
	| "ModifyWebhook"
	| "ModifyWebhookWithToken"
	| "DeleteWebhook"
	| "DeleteWebhookWithToken"
	| "ExecuteWebhook"
	| "ExecuteSlackCompatibleWebhook"
	| "ExecuteGithubCompatibleWebhook"
	| "GetWebhookMessage"
	| "EditWebhookMessage"
	| "DeleteWebhookMessage"
	| "GetGateway"
	| "GetGatewayBot"
	| "GetCurrentBotApplicationInformation"
	| "GetCurrentAuthorizationInformation"

return endpoints
