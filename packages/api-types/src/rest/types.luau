--[[
	Mapping out all discord responses that we can get from the Discord v10 REST/HTTP API.
]]

local objects = require("@api-types/objects")

-- [[ Base ]] --

export type Response<DATA> = DATA
export type Request<DATA> = DATA

-- [[ Requests ]] --

-- https://discord.com/developers/docs/resources/application#edit-current-application
export type EditCurrentApplicationRequest = Request<{
	custom_install_url: string, -- Default custom authorization URL for the app, if enabled
	description: string, -- Description of the app
	role_connections_verification_url: string, -- Role connection verification URL for the app
	install_params: objects.InstallParamsObject, -- Settings for the app's default in-app authorization link, if enabled
	integration_types_config: { [objects.IntegrationType]: unknown }, -- In preview. Default scopes and permissions for each supported installation context. Value for each key is an integration type configuration object
	flags: number, -- App's public flags
	icon: string?, -- Icon for the app
	cover_image: string?, -- Default rich presence invite cover image for the app
	interactions_endpoint_url: string, -- Interactions endpoint URL for the app
	tags: { string }, -- List of tags describing the content and functionality of the app (max of 20 characters per tag). Max of 5 tags.
}>

-- [[ Responses ]] --

-- https://discord.com/developers/docs/interactions/application-commands#get-global-application-commands
export type GetGlobalApplicationCommandsResponse = Response<{ objects.ApplicationCommandObject }>

-- https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
export type CreateGlobalApplicationCommandResponse = Response<objects.ApplicationCommandObject>

-- https://discord.com/developers/docs/interactions/application-commands#get-global-application-command
export type GetGlobalApplicationCommandResponse = Response<objects.ApplicationCommandObject>

-- https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
export type EditGlobalApplicationCommandResponse = Response<objects.ApplicationCommandObject>

-- https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command
export type DeleteGlobalApplicationCommandResponse = Response<nil>

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
export type BulkOverwriteGlobalApplicationCommandsResponse = Response<{ objects.ApplicationCommandObject }>

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands
export type GetGuildApplicationCommandsResponse = Response<{ objects.ApplicationCommandObject }>

-- https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
export type CreateGuildApplicationCommandResponse = Response<objects.ApplicationCommandObject>

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command
export type GetGuildApplicationCommandResponse = Response<objects.ApplicationCommandObject>

-- https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
export type EditGuildApplicationCommandResponse = Response<objects.ApplicationCommandObject>

-- https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command
export type DeleteGuildApplicationCommandResponse = Response<nil>

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
export type BulkOverwriteGuildApplicationCommandsResponse = Response<{ objects.ApplicationCommandObject }>

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
export type GetGuildApplicationCommandPermissions = Response<{ objects.GuildApplicationCommandPermissionsObject }>

-- https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
export type GetApplicationCommandPermissions = Response<{ objects.GuildApplicationCommandPermissionsObject }>

-- https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
export type EditApplicationCommandPermissions = Response<objects.GuildApplicationCommandPermissionsObject>

-- https://discord.com/developers/docs/interactions/application-commands#batch-edit-application-command-permissions
export type BatchEditApplicationCommandPermissions = Response<{ objects.GuildApplicationCommandPermissionsObject }>

-- https://discord.com/developers/docs/resources/application#get-current-application
export type GetCurrentApplicationResponse = Response<objects.ApplicationObject>

-- https://discord.com/developers/docs/resources/application#edit-current-application
export type EditCurrentApplicationResponse = Response<objects.ApplicationObject>

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
export type GetApplicationRoleConnectionMetadataRecordsResponse = Response<
	objects.ApplicationRoleConnectionMetadataObject
>

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
export type UpdateApplicationRoleConnectionMetadataRecordsResponse = Response<
	objects.ApplicationRoleConnectionMetadataObject
>

-- https://discord.com/developers/docs/resources/audit-log#get-guild-audit-log
export type GetGuildAuditLogResponse = Response<objects.AuditLogObject>

-- https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
export type ListAutoModerationRulesForGuildResponse = Response<{ objects.AutomoderationRuleObject }>

-- https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
export type GetAutoModerationRuleResponse = Response<objects.AutomoderationRuleObject>

-- https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
export type CreateAutoModerationRuleResponse = Response<objects.AutomoderationRuleObject>

-- https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule
export type ModifyAutoModerationRuleResponse = Response<objects.AutomoderationRuleObject>

-- https://discord.com/developers/docs/resources/auto-moderation#delete-auto-moderation-rule
export type DeleteAutoModerationRuleResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#get-channel
export type GetChannelResponse = Response<objects.ChannelObject & (objects.ThreadMemberObject?)>

-- https://discord.com/developers/docs/resources/channel#modify-channel
export type ModifyChannelResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/channel#deleteclose-channel
export type DeleteCloseChannelResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/channel#get-channel-messages
export type GetChannelMessagesResponse = Response<{ objects.MessageObject }>

-- https://discord.com/developers/docs/resources/channel#get-channel-message
export type GetChannelMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/resources/channel#create-message
export type CreateMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/resources/channel#crosspost-message
export type CrosspostMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/resources/channel#create-reaction
export type CreateReactionResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#delete-own-reaction
export type DeleteOwnReactionResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#delete-user-reaction
export type DeleteUserReactionResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#get-reactions
export type GetReactionsResponse = Response<{ objects.UserObject }>

-- https://discord.com/developers/docs/resources/channel#delete-all-reactions
export type DeleteAllReactionsResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#delete-all-reactions-for-emoji
export type DeleteAllReactionsForEmojiResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#edit-message
export type EditMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/resources/channel#delete-message
export type DeleteMessageResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#bulk-delete-messages
export type BulkDeleteMessageResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#edit-channel-permissions
export type EditChannelPermissionsResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#get-channel-invites
export type GetChannelInvitesResponse = Response<{ objects.InviteObject & objects.InviteMetadataObject }>

-- https://discord.com/developers/docs/resources/channel#create-channel-invite
export type CreateChannelInviteResponse = Response<objects.InviteObject>

-- https://discord.com/developers/docs/resources/channel#delete-channel-permission
export type DeleteChannelPermissionResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#follow-announcement-channel
export type FollowAnnouncementChannelResponse = Response<objects.FollowedChannelObject>

-- https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
export type TriggerTypingIndicatorResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#get-pinned-messages
export type GetPinnedMessagesResponse = Response<{ objects.MessageObject }>

-- https://discord.com/developers/docs/resources/channel#pin-message
export type PinMessageResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#unpin-message
export type UnpinMessageResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
export type GroupDMAddRecipientResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#group-dm-remove-recipient
export type GroupDMRemoveRecipientResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#start-thread-from-message
export type StartThreadFromMessageResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/channel#start-thread-without-message
export type StartThreadWithoutMessageResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
export type StartThreadInForumOrMediaChannelResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/channel#join-thread
export type JoinThreadResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#add-thread-member
export type AddThreadMemberResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#leave-thread
export type LeaveThreadResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#remove-thread-member
export type RemoveThreadMemberResponse = Response<nil>

-- https://discord.com/developers/docs/resources/channel#get-thread-member
export type GetThreadMemberResponse = Response<objects.ThreadMemberObject>

-- https://discord.com/developers/docs/resources/channel#list-thread-members
export type ListThreadMembersResponse = Response<{ objects.ThreadMemberObject }>

-- https://discord.com/developers/docs/resources/channel#list-public-archived-threads
export type ListPublicArchivedThreadsResponse = Response<{
	threads: { objects.ChannelObject }, -- the public, archived threads
	members: { objects.ThreadMemberObject }, -- a thread member object for each returned thread the current user has joined
	has_more: boolean, -- whether there are potentially additional threads that could be returned on a subsequent call
}>

-- https://discord.com/developers/docs/resources/channel#list-private-archived-threads
export type ListPrivateArchivedThreadsResponse = Response<{
	threads: { objects.ChannelObject }, -- the public, archived threads
	members: { objects.ThreadMemberObject }, -- a thread member object for each returned thread the current user has joined
	has_more: boolean, -- whether there are potentially additional threads that could be returned on a subsequent call
}>

-- https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
export type ListJoinedPrivateArchivedThreadsResponse = Response<{
	threads: { objects.ChannelObject }, -- the public, archived threads
	members: { objects.ThreadMemberObject }, -- a thread member object for each returned thread the current user has joined
	has_more: boolean, -- whether there are potentially additional threads that could be returned on a subsequent call
}>

-- https://discord.com/developers/docs/resources/emoji#list-guild-emojis
export type ListGuildEmojisResponse = Response<{ objects.EmojiObject }>

-- https://discord.com/developers/docs/resources/emoji#get-guild-emoji
export type GetGuildEmojiResponse = Response<objects.EmojiObject>

-- https://discord.com/developers/docs/resources/emoji#create-guild-emoji
export type CreateGuildEmojiResponse = Response<objects.EmojiObject>

-- https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
export type ModifyGuildEmojiResponse = Response<objects.EmojiObject>

-- https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
export type DeleteGuildEmojiResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#create-guild
export type CreateGuildResponse = Response<objects.GuildObject>

-- https://discord.com/developers/docs/resources/guild#get-guild
export type GetGuildResponse = Response<objects.GuildObject>

-- https://discord.com/developers/docs/resources/guild#get-guild
export type GetGuildPreviewResponse = Response<objects.GuildPreviewObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild
export type ModifyGuildResponse = Response<objects.GuildObject>

-- https://discord.com/developers/docs/resources/guild#delete-guild
export type DeleteGuildResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#get-guild-channels
export type GetGuildChannelsResponse = Response<{ objects.ChannelObject }>

-- https://discord.com/developers/docs/resources/guild#create-guild-channel
export type CreateGuildChannelResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
export type ModifyGuildChannelPositionsResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#list-active-guild-threads
export type ListActiveGuildThreadsResponse = Response<{
	threads: { objects.ChannelObject }, -- the active threads
	members: { objects.ThreadMemberObject }, -- a thread member object for each returned thread the current user has joined
}>

-- https://discord.com/developers/docs/resources/guild#get-guild-member
export type GetGuildMemberResponse = Response<objects.GuildMemberObject>

-- https://discord.com/developers/docs/resources/guild#list-guild-members
export type ListGuildMembersResponse = Response<{ objects.GuildMemberObject }>

-- https://discord.com/developers/docs/resources/guild#search-guild-members
export type SearchGuildMembersResponse = Response<{ objects.GuildMemberObject }>

-- https://discord.com/developers/docs/resources/guild#add-guild-member
export type AddGuildMemberResponse = Response<objects.GuildMemberObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-member
export type ModifyGuildMemberResponse = Response<objects.GuildMemberObject>

-- https://discord.com/developers/docs/resources/guild#modify-current-member
export type ModifyCurrentMemberResponse = Response<objects.GuildMemberObject>

-- https://discord.com/developers/docs/resources/guild#modify-current-user-nick
export type ModifyCurrentUserNicknameResponse = Response<unknown>

-- https://discord.com/developers/docs/resources/guild#add-guild-member-role
export type AddGuildMemberRoleResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#remove-guild-member-role
export type RemoveGuildMemberRoleResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#remove-guild-member
export type RemoveGuildMemberResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#get-guild-bans
export type GetGuildBansResponse = Response<{ objects.BanObject }>

-- https://discord.com/developers/docs/resources/guild#get-guild-ban
export type GetGuildBanResponse = Response<objects.BanObject>

-- https://discord.com/developers/docs/resources/guild#create-guild-ban
export type CreateGuildBanResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#remove-guild-ban
export type RemoveGuildBanResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#bulk-guild-ban
export type BulkGuildBanResponse = Response<{
	banned_users: { objects.Snowflake },
	failed_users: { objects.Snowflake },
}>

-- https://discord.com/developers/docs/resources/guild#get-guild-roles
export type GetGuildRolesResponse = Response<{ objects.GuildRoleObject }>

-- https://discord.com/developers/docs/resources/guild#create-guild-role
export type CreateGuildRoleResponse = Response<objects.GuildRoleObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
export type ModifyGuildRolePositions = Response<{ objects.GuildRoleObject }>

-- https://discord.com/developers/docs/resources/guild#modify-guild-role
export type ModifyGuildRoleResponse = Response<objects.GuildRoleObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
export type ModifyGuildMFALevelResponse = Response<unknown>

-- https://discord.com/developers/docs/resources/guild#delete-guild-role
export type DeleteGuildRoleResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#get-guild-prune-count
export type GetGuildPruneCountResponse = Response<{ pruned: number }>

-- https://discord.com/developers/docs/resources/guild#begin-guild-prune
export type BeginGuildPruneResponse = Response<{ pruned: number }>

-- https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
export type GetGuildVoiceRegionsResponse = Response<{ objects.VoiceRegionObject }>

-- https://discord.com/developers/docs/resources/guild#get-guild-invites
export type GetGuldInvitesResponse = Response<{ objects.InviteObject & objects.InviteMetadataObject }>

-- https://discord.com/developers/docs/resources/guild#get-guild-integrations
export type GetGuildIntegrationsResponse = Response<objects.IntegrationObject>

-- https://discord.com/developers/docs/resources/guild#delete-guild-integration
export type DeleteGuildIntegrationResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
export type GetGuildWidgetSettingsResponse = Response<objects.GuildWidgetSettingsObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-widget
export type ModifyGuildWidgetResponse = Response<objects.GuildWidgetSettingsObject>

-- https://discord.com/developers/docs/resources/guild#get-guild-widget
export type GetGuildWidgetResponse = Response<objects.GuildWidgetObject>

-- https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
export type GetGuildVanityUrlResponse = Response<objects.InviteObject>

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-image
export type GetGuildWidgetImageResponse = Response<string>

-- https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
export type GetGuildWelcomeScreenResponse = Response<objects.WelcomeScreenObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
export type ModifyGuildWelcomeScreenResponse = Response<objects.WelcomeScreenObject>

-- https://discord.com/developers/docs/resources/guild#get-guild-onboarding
export type GetGuildOnboardingResponse = Response<objects.GuildOnboardingObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
export type ModifyGuildOnboardingResponse = Response<objects.GuildOnboardingObject>

-- https://discord.com/developers/docs/resources/guild#modify-current-user-voice-state
export type ModifyCurrentUserVoiceStateResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#modify-user-voice-state
export type ModifyUserVoiceStateResponse = Response<unknown>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#list-scheduled-events-for-guild
export type ListScheduledEventsForGuildResponse = Response<{ objects.GuildScheduledEventObject }>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event
export type CreateGuildScheduledEventResponse = Response<objects.GuildScheduledEventObject>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event
export type GetGuildScheduledEventResponse = Response<objects.GuildScheduledEventObject>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event
export type ModifyGuildScheduledEventResponse = Response<objects.GuildScheduledEventObject>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#delete-guild-scheduled-event
export type DeleteGuildScheduledEventResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event-users
export type GetGuildScheduledEventUsersResponse = Response<{ objects.GuildScheduledEventUserObject }>

-- https://discord.com/developers/docs/resources/guild-template#get-guild-template
export type GetGuildTemplateResponse = Response<objects.GuildTemplateObject>

-- https://discord.com/developers/docs/resources/guild-template#create-guild-from-guild-template
export type CreateGuildFromGuildTemplateResponse = Response<objects.GuildObject>

-- https://discord.com/developers/docs/resources/guild-template#get-guild-templates
export type GetGuildTemplatesResponse = Response<objects.GuildTemplateObject>

-- https://discord.com/developers/docs/resources/guild-template#create-guild-template
export type CreateGuildTemplateResponse = Response<objects.GuildTemplateObject>

-- https://discord.com/developers/docs/resources/guild-template#sync-guild-template
export type SyncGuildTemplateResponse = Response<objects.GuildTemplateObject>

-- https://discord.com/developers/docs/resources/guild-template#modify-guild-template
export type ModifyGuildTemplateResponse = Response<objects.GuildTemplateObject>

-- https://discord.com/developers/docs/resources/guild-template#delete-guild-template
export type DeleteGuildTemplateResponse = Response<objects.GuildTemplateObject>

-- https://discord.com/developers/docs/resources/invite#get-invite
export type GetInviteResponse = Response<objects.InviteObject>

-- https://discord.com/developers/docs/resources/invite#delete-invite
export type DeleteInviteResponse = Response<objects.InviteObject>

-- https://discord.com/developers/docs/resources/poll#get-answer-voters
export type GetAnswerVotersResponse = Response<{ objects.UserObject }>

-- https://discord.com/developers/docs/resources/poll#end-poll
export type EndPollResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
export type CreateStageInstanceResponse = Response<objects.StageInstanceObject>

-- https://discord.com/developers/docs/resources/stage-instance#get-stage-instance
-- discord-fixme: make a PR to declare what this API returns.
export type GetStageInstanceResponse = Response<objects.StageInstanceObject>

-- https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
export type ModifyStageInstanceResponse = Response<objects.StageInstanceObject>

-- https://discord.com/developers/docs/resources/stage-instance#delete-stage-instance
export type DeleteStageInstanceResponse = Response<nil>

-- https://discord.com/developers/docs/resources/sticker#get-sticker
export type GetStickerResponse = Response<objects.StickerObject>

-- https://discord.com/developers/docs/resources/sticker#list-sticker-packs
export type ListStickerPacksResponse = Response<{
	sticker_packs: { objects.StickerPackObject }, -- array of sticker pack objects
}>

-- https://discord.com/developers/docs/resources/sticker#list-guild-stickers
export type ListGuildStickersResponse = Response<{ objects.StickerObject }>

-- https://discord.com/developers/docs/resources/sticker#get-guild-sticker
export type GetGuildStickerResponse = Response<objects.StickerObject>

-- https://discord.com/developers/docs/resources/sticker#create-guild-sticker
export type CreateGuildStickerResponse = Response<objects.StickerObject>

-- https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
export type ModifyGuildStickerResponse = Response<objects.StickerObject>

-- https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
export type DeleteGuildStickerResponse = Response<nil>

-- https://discord.com/developers/docs/resources/user#get-current-user
export type GetCurrentUserResponse = Response<objects.UserObject>

-- https://discord.com/developers/docs/resources/user#get-user
export type GetUserResponse = Response<objects.UserObject>

-- https://discord.com/developers/docs/resources/user#modify-current-user
export type ModifyCurrentUserResponse = Response<objects.UserObject>

-- https://discord.com/developers/docs/resources/user#get-current-user-guilds
export type GetCurrentUserGuildsResponse = Response<{ objects.GuildObject }>

-- https://discord.com/developers/docs/resources/user#get-current-user-guild-member
export type GetCurrentUserGuildMemberResponse = Response<objects.GuildMemberObject>

-- https://discord.com/developers/docs/resources/user#leave-guild
export type LeaveGuildResponse = Response<nil>

-- https://discord.com/developers/docs/resources/user#create-dm
export type CreateDMResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/user#create-group-dm
export type CreateGroupDMResponse = Response<objects.ChannelObject>

-- https://discord.com/developers/docs/resources/user#get-current-user-connections
export type GetCurrentUserConnectionResponse = Response<objects.ConnectionObject>

-- https://discord.com/developers/docs/resources/user#get-current-user-application-role-connection
export type GetCurrentUserApplicationRoleConnectionResponse = Response<objects.ApplicationRoleConnectionObject>

-- https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
export type UpdateCurrentUserApplicationRoleConnectionResponse = Response<objects.ApplicationRoleConnectionObject>

-- https://discord.com/developers/docs/resources/voice
export type ListVoiceRegionsResponse = Response<{ objects.VoiceRegionObject }>

-- https://discord.com/developers/docs/resources/webhook#create-webhook
export type CreateWebhookResponse = Response<objects.WebhookObject>

-- https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
export type GetChannelWebhooksResponse = Response<{ objects.WebhookObject }>

-- https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
export type GetGuildWebhooksResponse = Response<{ objects.WebhookObject }>

-- https://discord.com/developers/docs/resources/webhook#get-webhook
export type GetWebhookResponse = Response<objects.WebhookObject>

-- https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
export type GetWebhookWithTokenResponse = Response<objects.WebhookObject>

-- https://discord.com/developers/docs/resources/webhook#modify-webhook
export type ModifyWebhookResponse = Response<objects.WebhookObject>

-- https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
export type ModifyWebhookWithTokenResponse = Response<objects.WebhookObject>

-- https://discord.com/developers/docs/resources/webhook#delete-webhook
export type DeleteWebhookResponse = Response<nil>

-- https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
export type DeleteWebhookWitHTokenResponse = Response<nil>

-- https://discord.com/developers/docs/resources/webhook#execute-webhook
export type ExecuteWebhook = Response<objects.MessageObject?>

-- https://discord.com/developers/docs/resources/webhook#execute-slackcompatible-webhook
export type ExecuteSlackCompatibleWebhookResponse = Response<unknown>

-- https://discord.com/developers/docs/resources/webhook#execute-githubcompatible-webhook
export type ExecuteGitCompatibleWebhookResponse = Response<unknown>

-- https://discord.com/developers/docs/resources/webhook#get-webhook-message
export type GetWebhookMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/resources/webhook#edit-webhook-message
export type EditWebhookMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/resources/webhook#delete-webhook-message
export type DeleteWebhookMessageResponse = Response<nil>

-- https://discord.com/developers/docs/topics/gateway#get-gateway
export type GetGatewayResponse = Response<{
	url: string, -- WSS URL that can be used for connecting to the Gateway
}>

-- https://discord.com/developers/docs/topics/gateway#get-gateway-bot
export type GetGatewayBotResponse = Response<{
	url: string, -- WSS URL that can be used for connecting to the Gateway
	shards: number, -- Recommended number of shards to use when connecting
	session_start_limit: objects.SessionStartLimitObject, -- Information on the current session start limit
}>

return "DISCORD_V10_PAYLOAD_TYPES"
