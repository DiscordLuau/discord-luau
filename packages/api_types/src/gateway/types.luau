--[=[
	@class Types.gateway.types

	Mapping out all discord recieve/send payloads that can be consumed by the Discord v10 API.
]=]

local objects = require("../apiTypes")

-- [[ Base ]] --
export type Payload<DATA> = {
	op: number,
	d: DATA,
	s: number?,
	t: string?,
}

-- [[ Send Events - https://discord.com/developers/docs/topics/gateway-events#send-events ]] --

-- https://discord.com/developers/docs/topics/gateway-events#identify
export type IdentifyPayload = Payload<{
	token: string, -- Authentication token
	properties: objects.IdentifyPropertiesObject, -- Connection properties
	compress: boolean?, -- Whether this connection supports compression of packets
	large_threshold: number?, -- Value between 50 and 250, total number of members where the gateway will stop sending offline members in the guild member list
	shard: { number }?, -- Used for Guild Sharding
	presence: objects.ActivityObject?, -- Presence structure for initial presence information
	intents: number, -- Gateway Intents you wish to receive
}>

-- https://discord.com/developers/docs/topics/gateway-events#resume
export type ResumePayload = Payload<{
	token: string, -- Session token
	session_id: string, -- Session ID
	seq: number, -- Last sequence number received
}>

-- https://discord.com/developers/docs/topics/gateway-events#heartbeat
export type HeartbeatPayload = Payload<number>

-- https://discord.com/developers/docs/topics/gateway-events#request-guild-members
export type RequestGuildMembersPayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild to get members for
	query: string?, -- string that username starts with, or an empty string to return all members
	limit: number, -- maximum number of members to send matching the query; a limit of 0 can be used with an empty string query to return all members
	presences: boolean?, -- used to specify if we want the presences of the matched members
	user_ids: { objects.Snowflake }?, -- used to specify which users you wish to fetch
	nonce: string?, -- nonce to identify the Guild Members Chunk response
}>

-- https://discord.com/developers/docs/topics/gateway-events#update-voice-state
export type UpdateVoiceStatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	channel_id: string?, -- ID of the voice channel client wants to join (null if disconnecting)
	self_mute: boolean, -- Whether the client is muted
	self_deaf: boolean, -- Whether the client deafened
}>

-- https://discord.com/developers/docs/topics/gateway-events#update-presence
export type UpdatePresencePayload = Payload<objects.PresenceObject>

-- [[ Receive Events - https://discord.com/developers/docs/topics/gateway-events#receive-events ]] --

-- https://discord.com/developers/docs/topics/gateway-events#hello
export type HelloPayload = Payload<{
	heartbeat_interval: number, -- Interval (in milliseconds) an app should heartbeat with
}>

-- https://discord.com/developers/docs/topics/gateway-events#ready
export type ReadyPayload = Payload<{
	v: number,
	user: objects.UserObject,
	guilds: { objects.UnavailableGuildObject },
	session_id: string,
	resume_gateway_url: string,
	shard: { number }?,
	application: objects.ApplicationObject,
}>

-- https://discord.com/developers/docs/topics/gateway-events#resumed
export type ResumedPayload = Payload<nil>

-- https://discord.com/developers/docs/topics/gateway-events#reconnect
export type ReconnectPayload = Payload<boolean>

-- https://discord.com/developers/docs/topics/gateway-events#invalid-session
export type InvalidSessionPayload = Payload<boolean?>

-- https://discord.com/developers/docs/topics/gateway-events#auto-moderation-rule-create
export type ApplicationCommandPermissionsCreatePayload = Payload<objects.AutomoderationRuleObject>

-- https://discord.com/developers/docs/topics/gateway-events#application-command-permissions-update
export type ApplicationCommandPermissionsUpdatePayload = Payload<objects.AutomoderationRuleObject>

-- https://discord.com/developers/docs/topics/gateway-events#auto-moderation-rule-delete
export type ApplicationCommandPermissionsDeletePayload = Payload<objects.AutomoderationRuleObject>

-- https://discord.com/developers/docs/topics/gateway-events#auto-moderation-action-execution
export type ApplicationCommandPermissionsExecutionPayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild in which action was executed
	action: objects.AutomoderationActionObject, -- Action which was executed
	rule_id: objects.Snowflake, -- ID of the rule which action belongs to
	rule_trigger_type: objects.AutomoderationRuleTriggerType, -- Trigger type of rule which was triggered
	user_id: objects.Snowflake, -- ID of the user which generated the content which triggered the rule
	channel_id: objects.Snowflake?, -- ID of the channel in which user content was posted
	message_id: objects.Snowflake?, -- ID of any user message which content belongs to *
	alert_system_message_id: objects.Snowflake?, -- ID of any system auto moderation messages posted as a result of this action **
	content: string, -- User-generated text content
	matched_keyword: string?, -- Word or phrase configured in the rule that triggered the rule
	matched_content: string?, -- Substring in content that triggered the rule
}>

-- https://discord.com/developers/docs/topics/gateway-events#channel-create
export type CreateChannelPayload = Payload<objects.ChannelObject>

-- https://discord.com/developers/docs/topics/gateway-events#channel-update
export type UpdateChannelPayload = Payload<objects.ChannelObject>

-- https://discord.com/developers/docs/topics/gateway-events#channel-delete
export type DeleteChannelPayload = Payload<objects.ChannelObject>

-- https://discord.com/developers/docs/topics/gateway-events#channel-pins-update
export type ChannelPinsUpdatePayload = Payload<{
	guild_id: objects.Snowflake?,
	channel_id: objects.Snowflake,
	last_pin_timestamp: string?,
}>

-- https://discord.com/developers/docs/topics/gateway-events#thread-create
export type CreateThreadPayload = Payload<objects.ChannelObject>

-- https://discord.com/developers/docs/topics/gateway-events#thread-update
export type UpdateThreadPayload = Payload<objects.ChannelObject>

-- https://discord.com/developers/docs/topics/gateway-events#thread-delete
export type DeleteThreadPayload = Payload<objects.ChannelObject>

-- https://discord.com/developers/docs/topics/gateway-events#thread-list-sync
export type ThreadListSyncPayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	channel_ids: { objects.Snowflake }?, -- Parent channel IDs whose threads are being synced. If omitted, then threads were synced for the entire guild. This array may contain channel_ids that have no active threads as well, so you know to clear that data.
	threads: { objects.ChannelObject }, -- All active threads in the given channels that the current user can access
	members: { objects.ThreadMemberObject }, -- All thread member objects from the synced threads for the current user, indicating which threads the current user has been added to
}>

-- https://discord.com/developers/docs/topics/gateway-events#thread-member-update
export type ThreadMemberUpdatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
}>

-- https://discord.com/developers/docs/topics/gateway-events#thread-member-update
export type ThreadMembersUpdatePayload = Payload<{
	id: objects.Snowflake, -- ID of the thread
	guild_id: objects.Snowflake, -- ID of the guild
	member_count: number, -- Approximate number of members in the thread, capped at 50
	added_members: { objects.ThreadMemberObject }?, -- Users who were added to the thread
	removed_member_ids: { objects.Snowflake }?, -- ID of the users who were removed from the thread
}>

-- https://discord.com/developers/docs/topics/gateway-events#entitlement-create
export type EntitlementCreatePayload = Payload<objects.EntitlementObject>

-- https://discord.com/developers/docs/topics/gateway-events#entitlement-update
export type EntitlementUpdatePayload = Payload<objects.EntitlementObject>

-- https://discord.com/developers/docs/topics/gateway-events#entitlement-delete
export type EntitlementDeletePayload = Payload<objects.EntitlementObject>

-- https://discord.com/developers/docs/topics/gateway-events#guild-create
export type GuildCreatePayload = Payload<
	objects.UnavailableGuildObject | (objects.GuildObject & {
		joined_at: string, -- When this guild was joined at
		large: boolean, -- true if this is considered a large guild
		unavailable: boolean?, -- true if this guild is unavailable due to an outage
		member_count: number, -- Total number of members in this guild
		voice_states: { objects.VoiceStateObject }, -- States of members currently in voice channels; lacks the guild_id key
		members: { objects.GuildMemberObject }, -- Users in the guild
		channels: { objects.ChannelObject }, -- Channels in the guild
		threads: { objects.ChannelObject }, -- All active threads in the guild that current user has permission to view
		presences: { objects.PresenceUpdateObject }, -- Presences of the members in the guild, will only include non-offline members if the size is greater than large threshold
		stage_instances: { objects.StageInstanceObject }, -- Stage instances in the guild
		guild_scheduled_events: { objects.GuildScheduledEventObject }, -- Scheduled events in the guild
	})
>

-- https://discord.com/developers/docs/topics/gateway-events#guild-update
export type GuildUpdatePayload = Payload<objects.GuildObject>

-- https://discord.com/developers/docs/topics/gateway-events#guild-delete
export type GuildDeletePayload = Payload<objects.UnavailableGuildObject>

-- https://discord.com/developers/docs/topics/gateway-events#guild-ban-add
export type GuildBanAddPayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	user: objects.UserObject, -- User who was banned
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-ban-remove
export type GuildBanRemovePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	user: objects.UserObject, -- User who was unbanned
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-emojis-update
export type GuildEmojisUpdatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	emojis: { objects.EmojiObject }, -- Array of emojis
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-stickers-update
export type GuildStickersUpdatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	stickers: { objects.StickerObject }, -- Array of stickers
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-integrations-update
export type GuildIntegrationsUpdatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-member-add
export type GuildMemberAddPayload = Payload<
	objects.GuildMemberObject & {
		guild_id: objects.Snowflake, -- ID of the guild
	}
>

-- https://discord.com/developers/docs/topics/gateway-events#guild-member-remove
export type GuildMemberRemovePayload = Payload<{
	guild_id: objects.Snowflake, --ID of the guild
	user: objects.UserObject, -- User who was removed
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-member-update
export type GuildMemberUpdatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	roles: { objects.Snowflake }, -- User role ids
	user: objects.UserObject, -- The user effected
	nick: string?, -- Nickname of the user in the guild
	avatar: string?, -- Member's guild avatar hash
	joined_at: string?, -- When the user joined the guild
	premium_since: string?, -- When the user starting boosting the guild
	deaf: boolean?, -- Whether the user is deafened in voice channels
	mute: boolean?, -- Whether the user is muted in voice channels
	pending: boolean?, -- Whether the user has not yet passed the guild's Membership Screening requirements
	communication_disabled_until: string?, -- When the user's timeout will expire and the user will be able to communicate in the guild again, null or a time in the past if the user is not timed out
	flags: number?, -- Guild member flags represented as a bit set, defaults to 0
	avatar_decoration_data: objects.AvatarDecorationDataObject?, -- Data for the member's guild avatar decoration
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-members-chunk
export type GuildMembersChunkPayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	members: { objects.GuildMemberObject }, -- Set of guild members
	chunk_index: number, -- Chunk index in the expected chunks for this response (0 <= chunk_index < chunk_count)
	chunk_count: number, -- Total number of expected chunks for this response
	not_found: { unknown }?, -- When passing an invalid ID to REQUEST_GUILD_MEMBERS, it will be returned here
	presences: { objects.PresenceObject }?, -- When passing true to REQUEST_GUILD_MEMBERS, presences of the returned members will be here
	nonce: string?, -- Nonce used in the Guild Members Request
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-role-create
export type GuildRoleCreatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	role: objects.GuildRoleObject, -- Role that was created
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-role-update
export type GuildRoleUpdatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	role: objects.GuildRoleObject, -- Role that was updated
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-role-delete
export type GuildRoleDeletePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	role_id: objects.Snowflake, -- ID of the role
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-create
export type GuildScheduledEventCreatePayload = Payload<objects.GuildScheduledEventObject>

-- https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-create
export type GuildScheduledEventUpdatePayload = Payload<objects.GuildScheduledEventObject>

-- https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-create
export type GuildScheduledEventDeletePayload = Payload<objects.GuildScheduledEventObject>

-- https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-create
export type GuildScheduledEventUserAddPayload = Payload<{
	guild_scheduled_event_id: objects.Snowflake, -- ID of the guild scheduled event
	user_id: objects.Snowflake, -- ID of the user
	guild_id: objects.Snowflake, -- ID of the guild
}>

-- https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-create
export type GuildScheduledEventUserRemovePayload = Payload<{
	guild_scheduled_event_id: objects.Snowflake, -- ID of the guild scheduled event
	user_id: objects.Snowflake, -- ID of the user
	guild_id: objects.Snowflake, -- ID of the guild
}>

-- https://discord.com/developers/docs/topics/gateway-events#integration-create
export type IntegrationCreatePayload = Payload<
	objects.IntegrationObject & {
		guild_id: objects.Snowflake?, -- ID of the guild
	}
>

-- https://discord.com/developers/docs/topics/gateway-events#integration-update
export type IntegrationUpdatePayload = Payload<
	objects.IntegrationObject & {
		guild_id: objects.Snowflake?, -- ID of the guild
	}
>

-- https://discord.com/developers/docs/topics/gateway-events#integration-delete
export type IntegrationDeletePayload = Payload<
	objects.IntegrationObject & {
		id: objects.Snowflake?, -- Integration ID
		guild_id: objects.Snowflake, -- ID of the guild
		application_id: objects.Snowflake?, -- ID of the bot/OAuth2 application for this discord integration
	}
>

-- https://discord.com/developers/docs/topics/gateway-events#interaction-create
export type InteractionCreatePayload = Payload<objects.InteractionObject>

-- https://discord.com/developers/docs/topics/gateway-events#invite-create
export type InviteCreatePayload = Payload<{
	channel_id: objects.Snowflake, -- Channel the invite is for
	code: string, -- Unique invite code
	created_at: string, -- Time at which the invite was created
	guild_id: objects.Snowflake?, -- Guild of the invite
	inviter: objects.UserObject?, -- User that created the invite
	max_age: number, -- How long the invite is valid for (in seconds)
	max_uses: number, -- Maximum number of times the invite can be used
	target_type: objects.InviteTargetTypes?, -- Type of target for this voice channel invite
	target_user: objects.UserObject?, -- User whose stream to display for this voice channel stream invite
	target_application: objects.ApplicationObject?, -- Embedded application to open for this voice channel embedded application invite
	temporary: boolean, -- Whether or not the invite is temporary (invited users will be kicked on disconnect unless they're assigned a role)
	uses: number, -- How many times the invite has been used (always will be 0)
}>

-- https://discord.com/developers/docs/topics/gateway-events#invite-delete
export type InviteDeletePayload = Payload<{
	channel_id: objects.Snowflake, -- Channel of the invite
	code: string, -- Unique invite code
	guild_id: objects.Snowflake?, -- Guild of the invite
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-create
export type MessageCreatePayload = Payload<
	objects.MessageObject & {
		mentions: { objects.UserObject & { member: objects.GuildMemberObject } }, -- Users specifically mentioned in the message
		member: objects.GuildMemberObject?, -- Member properties for this message's author. Missing for ephemeral messages and messages from webhooks
		guild_id: objects.Snowflake?, -- ID of the guild the message was sent in - unless it is an ephemeral message
	}
>

-- https://discord.com/developers/docs/topics/gateway-events#message-update
export type MessageUpdatePayload = Payload<
	objects.MessageObject & {
		mentions: { objects.UserObject & { member: objects.GuildMemberObject } }, -- Users specifically mentioned in the message
		member: objects.GuildMemberObject?, -- Member properties for this message's author. Missing for ephemeral messages and messages from webhooks
		guild_id: objects.Snowflake?, -- ID of the guild the message was sent in - unless it is an ephemeral message
	}
>

-- https://discord.com/developers/docs/topics/gateway-events#message-delete
export type MessageDeletePayload = Payload<{
	id: objects.Snowflake, -- ID of the messages
	channel_id: objects.Snowflake, -- ID of the channel
	guild_id: objects.Snowflake?, -- ID of the guild
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-delete-bulk
export type MessageDeleteBulkPayload = Payload<{
	ids: { objects.Snowflake }, -- IDs of the messages
	channel_id: objects.Snowflake, -- ID of the channel
	guild_id: objects.Snowflake?, -- ID of the guild
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-reaction-add
export type MessageReactionAddPayload = Payload<{
	user_id: objects.Snowflake, -- ID of the user
	channel_id: objects.Snowflake, -- ID of the channel
	message_id: objects.Snowflake, -- ID of the message
	guild_id: objects.Snowflake?, -- ID of the guild
	member: objects.GuildMemberObject?, -- Member who reacted if this happened in a guild
	emoji: objects.EmojiObject, -- Emoji used to react - example
	message_author_id: objects.Snowflake?, -- ID of the user who authored the message which was reacted to
	burst: boolean, -- true if this is a super-reaction
	burst_colors: { string }, -- Colors used for super-reaction animation in "#rrggbb" format
	type: objects.ReactionType, -- The type of reaction
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove
export type MessageReactionRemovePayload = Payload<{
	user_id: objects.Snowflake, -- ID of the user
	channel_id: objects.Snowflake, -- ID of the channel
	message_id: objects.Snowflake, -- ID of the message
	guild_id: objects.Snowflake?, -- ID of the guild
	emoji: objects.EmojiObject, -- Emoji used to react - example
	burst: boolean, -- true if this was a super-reaction
	type: objects.ReactionType, -- The type of reaction
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove-all
export type MessageReactionRemoveAllPayload = Payload<{
	channel_id: objects.Snowflake, -- ID of the channel
	message_id: objects.Snowflake, -- ID of the guild
	guild_id: objects.Snowflake?, -- ID of the message
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove-emoji
export type MessageReactionRemoveEmojiPayload = Payload<{
	channel_id: objects.Snowflake, -- ID of the channel
	message_id: objects.Snowflake, -- ID of the guild
	guild_id: objects.Snowflake?, -- ID of the message
	emoji: objects.EmojiObject, -- Emoji that was removed
}>

-- https://discord.com/developers/docs/topics/gateway-events#presence-update
export type PresenceUpdatePayload = Payload<{
	user: objects.UserObject, -- User whose presence is being updated
	guild_id: objects.Snowflake, -- ID of the guild
	status: string, -- Either "idle", "dnd", "online", or "offline"
	activities: { objects.ActivityObject }, -- User's current activities
	client_status: objects.ClientStatusObject, -- User's platform-dependent status
}>

-- https://discord.com/developers/docs/topics/gateway-events#stage-instance-create
export type StageInstanceCreate = Payload<objects.StageInstanceObject>

-- https://discord.com/developers/docs/topics/gateway-events#stage-instance-update
export type StageInstanceUpdate = Payload<objects.StageInstanceObject>

-- https://discord.com/developers/docs/topics/gateway-events#stage-instance-delete
export type StageInstanceDelete = Payload<objects.StageInstanceObject>

-- https://discord.com/developers/docs/topics/gateway-events#typing-start
export type TypingStartPayload = Payload<{
	channel_id: objects.Snowflake, -- ID of the channel
	guild_id: objects.Snowflake?, -- ID of the guild
	user_id: objects.Snowflake, -- ID of the user
	timestamp: number, -- Unix time (in seconds) of when the user started typing
	member: objects.GuildMemberObject?, -- Member who started typing if this happened in a guild
}>

-- https://discord.com/developers/docs/topics/gateway-events#user-update
export type UserUpdatePayload = Payload<objects.UserObject>
-- https://discord.com/developers/docs/topics/gateway-events#voice-state-update
export type VoiceStateUpdatePayload = Payload<{
	token: string, -- Voice connection token
	guild_id: objects.Snowflake, -- Guild this voice server update is for
	endpoint: string?, -- Voice server host
}>

-- https://discord.com/developers/docs/topics/gateway-events#voice-server-update
export type VoiceServerUpdatePayload = Payload<{
	token: string, -- Voice connection token
	guild_id: objects.Snowflake, -- Guild this voice server update is for
	endpoint: string?, -- Voice server host
}>

-- https://discord.com/developers/docs/topics/gateway-events#webhooks-update
export type WebhooksUpdatePayload = Payload<{
	guild_id: objects.Snowflake, -- ID of the guild
	channel_id: objects.Snowflake, -- ID of the channel=
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-add
export type MessagePollVoteAdd = Payload<{
	user_id: objects.Snowflake, -- ID of the user
	channel_id: objects.Snowflake, -- ID of the channel
	message_id: objects.Snowflake, -- ID of the message
	guild_id: objects.Snowflake?, -- ID of the guild
	answer_id: number, -- ID of the answer
}>

-- https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-remove
export type MessagePollVoteRemove = Payload<{
	user_id: objects.Snowflake, -- ID of the user
	channel_id: objects.Snowflake, -- ID of the channel
	message_id: objects.Snowflake, -- ID of the message
	guild_id: objects.Snowflake?, -- ID of the guild
	answer_id: number, -- ID of the answer
}>

return "DISCORD_V10_PAYLOAD_TYPES"
