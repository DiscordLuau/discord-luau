--[=[
	@class StdPolyfills.rest.types

	Mapping out all discord responses that we can get from the Discord v10 REST/HTTP API.
]=]

local objects = require("../apiTypes")

-- [[ Base ]] --
export type Response<DATA> = DATA
export type Request<DATA> = DATA

-- [[ Requests ]] --

-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-interaction-response
export type CreateInteractionRequest = Request<objects.InteractionResponseObject>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-original-interaction-response
export type EditOriginalInteractionRequest = Request<objects.Partial<objects.MessageObject>>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
export type CreateFollowupMessageRequest = Request<objects.Partial<objects.MessageObject>>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
export type EditFollowupMessageRequest = Request<objects.Partial<objects.MessageObject>>

-- https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
export type CreateAutoModerationRuleRequest = Request<{
	name: string, -- the rule name
	event_type: objects.AutomoderationRuleEventType, -- the event type
	trigger_type: objects.AutomoderationRuleTriggerType, -- the trigger type
	trigger_metadata: objects.AutomoderationRuleTriggerMetadataObject?, -- the trigger metadata
	actions: { objects.AutomoderationActionObject }, -- the actions which will execute when the rule is triggered
	enabled: boolean?, -- whether the rule is enabled (False by default)
	exempt_roles: { objects.Snowflake }?, -- the role ids that should not be affected by the rule (Maximum of 20)
	exempt_channels: { objects.Snowflake }?, -- the channel ids that should not be affected by the rule (Maximum of 50)
}>

-- https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule
export type ModifyAutoModerationRuleRequest = Request<{
	name: string, -- the rule name
	event_type: objects.AutomoderationRuleEventType, -- the event type
	trigger_metadata: objects.AutomoderationRuleTriggerMetadataObject?, -- the trigger metadata
	actions: { objects.AutomoderationActionObject }, -- the actions which will execute when the rule is triggered
	enabled: boolean?, -- whether the rule is enabled (False by default)
	exempt_roles: { objects.Snowflake }?, -- the role ids that should not be affected by the rule (Maximum of 20)
	exempt_channels: { objects.Snowflake }?, -- the channel ids that should not be affected by the rule (Maximum of 50)
}>

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

-- https://discord.com/developers/docs/resources/channel#modify-channel
export type ModifyChannelRequest = Request<{
	name: string?, -- 1-100 character channel name
	type: objects.ChannelType, -- the type of channel; only conversion between text and announcement is supported and only in guilds with the "NEWS" feature
	icon: string?, -- (if a group DM, the base64 encoded icon for the group DM)
	position: number?, -- the position of the channel in the left-hand listing (channels with the same position are sorted by id)
	topic: string?, -- 0-1024 character channel topic (0-4096 characters for GUILD_FORUM and GUILD_MEDIA channels)
	nsfw: boolean?, -- whether the channel is nsfw
	rate_limit_per_user: number?, -- amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission manage_messages or manage_channel, are unaffected
	bitrate: number?, -- the bitrate (in bits) of the voice or stage channel; min 8000
	user_limit: number?, -- the user limit of the voice or stage channel, max 99 for voice channels and 10,000 for stage channels (0 refers to no limit)
	permission_overwrites: { objects.OverwriteObject }?, -- channel or category-specific permissions
	parent_id: objects.Snowflake?, -- id of the new parent category for a channel
	rtc_region: string?, -- channel voice region id, automatic when set to null
	video_quality_mode: objects.VideoQualityMode, -- the camera video quality mode of the voice channel
	default_auto_archive_duration: number?, -- the default duration that the clients use (not the API) for newly created threads in the channel, in minutes, to automatically archive the thread after recent activity
	flags: number?, -- channel flags combined as a bitfield. Currently only REQUIRE_TAG (1 << 4) is supported by GUILD_FORUM and GUILD_MEDIA channels. HIDE_MEDIA_DOWNLOAD_OPTIONS (1 << 15) is supported only by GUILD_MEDIA channels
	available_tags: { objects.ForumTagObject }?, -- the set of tags that can be used in a GUILD_FORUM or a GUILD_MEDIA channel; limited to 20
	default_reaction_emoji: objects.DefaultReactionObject?, -- the emoji to show in the add reaction button on a thread in a GUILD_FORUM or a GUILD_MEDIA channel
	default_thread_rate_limit_per_user: number?, -- the initial rate_limit_per_user to set on newly created threads in a channel. this field is copied to the thread at creation time and does not live update.
	default_sort_order: objects.SortOrderType?, -- the default sort order type used to order posts in GUILD_FORUM and GUILD_MEDIA channels
	default_forum_layout: objects.ForumLayoutType?, -- the default forum layout type used to display posts in GUILD_FORUM channels
}>

-- https://discord.com/developers/docs/resources/channel#create-message
export type CreateMessageRequest = Request<{
	content: string?, -- Message contents (up to 2000 characters)
	nonce: (string | number)?, -- Can be used to verify a message was sent (up to 25 characters). Value will appear in the Message Create event.
	tts: boolean?, -- true if this is a TTS message
	embeds: { objects.EmbedObject }?, -- Up to 10 rich embeds (up to 6000 characters)
	allowed_mentions: objects.AllowedMentionObject?, -- Allowed mentions for the message
	message_reference: objects.MessageReferenceObject?, -- Include to make your message a reply or a forward
	components: { objects.ComponentObjects }?, -- Components to include with the message
	sticker_ids: { objects.Snowflake }?, -- IDs of up to 3 stickers in the server to send in the message
	-- files: { },
	-- payload_json: string,
	attachments: { objects.AttachmentObject }?, -- Attachment objects with filename and description. See Uploading Files
	flags: number?, -- Message flags combined as a bitfield (only SUPPRESS_EMBEDS and SUPPRESS_NOTIFICATIONS can be set)
	enforce_nonce: boolean?, -- If true and nonce is present, it will be checked for uniqueness in the past few minutes. If another message was created by the same author with the same nonce, that message will be returned and no new message will be created.
	poll: objects.PollObject?, -- The discord poll object
}>

-- https://discord.com/developers/docs/resources/channel#edit-message
export type EditMessageRequest = Request<{
	content: string?, -- Message contents (up to 2000 characters)
	embeds: { objects.EmbedObject }?, -- Up to 10 rich embeds (up to 6000 characters)
	allowed_mentions: { objects.AllowedMentionObject }?, -- Allowed mentions for the message
	components: { objects.ComponentObjects }?, -- Components to include with the message
	-- files: { },
	-- payload_json: string,
	attachments: { objects.AttachmentObject }?, -- Attachment objects with filename and description. See Uploading Files
	flags: number?, -- Message flags combined as a bitfield (only SUPPRESS_EMBEDS and SUPPRESS_NOTIFICATIONS can be set)
}>

-- https://discord.com/developers/docs/resources/channel#create-channel-invite
export type CreateChannelInviteRequest = Request<{
	max_age: number?, -- duration of invite in seconds before expiry, or 0 for never. between 0 and 604800 (7 days)
	max_uses: number?, -- max number of uses or 0 for unlimited. between 0 and 100
	temporary: boolean?, -- whether this invite only grants temporary membership
	unique: boolean?, -- if true, don't try to reuse a similar invite (useful for creating many unique one time use invites)
	target_type: objects.InviteTargetTypes?, -- the type of target for this voice channel invite
	target_user_id: objects.Snowflake?, -- the id of the user whose stream to display for this invite, required if target_type is 1, the user must be streaming in the channel
	target_application_id: objects.Snowflake?, -- the id of the embedded application to open for this invite, required if target_type is 2, the application must have the EMBEDDED flag
}>

-- https://discord.com/developers/docs/resources/channel#bulk-delete-messages
export type BulkDeleteMessagesRequest = Request<{
	messages: { objects.Snowflake },
}>

-- https://discord.com/developers/docs/resources/channel#follow-announcement-channel
export type FollowAnnouncementChannelRequest = Request<{
	webhook_channel_id: objects.Snowflake, -- id of target channel
}>

-- https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
export type GroupDMAddRecipientRequest = Request<{
	access_token: string, -- access token of a user that has granted your app the gdm.join scope
	nick: string, -- nickname of the user being added
}>

-- https://discord.com/developers/docs/resources/channel#start-thread-from-message
export type StartThreadFromMessageRequest = Request<{
	name: string, -- 1-100 character channel name
	auto_archive_duration: number?, -- the thread will stop showing in the channel list after auto_archive_duration minutes of inactivity, can be set to: 60, 1440, 4320, 10080
	rate_limit_per_user: number?, -- amount of seconds a user has to wait before sending another message (0-21600)
}>

-- https://discord.com/developers/docs/resources/channel#start-thread-without-message
export type StartThreadWithoutMessageRequest = Request<{
	name: string, -- 1-100 character channel name
	auto_archive_duration: number?, -- the thread will stop showing in the channel list after auto_archive_duration minutes of inactivity, can be set to: 60, 1440, 4320, 10080
	type: objects.ChannelType?, -- the type of thread to create
	invitable: boolean?, -- whether non-moderators can add other non-moderators to a thread; only available when creating a private thread
	rate_limit_per_user: number?, -- amount of seconds a user has to wait before sending another message (0-21600)
}>

-- https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
export type StartThreadInForumOrMediaChannelRequest = Request<{
	name: string, -- 1-100 character channel name
	auto_archive_duration: number?, -- the thread will stop showing in the channel list after auto_archive_duration minutes of inactivity, can be set to: 60, 1440, 4320, 10080
	rate_limit_per_user: number?, -- amount of seconds a user has to wait before sending another message (0-21600)
	--files: { },
	-- payload_json: string,
	applied_tags: { objects.Snowflake }?, -- the IDs of the set of tags that have been applied to a thread in a GUILD_FORUM or a GUILD_MEDIA channel
	message: objects.ForumAndMediaThreadMessageObject?, -- contents of the first message in the forum/media thread
}>

-- https://discord.com/developers/docs/resources/emoji#create-guild-emoji
export type CreateGuildEmojiRequest = Request<{
	name: string, -- name of the emoji
	image: string, -- the 128x128 emoji image
	roles: { objects.Snowflake }, -- roles allowed to use this emoji
}>

-- https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
export type ModifyGuildEmojiRequest = Request<{
	name: string, -- name of the emoji
	roles: { objects.Snowflake }, -- roles allowed to use this emoji
}>

-- https://discord.com/developers/docs/resources/guild#create-guild
export type CreateGuildRequest = Request<{
	name: string, -- name of the guild (2-100 characters)
	region: string?, -- voice region id (deprecated)
	icon: string?, -- base64 128x128 image for the guild icon
	verification_level: objects.VerificationLevel?, -- verification level
	default_message_notifications: objects.DefaultMessageNotification?, -- default message notification level
	explicit_content_filter: objects.ExplicitContentFilterLevel?, -- explicit content filter level
	roles: { objects.GuildRoleObject }?, -- new guild roles
	channels: { objects.ChannelObject }?, -- new guild's channels
	afk_channel_id: objects.Snowflake?, -- id for afk channel
	afk_timeout: number?, -- afk timeout in seconds, can be set to: 60, 300, 900, 1800, 3600
	system_channel_id: objects.Snowflake?, -- the id of the channel where guild notices such as welcome messages and boost events are posted
	system_channel_flags: objects.SystemChannelFlags?, -- system channel flags
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild
export type ModifyGuildRequest = Request<
	objects.Partial<{
		name: string, -- guild name
		verification_level: objects.VerificationLevel?, -- verification level
		default_message_notifications: objects.DefaultMessageNotification?, -- default message notification level
		explicit_content_filter: objects.ExplicitContentFilterLevel?, -- explicit content filter level
		afk_channel_id: objects.Snowflake?, -- id for afk channel
		afk_timeout: number?, -- afk timeout in seconds, can be set to: 60, 300, 900, 1800, 3600
		icon: string?, -- base64 1024x1024 png/jpeg/gif image for the guild icon (can be animated gif when the server has the ANIMATED_ICON feature)
		owner_id: objects.Snowflake, -- user id to transfer guild ownership to (must be owner)
		splash: string?, -- base64 16:9 png/jpeg image for the guild splash (when the server has the INVITE_SPLASH feature)
		discovery_splash: string?, -- base64 16:9 png/jpeg image for the guild discovery splash (when the server has the DISCOVERABLE feature)
		banner: string?, -- base64 16:9 png/jpeg image for the guild banner (when the server has the BANNER feature; can be animated gif when the server has the ANIMATED_BANNER feature)
		system_channel_id: objects.Snowflake?, -- the id of the channel where guild notices such as welcome messages and boost events are posted
		system_channel_flags: objects.SystemChannelFlags?, -- system channel flags
		rules_channel_id: objects.Snowflake?, -- the id of the channel where Community guilds display rules and/or guidelines
		public_updates_channel_id: objects.Snowflake?, -- the id of the channel where admins and moderators of Community guilds receive notices from Discord
		preferred_locale: objects.LanguageLocales?, -- the preferred locale of a Community guild used in server discovery and notices from Discord; defaults to "en-US"
		features: { objects.GuildFeature }?, -- enabled guild features
		description: string?, -- the description for the guild
		premium_progress_bar_enabled: boolean?, -- whether the guild's boost progress bar should be enabled
		safety_alerts_channel_id: objects.Snowflake?, -- the id of the channel where admins and moderators of Community guilds receive safety alerts from Discord
	}>
>

-- https://discord.com/developers/docs/resources/guild#create-guild-channel
export type CreateGuildChannelRequest = Request<
	objects.Partial<{
		name: string, -- channel name (1-100 characters)
		type: objects.ChannelType, -- the type of channel
		topic: string?, -- channel topic (0-1024 characters)
		bitrate: number?, -- the bitrate (in bits) of the voice or stage channel; min 8000
		user_limit: number?, -- the user limit of the voice channel
		rate_limit_per_user: number?, -- amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission manage_messages or manage_channel, are unaffected
		position: number, -- sorting position of the channel (channels with the same position are sorted by id)
		permission_overwrites: { objects.OverwriteObject }, -- the channel's permission overwrites
		parent_id: objects.Snowflake?, -- id of the parent category for a channel
		nsfw: boolean?, -- whether the channel is nsfw
		rtc_region: string?, -- channel voice region id of the voice or stage channel, automatic when set to null
		video_quality_mode: objects.VideoQualityMode?, -- the camera video quality mode of the voice channel
		default_auto_archive_duration: number?, -- the default duration that the clients use (not the API) for newly created threads in the channel, in minutes, to automatically archive the thread after recent activity
		default_reaction_emoji: objects.EmojiObject?, -- emoji to show in the add reaction button on a thread in a GUILD_FORUM or a GUILD_MEDIA channel
		available_tags: { objects.ForumTagObject }?, -- set of tags that can be used in a GUILD_FORUM or a GUILD_MEDIA channel
		default_sort_order: objects.SortOrderType?, -- the default sort order type used to order posts in GUILD_FORUM and GUILD_MEDIA channels
		default_forum_layout: objects.ForumLayoutType?, -- the default forum layout view used to display posts in GUILD_FORUM channels
		default_thread_rate_limit_per_user: number?, -- the initial rate_limit_per_user to set on newly created threads in a channel. this field is copied to the thread at creation time and does not live update.
	}>
>

-- https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
export type ModifyGuildChannelPositionsRequest = Request<
	{
		{
			id: objects.Snowflake, -- channel id
			position: number?, -- sorting position of the channel (channels with the same position are sorted by id)
			lock_permissions: boolean?, -- syncs the permission overwrites with the new parent, if moving to a new category
			parent_id: objects.Snowflake?, -- the new parent ID for the channel that is moved
		}
	}
>

-- https://discord.com/developers/docs/resources/guild#add-guild-member
export type AddGuildMemberRequest = Request<{
	access_token: string, -- an oauth2 access token granted with the guilds.join to the bot's application for the user you want to add to the guild
	nick: string?, -- value to set user's nickname to
	roles: { objects.Snowflake }?, -- array of role ids the member is assigned
	mute: boolean?, -- whether the user is muted in voice channels
	deaf: boolean?, -- whether the user is deafened in voice channels
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild-member
export type ModifyGuildMemberRequest = Request<{
	nick: string?, -- value to set user's nickname to
	roles: { objects.Snowflake }?, -- array of role ids the member is assigned
	mute: boolean?, -- whether the user is muted in voice channels. Will throw a 400 error if the user is not in a voice channel
	deaf: boolean?, -- whether the user is deafened in voice channels. Will throw a 400 error if the user is not in a voice channel
	channel_id: (objects.Snowflake | boolean)?, -- id of channel to move user to (if they are connected to voice)
	communication_disabled_until: string?, -- when the user's timeout will expire and the user will be able to communicate in the guild again (up to 28 days in the future), set to null to remove timeout. Will throw a 403 error if the user has the ADMINISTRATOR permission or is the owner of the guild
	flags: objects.GuildMemberFlags?, -- guild member flags
}>

-- https://discord.com/developers/docs/resources/guild#modify-current-member
export type ModifyCurrentMemberRequest = Request<{
	nick: string, -- value to set user's nickname to
}>

-- https://discord.com/developers/docs/resources/guild#create-guild-ban
export type CreateGuildBanRequest = Request<{
	delete_message_days: number?, -- number of days to delete messages for (0-7) (deprecated)
	delete_message_seconds: number?, -- number of seconds to delete messages for, between 0 and 604800 (7 days)
}>

-- https://discord.com/developers/docs/resources/guild#bulk-guild-ban
export type BulkGuildBanRequest = Request<{
	user_ids: { objects.Snowflake }, -- list of user ids to ban (max 200)
	delete_message_seconds: number?, -- number of seconds to delete messages for, between 0 and 604800 (7 days)
}>

-- https://discord.com/developers/docs/resources/guild#create-guild-role
export type CreateGuildRoleRequest = Request<{
	name: string?, -- name of the role, max 100 characters
	permissions: string?, -- bitwise value of the enabled/disabled permissions
	color: number?, -- RGB color value
	hoist: boolean?, -- whether the role should be displayed separately in the sidebar
	icon: string?, -- the role's icon image (if the guild has the ROLE_ICONS feature)
	unicode_emoji: string?, -- the role's unicode emoji as a standard emoji (if the guild has the ROLE_ICONS feature)
	mentionable: boolean?, -- whether the role should be mentionable
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
export type ModifyGuildRolePositionsRequest = Request<{
	id: objects.Snowflake, -- the target role id
	position: number, -- sorting position of the role (roles with the same position are sorted by id)
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild-role
export type ModifyGuildRoleRequest = Request<{
	name: string?, -- name of the role, max 100 characters
	permissions: string?, -- bitwise value of the enabled/disabled permissions
	color: number?, -- RGB color value
	hoist: boolean?, -- whether the role should be displayed separately in the sidebar
	icon: string?, -- the role's icon image (if the guild has the ROLE_ICONS feature)
	unicode_emoji: string?, -- the role's unicode emoji as a standard emoji (if the guild has the ROLE_ICONS feature)
	mentionable: boolean?, -- whether the role should be mentionable
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
export type ModifyGuildMFALevelRequest = Request<{
	level: objects.MFALevel, -- The updated MFA level
}>

-- https://discord.com/developers/docs/resources/guild#begin-guild-prune
export type BeginGuildPruneRequest = Request<{
	days: number, -- number of days to prune (1-30)
	compute_prune_count: boolean, -- whether pruned is returned, discouraged for large guilds
	include_ruoles: { objects.Snowflake }, -- role(s) to include
	reason: string?, -- reason for the prune (deprecated)
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
export type ModifyGuildWelcomeScreenRequest = Request<{
	enabled: boolean?, -- whether the welcome screen is enabled
	welcome_channels: { objects.WelcomeScreenChannelObject }, -- channels linked in the welcome screen and their display options
	description: string?, -- the server description to show in the welcome screen
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
export type ModifyGuildOnboardingRequest = Request<{
	prompts: { objects.OnboardingPromptObject }?, -- Prompts shown during onboarding and in customize community
	default_channel_ids: { objects.Snowflake }?, -- Channel IDs that members get opted into automatically
	enabled: boolean?, -- Whether onboarding is enabled in the guild
	mode: objects.OnboardingMode?, -- Current mode of onboarding
}>

-- https://discord.com/developers/docs/resources/guild#modify-current-user-voice-state
export type ModifyCurrentUserVoiceStateRequest = Request<{
	channel_id: objects.Snowflake?, -- the id of the channel the user is currently in
	suppress: boolean?, -- toggles the user's suppress state
	request_to_speak_timestamp: string?, -- sets the user's request to speak
}>

-- https://discord.com/developers/docs/resources/guild#modify-user-voice-state
export type ModifyUserVoiceStateRequest = Request<{
	channel_id: objects.Snowflake?, -- the id of the channel the user is currently in
	suppress: boolean?, -- toggles the user's suppress state
}>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event
export type CreateGuildScheduledEventRequest = Request<{
	channel_id: objects.Snowflake?, -- the channel id of the scheduled event.
	entity_metadata: objects.GuildScheduledEventEntityMetadata, -- the entity metadata of the scheduled event
	name: string, -- the name of the scheduled event
	privacy_level: objects.PrivacyLevel, -- the privacy level of the scheduled event
	scheduled_start_time: string, -- the time to schedule the scheduled event
	scheduled_end_time: string?, -- the time when the scheduled event is scheduled to end
	description: string?, -- the description of the scheduled event
	entity_type: objects.GuildScheduledEventEntityType, -- the entity type of the scheduled event
	image: string?, -- the cover image of the scheduled event
}>

-- https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event
export type ModifyGuildScheduledEventRequest = Request<{
	channel_id: objects.Snowflake?, -- the channel id of the scheduled event.
	entity_metadata: objects.GuildScheduledEventEntityMetadata, -- the entity metadata of the scheduled event
	name: string, -- the name of the scheduled event
	privacy_level: objects.PrivacyLevel, -- the privacy level of the scheduled event
	scheduled_start_time: string, -- the time to schedule the scheduled event
	scheduled_end_time: string?, -- the time when the scheduled event is scheduled to end
	description: string?, -- the description of the scheduled event
	entity_type: objects.GuildScheduledEventEntityType, -- the entity type of the scheduled event
	status: objects.GuildScheduledEventStatus?, -- the status of the scheduled event
	image: string?, -- the cover image of the scheduled event
}>

-- https://discord.com/developers/docs/resources/guild-template#create-guild-from-guild-template
export type CreateGuildFromGuildTemplateRequest = Request<{
	name: string, -- name of the guild (2-100 characters)
	icon: string?, -- base64 128x128 image for the guild icon
}>

-- https://discord.com/developers/docs/resources/guild-template#create-guild-template
export type CreateGuildTemplateRequest = Request<{
	name: string, -- name of the template (1-100 characters)
	description: string?, -- description for the template (0-120 characters)
}>

-- https://discord.com/developers/docs/resources/guild-template#modify-guild-template
export type ModifyGuildTemplateRequest = Request<{
	name: string?, -- name of the template (1-100 characters)
	description: string?, -- description for the template (0-120 characters)
}>

-- https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
export type CreateStageInstanceRequest = Request<{
	channel_id: objects.Snowflake, -- The id of the Stage channel
	topic: string, -- The topic of the Stage instance (1-120 characters)
	privacy_level: objects.PrivacyLevel?, -- The privacy level of the Stage instance (default GUILD_ONLY)
	send_start_notification: boolean?, -- Notify @everyone that a Stage instance has started
	guild_scheduled_event_id: objects.Snowflake?, -- The guild scheduled event associated with this Stage instance
}>

-- https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
export type ModifyStageInstanceRequest = Request<{
	topic: string, -- The topic of the Stage instance (1-120 characters)
	privacy_level: objects.PrivacyLevel, -- The privacy level of the Stage instance
}>

-- https://discord.com/developers/docs/resources/sticker#create-guild-sticker
export type CreateGuildStickerRequest = Request<{
	name: string, -- name of the sticker (2-30 characters)
	description: string, -- description of the sticker (empty or 2-100 characters)
	tags: { string }, -- autocomplete/suggestion tags for the sticker (max 200 characters)
	file: string, -- the sticker file to upload, must be a PNG, APNG, GIF, or Lottie JSON file, max 512 KiB
}>

-- https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
export type ModifyGuildStickerRequest = Request<{
	name: string, -- name of the sticker (2-30 characters)
	description: string?, -- description of the sticker (2-100 characters)
	tags: string, -- autocomplete/suggestion tags for the sticker (max 200 characters)
}>

-- https://discord.com/developers/docs/resources/user#modify-current-user
export type ModifyCurrentUserRequest = Request<{
	username: string, -- user's username, if changed may cause the user's discriminator to be randomized.
	avatar: string?, -- if passed, modifies the user's avatar
	banner: string?, -- if passed, modifies the user's banner
}>

-- https://discord.com/developers/docs/resources/user#create-dm
export type CreateDMRequest = Request<{
	recipient_id: objects.Snowflake, -- the recipient to open a DM channel with
}>

-- https://discord.com/developers/docs/resources/user#create-group-dm
export type CreateGroupDMRequest = Request<{
	access_tokens: { string }, -- access tokens of users that have granted your app the gdm.join scope
	nicks: { [objects.Snowflake]: string }, -- a dictionary of user ids to their respective nicknames
}>

-- https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
export type UpdateCurrentUserApplicationRoleConnectionRequest = Request<{
	platform_name: string?, -- the vanity name of the platform a bot has connected (max 50 characters)
	platform_username: string?, -- the username on the platform a bot has connected (max 100 characters)
	metadata: objects.ApplicationRoleConnectionMetadataObject?, -- object mapping application role connection metadata keys to their string-ified value (max 100 characters) for the user on the platform a bot has connected
}>

-- https://discord.com/developers/docs/resources/webhook#create-webhook
export type CreateWebhookRequest = Request<{
	name: string, -- name of the webhook (1-80 characters)
	avatar: string?, -- image for the default webhook avatar
}>

-- https://discord.com/developers/docs/resources/webhook#modify-webhook
export type ModifyWebhookRequest = Request<{
	name: string,
	avatar: string,
	channel_id: objects.Snowflake,
}>

-- https://discord.com/developers/docs/resources/webhook#execute-webhook
export type ExecuteWebhookRequest = Request<{
	content: string, -- the message contents (up to 2000 characters)
	username: string, -- override the default username of the webhook
	avatar_url: string, -- override the default avatar of the webhook
	tts: boolean, -- true if this is a TTS message
	embeds: { objects.EmbedObject }, -- embedded rich content
	allowed_mentions: objects.AllowedMentionObject, -- allowed mentions for the message
	components: { objects.ComponentObjects }, -- the components to include with the message
	-- files: { },
	-- payload_json: string,
	attachments: { objects.AttachmentObject }, -- attachment objects with filename and description
	flags: number, -- message flags combined as a bitfield (only SUPPRESS_EMBEDS and SUPPRESS_NOTIFICATIONS can be set can be set)
	thread_name: string, -- name of thread to create (requires the webhook channel to be a forum or media channel)
	applied_tags: { objects.Snowflake }, -- array of tag ids to apply to the thread (requires the webhook channel to be a forum or media channel)
	poll: objects.PollObject, -- discord poll
}>

-- https://discord.com/developers/docs/resources/webhook#execute-slackcompatible-webhook
export type ExecuteSlackCompatibleWebhookRequest = Request<{
	-- lol i dont want to look into block kit.. please use execute webhook request
	-- if that's not an option, feel free to contribute; https://api.slack.com/block-kit
}>

-- https://discord.com/developers/docs/resources/webhook#execute-githubcompatible-webhook
export type ExecuteGithubCompatibleWebhookRequest = Request<{
	-- ok, likewise with the slack comment, feel free to contribute; https://docs.github.com/en/webhooks/webhook-events-and-payloads
}>

-- https://discord.com/developers/docs/resources/webhook#edit-webhook-message
export type EditWebhookMessageRequest = Request<{
	content: string, -- the message contents (up to 2000 characters)
	embeds: { objects.EmbedObject }, -- embedded rich content
	allowed_mentions: objects.AllowedMentionObject, -- allowed mentions for the message
	components: { objects.ComponentObjects }, -- the components to include with the message
	-- files: { },
	-- payload_json: string,
	attachments: objects.AttachmentObject, -- attached files to keep and possible descriptions for new files
}>

-- https://discord.com/developers/docs/resources/channel#edit-channel-permissions
export type EditChannelPermissionsRequest = Request<{
	allow: string?, -- the bitwise value of all allowed permissions (default "0")
	deny: string?, -- the bitwise value of all disallowed permissions (default "0")
	type: number, -- 0 for a role or 1 for a member
}>

-- https://discord.com/developers/docs/resources/guild#modify-guild-widget
export type ModifyGuildWidgetRequest = Request<objects.GuildWidgetSettingsObject>

-- https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
export type CreateGlobalApplicationCommandRequest = Request<{
	name: string, -- Name of command, 1-32 characters
	name_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the name field. Values follow the same restrictions as name
	description: string?, -- 1-100 character description for CHAT_INPUT commands
	description_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the description field. Values follow the same restrictions as description
	options: { objects.ApplicationCommandOptionObject }?, -- the parameters for the command, max of 25
	default_member_permissions: string?, -- Set of permissions represented as a bit set
	dm_permission: boolean?, -- Deprecated (use contexts instead); Indicates whether the command is available in DMs with the app, only for globally-scoped commands. By default, commands are visible.
	default_permission: boolean, -- Replaced by default_member_permissions and will be deprecated in the future. Indicates whether the command is enabled by default when the app is added to a guild. Defaults to true
	integration_types: { objects.IntegrationType }?, -- Installation context(s) where the command is available
	contexts: { objects.InteractionContextType }?, -- Interaction context(s) where the command can be used
	type: objects.ApplicationCommandType?, -- Type of command, defaults 1 if not set
	nsfw: boolean?, -- Indicates whether the command is age-restricted
}>

-- https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
export type EditGlobalApplicationCommandRequest = Request<{
	name: string, -- Name of command, 1-32 characters
	name_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the name field. Values follow the same restrictions as name
	description: string?, -- 1-100 character description for CHAT_INPUT commands
	description_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the description field. Values follow the same restrictions as description
	options: { objects.ApplicationCommandOptionObject }?, -- the parameters for the command, max of 25
	default_member_permissions: string?, -- Set of permissions represented as a bit set
	dm_permission: boolean?, -- Deprecated (use contexts instead); Indicates whether the command is available in DMs with the app, only for globally-scoped commands. By default, commands are visible.
	default_permission: boolean, -- Replaced by default_member_permissions and will be deprecated in the future. Indicates whether the command is enabled by default when the app is added to a guild. Defaults to true
	integration_types: { objects.IntegrationType }?, -- Installation context(s) where the command is available
	contexts: { objects.InteractionContextType }?, -- Interaction context(s) where the command can be used
	nsfw: boolean?, -- Indicates whether the command is age-restricted
}>

-- https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
export type CreateGuildApplicationCommandRequest = Request<{
	name: string, -- Name of command, 1-32 characters
	name_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the name field. Values follow the same restrictions as name
	description: string?, -- 1-100 character description for CHAT_INPUT commands
	description_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the description field. Values follow the same restrictions as description
	options: { objects.ApplicationCommandOptionObject }?, -- the parameters for the command, max of 25
	default_member_permissions: string?, -- Set of permissions represented as a bit set
	dm_permission: boolean?, -- Deprecated (use contexts instead); Indicates whether the command is available in DMs with the app, only for globally-scoped commands. By default, commands are visible.
	default_permission: boolean, -- Replaced by default_member_permissions and will be deprecated in the future. Indicates whether the command is enabled by default when the app is added to a guild. Defaults to true
	integration_types: { objects.IntegrationType }?, -- Installation context(s) where the command is available
	contexts: { objects.InteractionContextType }?, -- Interaction context(s) where the command can be used
	type: objects.ApplicationCommandType?, -- Type of command, defaults 1 if not set
	nsfw: boolean?, -- Indicates whether the command is age-restricted
}>

-- https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
export type EditGuildApplicationCommandRequest = Request<{
	name: string, -- Name of command, 1-32 characters
	name_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the name field. Values follow the same restrictions as name
	description: string?, -- 1-100 character description for CHAT_INPUT commands
	description_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the description field. Values follow the same restrictions as description
	options: { objects.ApplicationCommandOptionObject }?, -- the parameters for the command, max of 25
	default_member_permissions: string?, -- Set of permissions represented as a bit set
	dm_permission: boolean?, -- Deprecated (use contexts instead); Indicates whether the command is available in DMs with the app, only for globally-scoped commands. By default, commands are visible.
	default_permission: boolean, -- Replaced by default_member_permissions and will be deprecated in the future. Indicates whether the command is enabled by default when the app is added to a guild. Defaults to true
	integration_types: { objects.IntegrationType }?, -- Installation context(s) where the command is available
	contexts: { objects.InteractionContextType }?, -- Interaction context(s) where the command can be used
	nsfw: boolean?, -- Indicates whether the command is age-restricted
}>

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
export type BulkOverwriteGlobalApplicationCommandsRequest = Request<{ objects.ApplicationCommandObject }>

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
export type BulkOverwriteGuildApplicationCommandsRequest = Request<
	{
		{
			id: objects.Snowflake?, -- ID of the command, if known
			name: string, -- Name of command, 1-32 characters
			name_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the name field. Values follow the same restrictions as name
			description: string?, -- 1-100 character description for CHAT_INPUT commands
			description_localizations: { [objects.LanguageLocales]: string }?, -- Localization dictionary for the description field. Values follow the same restrictions as description
			options: { objects.ApplicationCommandOptionObject }?, -- the parameters for the command, max of 25
			default_member_permissions: string?, -- Set of permissions represented as a bit set
			dm_permission: boolean?, -- Deprecated (use contexts instead); Indicates whether the command is available in DMs with the app, only for globally-scoped commands. By default, commands are visible.
			default_permission: boolean, -- Replaced by default_member_permissions and will be deprecated in the future. Indicates whether the command is enabled by default when the app is added to a guild. Defaults to true
			integration_types: { objects.IntegrationType }?, -- Installation context(s) where the command is available
			contexts: { objects.InteractionContextType }?, -- Interaction context(s) where the command can be used
			type: objects.ApplicationCommandType?, -- Type of command, defaults 1 if not set
			nsfw: boolean?, -- Indicates whether the command is age-restricted
		}
	}
>

-- https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
export type EditApplicationCommandPermissionsRequest = Request<{
	permissions: { objects.GuildApplicationCommandPermissionObject },
}>

-- [[ Responses ]] --

-- https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
export type GetCurrentUserVoiceStateResponse = Response<objects.VoiceStateObject>

-- https://discord.com/developers/docs/resources/voice#get-user-voice-state
export type GetUserVoiceStateResponse = Response<objects.VoiceStateObject>

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
export type GetGuildApplicationCommandPermissionsResponse = Response<
	{ objects.GuildApplicationCommandPermissionsObject }
>

-- https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
export type GetApplicationCommandPermissionsResponse = Response<{ objects.GuildApplicationCommandPermissionsObject }>

-- https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
export type EditApplicationCommandPermissionsResponse = Response<objects.GuildApplicationCommandPermissionsObject>

-- https://discord.com/developers/docs/resources/application#get-current-application
export type GetCurrentApplicationResponse = Response<{ objects.ApplicationObject }>

-- https://discord.com/developers/docs/resources/application#edit-current-application
export type EditCurrentApplicationResponse = Response<{ objects.ApplicationObject }>

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

-- https://discord.com/developers/docs/resources/guild#get-guild-roles
export type GetGuildRoleResponse = Response<objects.GuildRoleObject>

-- https://discord.com/developers/docs/resources/guild#create-guild-role
export type CreateGuildRoleResponse = Response<objects.GuildRoleObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
export type ModifyGuildRolePositionsResponse = Response<{ objects.GuildRoleObject }>

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
export type GetGuildInvitesResponse = Response<{ objects.InviteObject & objects.InviteMetadataObject }>

-- https://discord.com/developers/docs/resources/guild#get-guild-integrations
export type GetGuildIntegrationsResponse = Response<{ objects.IntegrationObject }>

-- https://discord.com/developers/docs/resources/guild#delete-guild-integration
export type DeleteGuildIntegrationResponse = Response<nil>

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
export type GetGuildWidgetSettingsResponse = Response<objects.GuildWidgetSettingsObject>

-- https://discord.com/developers/docs/resources/guild#modify-guild-widget
export type ModifyGuildWidgetResponse = Response<objects.GuildWidgetSettingsObject>

-- https://discord.com/developers/docs/resources/guild#get-guild-widget
export type GetGuildWidgetResponse = Response<objects.GuildWidgetObject>

-- https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
export type GetGuildVanityUrlResponse = Response<objects.GuildVanityUrl>

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
export type ExecuteWebhookResponse = Response<objects.MessageObject?>

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

-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-interaction-response
export type CreateInteractionResponse = Response<{
	resource: {
		message: objects.MessageObject?,
	},
}>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#get-original-interaction-response
export type GetOriginalInteractionResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-original-interaction-response
export type EditOriginalInteractionResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-original-interaction-response
export type DeleteOriginalInteractionResponse = Response<nil>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
export type CreateFollowupMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#get-followup-message
export type GetFollowupMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
export type EditFollowupMessageResponse = Response<objects.MessageObject>

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
export type DeleteFollowupMessageResponse = Response<nil>

return "DISCORD_V10_PAYLOAD_TYPES"
