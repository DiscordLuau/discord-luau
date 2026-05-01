local future = require("../luau_packages/future")
local stdPolyfills = require("../luau_packages/std_polyfills")
local apiTypes = require("../luau_packages/api_types")
local state = require("../luau_packages/state")
local rest = require("../luau_packages/rest")
local logger = require("../luau_packages/logger")
local emitter = require("../luau_packages/emitter")
local classes = require("../luau_packages/classes")
local builders = require("../luau_packages/builders")

local DISCORD_VERSION = 10

--[=[
	@class DiscordLuau.Bot
	@__index Prototype

	Top level documentation for the Discord-Luau library, welcome! 👋

	This package will represent the entrypoint to your adventure using Discord-Luau, through this package you'll generate
	a discord Bot object, this bot Object enables you to write discord bots for the Discord API.

	```luau
	local DiscordLuau = require("/path/to/discord-luau")
	local Bot = DiscordLuau.bot -- This module!

	local discordBot = Bot.new({
		token = env.DISCORD_BOT_TOKEN,
		reconnect = env.IS_PRODUCTION,
		intents = 513, -- Guild, GuildMessages
	})

	discordBot:connectAsync():await()

	print(`Bot has connected: '{discordBot.user.username}'`)
	```
]=]

--[=[
	@prop state State.State
	@within DiscordLuau.Bot
]=]

--[=[
	@prop logger Logger
	@within DiscordLuau.Bot
]=]

--[=[
	@prop application Classes.Application?
	@within DiscordLuau.Bot
]=]

--[=[
	@prop user Classes.User?
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onReady Emitter<number>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAllShardsReady Emitter<()>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onShardDisconnected Emitter<number, string>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onShardReconnected Emitter<number>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessage Emitter<Classes.Message>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessageChanged Emitter<Classes.Message>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessageDeleted Emitter<{ messageId: apiTypes.Snowflake, channelId: apiTypes.Snowflake, guildId: apiTypes.Snowflake }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessageBulkDeleted Emitter<{ channelId: string, guildId: string, ids: { string } }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGroupDMChannelCreate Emitter<Classes.GroupDM>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onCategoryChannelCreate Emitter<Classes.GuildCategory>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAnnouncementChannelCreate Emitter<Classes.GuildAnnouncement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onDirectoryChannelCreate Emitter<Classes.GuildDirectory>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onDMChannelCreate Emitter<Classes.DM>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onTextChannelCreate Emitter<Classes.GuildText>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onVoiceChannelCreate Emitter<Classes.GuildVoice>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onStageVoiceChannelCreate Emitter<Classes.GuildStageVoice>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGroupDMChannelUpdated Emitter<Classes.GroupDM>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onCategoryChannelUpdated Emitter<Classes.GuildCategory>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAnnouncementChannelUpdated Emitter<Classes.GuildAnnouncement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onDirectoryChannelUpdated Emitter<Classes.GuildDirectory>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onDMChannelUpdated Emitter<Classes.DM>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onTextChannelUpdated Emitter<Classes.GuildText>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onVoiceChannelUpdated Emitter<Classes.GuildVoice>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onStageVoiceChannelUpdated Emitter<Classes.GuildStageVoice>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGroupDMChannelDeleted Emitter<Classes.GroupDM>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onCategoryChannelDeleted Emitter<Classes.GuildCategory>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAnnouncementChannelDeleted Emitter<Classes.GuildAnnouncement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onDirectoryChannelDeleted Emitter<Classes.GuildDirectory>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onDMChannelDeleted Emitter<Classes.DM>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onTextChannelDeleted Emitter<Classes.GuildText>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onVoiceChannelDeleted Emitter<Classes.GuildVoice>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onStageVoiceChannelDeleted Emitter<Classes.GuildStageVoice>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onUserUpdated Emitter<Classes.User>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onChannelPinsUpdate Emitter<{ guildId: string, channelId: string, lastPinTimestamp: stdPolyfills.DateTime? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildCreate Emitter<classes.UnavailableGuild | classes.Guild>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildUpdate Emitter<Classes.Guild>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildDelete Emitter<Classes.UnavailableGuild>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildMemberBanned Emitter<{ guildId: string, user: classes.User }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildMemberUnbanned Emitter<{ guildId: string, user: classes.User }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildMemberJoined Emitter<Classes.GuildMember & { guildId: string }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildMemberLeft Emitter<{ guildId: string, user: classes.User }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildMemberUpdated Emitter<{guildId: stringroles: { string },user: classes.User,nick: string?,avatar: string,joinedAt: stdPolyfills.DateTime,premiumSince: stdPolyfills.DateTime,deaf: boolean?,mute: boolean?,pending: boolean?,communicationDisabledUntil: stdPolyfills.DateTime?,}>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onPingInteraction Emitter<Classes.Ping>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onCommandInteraction Emitter<Classes.TypesCommand>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onComponentInteraction Emitter<Classes.Component>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAutocompleteInteraction Emitter<Classes.Autocomplete>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onModalInteraction Emitter<Classes.Modal>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessageReactionAdd Emitter<{ userId: string, channelId: string, messageId: string, guildId: string?, member: Classes.GuildMember?, emoji: Classes.Emoji, messageAuthorId: string?, burst: boolean, burstColors: { string }, reactionType: number }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessageReactionRemove Emitter<{ userId: string, channelId: string, messageId: string, guildId: string?, emoji: Classes.Emoji, burst: boolean, reactionType: number }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessageReactionRemoveAll Emitter<{ channelId: string, messageId: string, guildId: string? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessageReactionRemoveEmoji Emitter<{ channelId: string, messageId: string, guildId: string?, emoji: Classes.Emoji }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onThreadListSync Emitter<{ guildId: string, channelIds: { string }?, members: { Classes.ThreadMember } }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onThreadMemberUpdate Emitter<{ guildId: string, threadMember: Classes.ThreadMember }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onThreadMembersUpdate Emitter<{ id: string, guildId: string, memberCount: number, addedMembers: { Classes.ThreadMember }, removedMemberIds: { string }? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onEntitlementCreate Emitter<Classes.Entitlement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onEntitlementUpdate Emitter<Classes.Entitlement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onEntitlementDelete Emitter<Classes.Entitlement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildAuditLogEntryCreate Emitter<Classes.AuditLogEntry>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildEmojisUpdate Emitter<{ guildId: string, emojis: { Classes.Emoji } }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildStickersUpdate Emitter<{ guildId: string, stickers: { Classes.Sticker } }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildScheduledEventCreate Emitter<Classes.ScheduledEvent>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildScheduledEventUpdate Emitter<Classes.ScheduledEvent>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildScheduledEventDelete Emitter<Classes.ScheduledEvent>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildScheduledEventUserAdd Emitter<{ guildScheduledEventId: string, userId: string, guildId: string }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildScheduledEventUserRemove Emitter<{ guildScheduledEventId: string, userId: string, guildId: string }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onIntegrationCreate Emitter<Classes.Integration>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onIntegrationUpdate Emitter<Classes.Integration>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onIntegrationDelete Emitter<{ id: string, guildId: string, applicationId: string? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onInviteCreate Emitter<{ channelId: string, code: string, createdAt: stdPolyfills.DateTime, guildId: string?, inviter: Classes.User?, maxAge: number, maxUses: number, targetType: number?, targetUser: Classes.User?, temporary: boolean, uses: number }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onInviteDelete Emitter<{ channelId: string, code: string, guildId: string? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAutoModerationRuleCreate Emitter<Classes.AutomoderationRule>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAutoModerationRuleUpdate Emitter<Classes.AutomoderationRule>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAutoModerationRuleDelete Emitter<Classes.AutomoderationRule>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAutoModerationActionExecution Emitter<{ guildId: string, action: apiTypes.AutomoderationActionObject, ruleId: string, ruleTriggerType: apiTypes.AutomoderationRuleTriggerType, userId: string, channelId: string?, messageId: string?, alertSystemMessageId: string?, content: string, matchedKeyword: string?, matchedContent: string? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onApplicationCommandPermissionsUpdate Emitter<{ id: string, applicationId: string, guildId: string, permissions: { apiTypes.GuildApplicationCommandPermissionObject } }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessagePollVoteAdd Emitter<{ userId: string, channelId: string, messageId: string, guildId: string?, answerId: number }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onMessagePollVoteRemove Emitter<{ userId: string, channelId: string, messageId: string, guildId: string?, answerId: number }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildRoleCreate Emitter<Classes.Role>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildRoleUpdate Emitter<Classes.Role>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildRoleDelete Emitter<{ guildId: string, roleId: string }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAnnouncementThreadCreate Emitter<Classes.Announcement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onPublicThreadCreate Emitter<Classes.Public>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onPrivateThreadCreate Emitter<Classes.Private>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onAnnouncementThreadUpdate Emitter<Classes.Announcement>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onPublicThreadUpdate Emitter<Classes.Public>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onPrivateThreadUpdate Emitter<Classes.Private>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onThreadDelete Emitter<{ id: string, guildId: string, parentId: string, type: number }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onPresenceUpdate Emitter<Classes.Presence>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onTypingStart Emitter<{ channelId: string, guildId: string?, userId: string, timestamp: number, member: Classes.GuildMember? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildMembersChunk Emitter<{ guildId: string, members: { Classes.GuildMember }, chunkIndex: number, chunkCount: number, notFound: { string }?, nonce: string? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildIntegrationsUpdate Emitter<{ guildId: string }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onWebhooksUpdate Emitter<{ guildId: string, channelId: string }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onResumed Emitter<()>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onVoiceStateUpdate Emitter<Classes.VoiceState>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onVoiceServerUpdate Emitter<{ token: string, guildId: string, endpoint: string? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onStageInstanceCreate Emitter<Classes.StageInstance>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onStageInstanceUpdate Emitter<Classes.StageInstance>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onStageInstanceDelete Emitter<Classes.StageInstance>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildSoundboardSoundCreate Emitter<Classes.SoundboardSound>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildSoundboardSoundUpdate Emitter<Classes.SoundboardSound>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildSoundboardSoundDelete Emitter<{ soundId: string, guildId: string }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onGuildSoundboardSoundsUpdate Emitter<{ guildId: string, soundboardSounds: { Classes.SoundboardSound } }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onVoiceChannelEffectSend Emitter<{ channelId: string, guildId: string, userId: string, emoji: Classes.Emoji?, animationType: number?, animationId: number?, soundId: string?, soundVolume: number? }>
	@within DiscordLuau.Bot
]=]

--[=[
	@prop onRateLimited Emitter<{ opcode: number, retryAfter: number, guildId: string? }>
	@within DiscordLuau.Bot
	Fired when the gateway rate limits a request. When opcode is RequestGuildMembers, guildId identifies the affected guild.
]=]

local Bot = {}

Bot.Interface = {}
Bot.Prototype = {}

--[=[
	@within DiscordLuau.Bot

	Queries the Discord Gateway for bot information.
	
	This function sends a request to the Discord Gateway to retrieve information
	about the bot, such as the recommended number of shards and session start limit.
]=]
function Bot.Prototype.queryGatewayInformation(self: Bot): future.FutureLike<string, apiTypes.GetGatewayBotResponse>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.gateway.getGatewayBotAsync(request):await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return response:unwrapOk()
	end) :: future.FutureLike<string, apiTypes.GetGatewayBotResponse>
end

--[=[
	@within DiscordLuau.Bot

	Connects the bot to the Discord gateway asynchronously.

	This function performs the following steps:
	1. Queries gateway information
	2. Asserts that the query was successful
	3. Connects to the WebSocket using the obtained gateway information

	Returns a async that resolves when the connection is established.
]=]
function Bot.Prototype.connectAsync(self: Bot): future.FutureLike<string, nil>
	return future.Future.new(function()
		local gatewayInformation = self:queryGatewayInformation():await()

		if not gatewayInformation:isOk() then
			self.logger:emergency(`Failed to retrieve gateway information: {gatewayInformation:unwrapErr()}`)

			error(gatewayInformation:unwrapErr())
		end

		self.state.webSocketManager.onAllShardsReady:listen(function(data)
			local application = classes.application.application.new(self.state, data.payload.d.application)
			local user = classes.user.new(data.payload.d.user)

			self.application = application
			self.user = user

			self.state:setApplicationId(application.id)

			self.onAllShardsReady:invoke()
		end)

		self.state.webSocketManager.onDisconnected:listen(function(data)
			self.onShardDisconnected:invoke(data.shardId, data.errorCode)
		end)

		self.state.webSocketManager.onReconnected:listen(function(data)
			self.onShardReconnected:invoke(data.shardId)
		end)

		self.state.webSocketManager.onRateLimited:listen(function(data)
			if data.guildId and data.opcode == apiTypes.gateway.opcodes.RequestGuildMembers then
				self.rateLimitedGuilds[data.guildId] = true

				stdPolyfills.task.delay(data.retryAfter, function()
					self.rateLimitedGuilds[data.guildId :: string] = nil
				end)
			end

			self.onRateLimited:invoke({
				opcode = data.opcode,
				retryAfter = data.retryAfter,
				guildId = data.guildId,
			})
		end)

		self.state.webSocketManager.onDispatch:listen(function(object: {
			shardId: number,
			event: apiTypes.ReceiveEvent,
			payload: apiTypes.Payload<unknown>,
		})
			if object.event == apiTypes.gateway.receiveEvents["Ready"] then
				self.onReady:invoke(object.shardId)
			elseif object.event == apiTypes.gateway.receiveEvents["MessageCreate"] then
				local typedObject = object.payload :: apiTypes.MessageCreatePayload

				self.onMessage:invoke(classes.message.message.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["MessageUpdate"] then
				local typedObject = object.payload :: apiTypes.MessageUpdatePayload

				self.onMessageChanged:invoke(classes.message.message.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["MessageDelete"] then
				local typedObject = object.payload :: apiTypes.MessageDeletePayload

				self.onMessageDeleted:invoke({
					messageId = typedObject.d.id,
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["MessageDeleteBulk"] then
				local typedObject = object.payload :: apiTypes.MessageDeleteBulkPayload

				self.onMessageBulkDeleted:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					ids = typedObject.d.ids,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelCreate"] then
				local typedObject = object.payload :: apiTypes.CreateChannelPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == apiTypes.channel.ChannelTypes.GuildText then
					self.onTextChannelCreate:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.DM then
					self.onDMChannelCreate:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildVoice then
					self.onVoiceChannelCreate:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GroupDM then
					self.onGroupDMChannelCreate:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildCategory then
					self.onCategoryChannelCreate:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildAnnouncement then
					self.onAnnouncementChannelCreate:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildStageVoice then
					self.onStageVoiceChannelCreate:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildDirectory then
					self.onDirectoryChannelCreate:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelUpdate"] then
				local typedObject = object.payload :: apiTypes.UpdateChannelPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == apiTypes.channel.ChannelTypes.GuildText then
					self.onTextChannelUpdated:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.DM then
					self.onDMChannelUpdated:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildVoice then
					self.onVoiceChannelUpdated:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GroupDM then
					self.onGroupDMChannelUpdated:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildCategory then
					self.onCategoryChannelUpdated:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildAnnouncement then
					self.onAnnouncementChannelUpdated:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildStageVoice then
					self.onStageVoiceChannelUpdated:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildDirectory then
					self.onDirectoryChannelUpdated:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelDelete"] then
				local typedObject = object.payload :: apiTypes.DeleteChannelPayload

				self.state.cache.channels:remove(typedObject.d.id :: apiTypes.Snowflake)

				if typedObject.d.type == apiTypes.channel.ChannelTypes.GuildText then
					self.onTextChannelDeleted:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.DM then
					self.onDMChannelDeleted:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildVoice then
					self.onVoiceChannelDeleted:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GroupDM then
					self.onGroupDMChannelDeleted:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildCategory then
					self.onCategoryChannelDeleted:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildAnnouncement then
					self.onAnnouncementChannelDeleted:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildStageVoice then
					self.onStageVoiceChannelDeleted:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.GuildDirectory then
					self.onDirectoryChannelDeleted:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelPinsUpdate"] then
				local typedObject = object.payload :: apiTypes.ChannelPinsUpdatePayload

				self.onChannelPinsUpdate:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					lastPinTimestamp = typedObject.d.last_pin_timestamp
						and stdPolyfills.datetime.fromIsoDate(typedObject.d.last_pin_timestamp),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["UserUpdate"] then
				local typedObject = object.payload :: apiTypes.UserUpdatePayload

				self.state.cache.users:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				self.onUserUpdated:invoke(classes.user.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildCreate"] then
				local typedObject = object.payload :: apiTypes.GuildCreatePayload

				if typedObject.d.unavailable then
					self.onGuildCreate:invoke(
						classes.guild.unavailableGuild.new(self.state, typedObject.d.id :: string)
					)
				else
					-- fixme: using 'any' below because otherwise typedObject.d doesn't work with apiTypes.GuildObject?
					local guildData = typedObject.d :: any

					self.state.cache.guilds:set(typedObject.d.id :: apiTypes.Snowflake, guildData)

					if guildData.roles then
						for _, roleData in guildData.roles do
							self.state.cache.roles:set(roleData.id :: apiTypes.Snowflake, roleData)
						end
					end

					if guildData.channels then
						for _, channelData in guildData.channels do
							self.state.cache.channels:set(channelData.id :: apiTypes.Snowflake, channelData)
						end
					end

					if guildData.threads then
						for _, threadData in guildData.threads do
							self.state.cache.channels:set(threadData.id :: apiTypes.Snowflake, threadData)
						end
					end

					self.onGuildCreate:invoke(classes.guild.guild.new(self.state, guildData))
				end
			elseif object.event == apiTypes.gateway.receiveEvents["GuildUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildUpdatePayload

				self.state.cache.guilds:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				self.onGuildUpdate:invoke(classes.guild.guild.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildDelete"] then
				local typedObject = object.payload :: apiTypes.GuildDeletePayload

				self.state.cache.guilds:remove(typedObject.d.id :: apiTypes.Snowflake)

				self.onGuildDelete:invoke(classes.guild.unavailableGuild.new(self.state, typedObject.d.id))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildBanAdd"] then
				local typedObject = object.payload :: apiTypes.GuildBanAddPayload

				self.state.cache.users:set(typedObject.d.user.id :: apiTypes.Snowflake, typedObject.d.user)

				self.onGuildMemberBanned:invoke({
					guildId = typedObject.d.guild_id,
					user = classes.user.new(typedObject.d.user),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildBanRemove"] then
				local typedObject = object.payload :: apiTypes.GuildBanRemovePayload

				self.state.cache.users:set(typedObject.d.user.id :: apiTypes.Snowflake, typedObject.d.user)

				self.onGuildMemberUnbanned:invoke({
					guildId = typedObject.d.guild_id,
					user = classes.user.new(typedObject.d.user),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildMemberAdd"] then
				local typedObject = object.payload :: apiTypes.GuildMemberAddPayload

				self.onGuildMemberJoined:invoke({
					guildId = typedObject.d.guild_id,
					member = classes.guild.member.new(self.state, typedObject.d.guild_id, typedObject.d),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildMemberRemove"] then
				local typedObject = object.payload :: apiTypes.GuildMemberRemovePayload

				self.onGuildMemberLeft:invoke({
					guildId = typedObject.d.guild_id,
					user = classes.user.new(typedObject.d.user),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildMemberUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildMemberUpdatePayload

				self.onGuildMemberUpdated:invoke({
					guildId = typedObject.d.guild_id,
					roles = typedObject.d.roles,
					user = classes.user.new(typedObject.d.user),
					nick = typedObject.d.nick,
					avatar = typedObject.d.avatar,
					joinedAt = typedObject.d.joined_at and stdPolyfills.datetime.fromIsoDate(typedObject.d.joined_at),
					premiumSince = typedObject.d.premium_since
						and stdPolyfills.datetime.fromIsoDate(typedObject.d.premium_since),
					deaf = typedObject.d.deaf,
					mute = typedObject.d.mute,
					pending = typedObject.d.pending,
					communicationDisabledUntil = typedObject.d.communication_disabled_until
						and stdPolyfills.datetime.fromIsoDate(typedObject.d.communication_disabled_until),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildRoleCreate"] then
				local typedObject = object.payload :: apiTypes.GuildRoleCreatePayload

				self.state.cache.roles:set(typedObject.d.role.id :: apiTypes.Snowflake, typedObject.d.role)

				self.onGuildRoleCreate:invoke(
					classes.guild.role.new(self.state, typedObject.d.guild_id, typedObject.d.role)
				)
			elseif object.event == apiTypes.gateway.receiveEvents["GuildRoleUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildRoleUpdatePayload

				self.state.cache.roles:set(typedObject.d.role.id :: apiTypes.Snowflake, typedObject.d.role)

				self.onGuildRoleUpdate:invoke(
					classes.guild.role.new(self.state, typedObject.d.guild_id, typedObject.d.role)
				)
			elseif object.event == apiTypes.gateway.receiveEvents["GuildRoleDelete"] then
				local typedObject = object.payload :: apiTypes.GuildRoleDeletePayload

				self.state.cache.roles:remove(typedObject.d.role_id :: apiTypes.Snowflake)

				self.onGuildRoleDelete:invoke({
					guildId = typedObject.d.guild_id,
					roleId = typedObject.d.role_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["ThreadCreate"] then
				local typedObject = object.payload :: apiTypes.CreateThreadPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == apiTypes.channel.ChannelTypes.AnnouncementThread then
					self.onAnnouncementThreadCreate:invoke(
						classes.channels.threads.announcement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.PublicThread then
					self.onPublicThreadCreate:invoke(classes.channels.threads.public.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.PrivateThread then
					self.onPrivateThreadCreate:invoke(classes.channels.threads.private.new(self.state, typedObject.d))
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ThreadUpdate"] then
				local typedObject = object.payload :: apiTypes.UpdateThreadPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == apiTypes.channel.ChannelTypes.AnnouncementThread then
					self.onAnnouncementThreadUpdate:invoke(
						classes.channels.threads.announcement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.PublicThread then
					self.onPublicThreadUpdate:invoke(classes.channels.threads.public.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.channel.ChannelTypes.PrivateThread then
					self.onPrivateThreadUpdate:invoke(classes.channels.threads.private.new(self.state, typedObject.d))
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ThreadDelete"] then
				local typedObject = object.payload :: apiTypes.DeleteThreadPayload

				self.state.cache.channels:remove(typedObject.d.id :: apiTypes.Snowflake)

				self.onThreadDelete:invoke({
					id = typedObject.d.id,
					guildId = typedObject.d.guild_id,
					parentId = typedObject.d.parent_id,
					type = typedObject.d.type,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["InteractionCreate"] then
				local typedObject = object.payload :: apiTypes.InteractionCreatePayload

				if typedObject.d.type == apiTypes.interaction.InteractionType.Ping then
					self.onPingInteraction:invoke(classes.interaction.types.ping.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.interaction.InteractionType.ApplicationCommand then
					self.onCommandInteraction:invoke(classes.interaction.types.command.new(self.state, typedObject.d))
				elseif typedObject.d.type == apiTypes.interaction.InteractionType.MessageComponent then
					self.onComponentInteraction:invoke(
						classes.interaction.types.component.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.interaction.InteractionType.ApplicationCommandAutocomplete then
					self.onAutocompleteInteraction:invoke(
						classes.interaction.types.autocomplete.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == apiTypes.interaction.InteractionType.ModalSubmit then
					self.onModalInteraction:invoke(classes.interaction.types.modal.new(self.state, typedObject.d))
				else
					error(`Unknown interaction type: {typedObject.d.type}`)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["MessageReactionAdd"] then
				local typedObject = object.payload :: apiTypes.MessageReactionAddPayload

				self.onMessageReactionAdd:invoke({
					userId = typedObject.d.user_id,
					channelId = typedObject.d.channel_id,
					messageId = typedObject.d.message_id,
					guildId = typedObject.d.guild_id,
					member = typedObject.d.member
						and typedObject.d.guild_id
						and classes.guild.member.new(self.state, typedObject.d.guild_id, typedObject.d.member),
					emoji = classes.emoji.new(typedObject.d.emoji),
					messageAuthorId = typedObject.d.message_author_id,
					burst = typedObject.d.burst,
					burstColors = typedObject.d.burst_colors,
					reactionType = typedObject.d.type,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["MessageReactionRemove"] then
				local typedObject = object.payload :: apiTypes.MessageReactionRemovePayload

				self.onMessageReactionRemove:invoke({
					userId = typedObject.d.user_id,
					channelId = typedObject.d.channel_id,
					messageId = typedObject.d.message_id,
					guildId = typedObject.d.guild_id,
					emoji = classes.emoji.new(typedObject.d.emoji),
					burst = typedObject.d.burst,
					reactionType = typedObject.d.type,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["MessageReactionRemoveAll"] then
				local typedObject = object.payload :: apiTypes.MessageReactionRemoveAllPayload

				self.onMessageReactionRemoveAll:invoke({
					channelId = typedObject.d.channel_id,
					messageId = typedObject.d.message_id,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["MessageReactionRemoveEmoji"] then
				local typedObject = object.payload :: apiTypes.MessageReactionRemoveEmojiPayload

				self.onMessageReactionRemoveEmoji:invoke({
					channelId = typedObject.d.channel_id,
					messageId = typedObject.d.message_id,
					guildId = typedObject.d.guild_id,
					emoji = classes.emoji.new(typedObject.d.emoji),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["ThreadListSync"] then
				local typedObject = object.payload :: apiTypes.ThreadListSyncPayload

				local threadMemberArray = {}
				for _, memberData in next, typedObject.d.members or {} do
					table.insert(
						threadMemberArray,
						classes.threadMember.new(self.state, typedObject.d.guild_id, memberData)
					)
				end

				self.onThreadListSync:invoke({
					guildId = typedObject.d.guild_id,
					channelIds = typedObject.d.channel_ids,
					members = threadMemberArray,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["ThreadMemberUpdate"] then
				local typedObject = object.payload :: apiTypes.ThreadMemberUpdatePayload

				self.onThreadMemberUpdate:invoke({
					guildId = typedObject.d.guild_id,
					threadMember = classes.threadMember.new(self.state, typedObject.d.guild_id, typedObject.d),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["ThreadMembersUpdate"] then
				local typedObject = object.payload :: apiTypes.ThreadMembersUpdatePayload

				local addedMembersArray = {}
				for _, memberData in next, typedObject.d.added_members or {} do
					table.insert(
						addedMembersArray,
						classes.threadMember.new(self.state, typedObject.d.guild_id, memberData)
					)
				end

				self.onThreadMembersUpdate:invoke({
					id = typedObject.d.id,
					guildId = typedObject.d.guild_id,
					memberCount = typedObject.d.member_count,
					addedMembers = addedMembersArray,
					removedMemberIds = typedObject.d.removed_member_ids,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["EntitlementCreate"] then
				local typedObject = object.payload :: apiTypes.EntitlementCreatePayload

				self.onEntitlementCreate:invoke(classes.entitlement.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["EntitlementUpdate"] then
				local typedObject = object.payload :: apiTypes.EntitlementUpdatePayload

				self.onEntitlementUpdate:invoke(classes.entitlement.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["EntitlementDelete"] then
				local typedObject = object.payload :: apiTypes.EntitlementDeletePayload

				self.onEntitlementDelete:invoke(classes.entitlement.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildAuditLogEntryCreate"] then
				local typedObject = object.payload :: apiTypes.GuildAuditLogEntryCreatePayload

				self.onGuildAuditLogEntryCreate:invoke(classes.auditlog.entry.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildEmojisUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildEmojisUpdatePayload

				local emojiArray = {}
				for _, emojiData in next, typedObject.d.emojis do
					table.insert(emojiArray, classes.emoji.new(emojiData))
				end

				self.onGuildEmojisUpdate:invoke({
					guildId = typedObject.d.guild_id,
					emojis = emojiArray,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildStickersUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildStickersUpdatePayload

				local stickerArray = {}
				for _, stickerData in next, typedObject.d.stickers do
					table.insert(stickerArray, classes.sticker.new(stickerData))
				end

				self.onGuildStickersUpdate:invoke({
					guildId = typedObject.d.guild_id,
					stickers = stickerArray,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildScheduledEventCreate"] then
				local typedObject = object.payload :: apiTypes.GuildScheduledEventCreatePayload

				self.onGuildScheduledEventCreate:invoke(classes.guild.scheduledEvent.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildScheduledEventUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildScheduledEventUpdatePayload

				self.onGuildScheduledEventUpdate:invoke(classes.guild.scheduledEvent.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildScheduledEventDelete"] then
				local typedObject = object.payload :: apiTypes.GuildScheduledEventDeletePayload

				self.onGuildScheduledEventDelete:invoke(classes.guild.scheduledEvent.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildScheduledEventUserAdd"] then
				local typedObject = object.payload :: apiTypes.GuildScheduledEventUserAddPayload

				self.onGuildScheduledEventUserAdd:invoke({
					guildScheduledEventId = typedObject.d.guild_scheduled_event_id,
					userId = typedObject.d.user_id,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildScheduledEventUserRemove"] then
				local typedObject = object.payload :: apiTypes.GuildScheduledEventUserRemovePayload

				self.onGuildScheduledEventUserRemove:invoke({
					guildScheduledEventId = typedObject.d.guild_scheduled_event_id,
					userId = typedObject.d.user_id,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["IntegrationCreate"] then
				local typedObject = object.payload :: apiTypes.IntegrationCreatePayload

				self.onIntegrationCreate:invoke(
					classes.guild.integration.integration.new(self.state, typedObject.d.guild_id, typedObject.d)
				)
			elseif object.event == apiTypes.gateway.receiveEvents["IntegrationUpdate"] then
				local typedObject = object.payload :: apiTypes.IntegrationUpdatePayload

				self.onIntegrationUpdate:invoke(
					classes.guild.integration.integration.new(self.state, typedObject.d.guild_id, typedObject.d)
				)
			elseif object.event == apiTypes.gateway.receiveEvents["IntegrationDelete"] then
				local typedObject = object.payload :: apiTypes.IntegrationDeletePayload

				self.onIntegrationDelete:invoke({
					id = typedObject.d.id :: string,
					guildId = typedObject.d.guild_id,
					applicationId = typedObject.d.application_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["InviteCreate"] then
				local typedObject = object.payload :: apiTypes.InviteCreatePayload

				self.onInviteCreate:invoke({
					channelId = typedObject.d.channel_id,
					code = typedObject.d.code,
					createdAt = stdPolyfills.datetime.fromIsoDate(typedObject.d.created_at),
					guildId = typedObject.d.guild_id,
					inviter = typedObject.d.inviter and classes.user.new(typedObject.d.inviter),
					maxAge = typedObject.d.max_age,
					maxUses = typedObject.d.max_uses,
					targetType = typedObject.d.target_type,
					targetUser = typedObject.d.target_user and classes.user.new(typedObject.d.target_user),
					temporary = typedObject.d.temporary,
					uses = typedObject.d.uses,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["InviteDelete"] then
				local typedObject = object.payload :: apiTypes.InviteDeletePayload

				self.onInviteDelete:invoke({
					channelId = typedObject.d.channel_id,
					code = typedObject.d.code,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["AutoModerationRuleCreate"] then
				local typedObject = object.payload :: apiTypes.AutoModerationRuleCreatePayload

				self.onAutoModerationRuleCreate:invoke(classes.automoderation.rule.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["AutoModerationRuleUpdate"] then
				local typedObject = object.payload :: apiTypes.AutoModerationRuleUpdatePayload

				self.onAutoModerationRuleUpdate:invoke(classes.automoderation.rule.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["AutoModerationRuleDelete"] then
				local typedObject = object.payload :: apiTypes.AutoModerationRuleDeletePayload

				self.onAutoModerationRuleDelete:invoke(classes.automoderation.rule.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["AutoModerationActionExecution"] then
				local typedObject = object.payload :: apiTypes.AutoModerationActionExecutionPayload

				self.onAutoModerationActionExecution:invoke({
					guildId = typedObject.d.guild_id,
					action = typedObject.d.action,
					ruleId = typedObject.d.rule_id,
					ruleTriggerType = typedObject.d.rule_trigger_type,
					userId = typedObject.d.user_id,
					channelId = typedObject.d.channel_id,
					messageId = typedObject.d.message_id,
					alertSystemMessageId = typedObject.d.alert_system_message_id,
					content = typedObject.d.content,
					matchedKeyword = typedObject.d.matched_keyword,
					matchedContent = typedObject.d.matched_content,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["ApplicationCommandPermissionsUpdate"] then
				local typedObject = object.payload :: apiTypes.ApplicationCommandPermissionsUpdatePayload

				self.onApplicationCommandPermissionsUpdate:invoke({
					id = typedObject.d.id,
					applicationId = typedObject.d.application_id,
					guildId = typedObject.d.guild_id,
					permissions = typedObject.d.permissions,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["MessagePollVoteAdd"] then
				local typedObject = object.payload :: apiTypes.MessagePollVoteAdd

				self.onMessagePollVoteAdd:invoke({
					userId = typedObject.d.user_id,
					channelId = typedObject.d.channel_id,
					messageId = typedObject.d.message_id,
					guildId = typedObject.d.guild_id,
					answerId = typedObject.d.answer_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["MessagePollVoteRemove"] then
				local typedObject = object.payload :: apiTypes.MessagePollVoteRemove

				self.onMessagePollVoteRemove:invoke({
					userId = typedObject.d.user_id,
					channelId = typedObject.d.channel_id,
					messageId = typedObject.d.message_id,
					guildId = typedObject.d.guild_id,
					answerId = typedObject.d.answer_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["PresenceUpdate"] then
				local typedObject = object.payload :: apiTypes.PresenceUpdatePayload

				self.onPresenceUpdate:invoke(classes.presence.new(typedObject.d :: apiTypes.PresenceObject))
			elseif object.event == apiTypes.gateway.receiveEvents["TypingStart"] then
				local typedObject = object.payload :: apiTypes.TypingStartPayload

				self.onTypingStart:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					userId = typedObject.d.user_id,
					timestamp = typedObject.d.timestamp,
					member = typedObject.d.member
						and typedObject.d.guild_id
						and classes.guild.member.new(self.state, typedObject.d.guild_id, typedObject.d.member),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildMembersChunk"] then
				local typedObject = object.payload :: apiTypes.GuildMembersChunkPayload

				local membersArray = {}
				for _, memberData in next, typedObject.d.members do
					table.insert(membersArray, classes.guild.member.new(self.state, typedObject.d.guild_id, memberData))
				end

				self.onGuildMembersChunk:invoke({
					guildId = typedObject.d.guild_id,
					members = membersArray,
					chunkIndex = typedObject.d.chunk_index,
					chunkCount = typedObject.d.chunk_count,
					notFound = typedObject.d.not_found,
					nonce = typedObject.d.nonce,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildIntegrationsUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildIntegrationsUpdatePayload

				self.onGuildIntegrationsUpdate:invoke({
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["WebhooksUpdate"] then
				local typedObject = object.payload :: apiTypes.WebhooksUpdatePayload

				self.onWebhooksUpdate:invoke({
					guildId = typedObject.d.guild_id,
					channelId = typedObject.d.channel_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["Resumed"] then
				self.onResumed:invoke()
			elseif object.event == apiTypes.gateway.receiveEvents["VoiceStateUpdate"] then
				local typedObject = object.payload :: apiTypes.VoiceStateUpdatePayload

				self.onVoiceStateUpdate:invoke(classes.guild.voiceState.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["VoiceServerUpdate"] then
				local typedObject = object.payload :: apiTypes.VoiceServerUpdatePayload

				self.onVoiceServerUpdate:invoke({
					token = typedObject.d.token,
					guildId = typedObject.d.guild_id,
					endpoint = typedObject.d.endpoint,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["StageInstanceCreate"] then
				local typedObject = object.payload :: apiTypes.StageInstanceCreate

				self.onStageInstanceCreate:invoke(classes.guild.stageInstance.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["StageInstanceUpdate"] then
				local typedObject = object.payload :: apiTypes.StageInstanceUpdate

				self.onStageInstanceUpdate:invoke(classes.guild.stageInstance.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["StageInstanceDelete"] then
				local typedObject = object.payload :: apiTypes.StageInstanceDelete

				self.onStageInstanceDelete:invoke(classes.guild.stageInstance.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildSoundboardSoundCreate"] then
				local typedObject = object.payload :: apiTypes.GuildSoundboardSoundCreatePayload

				self.onGuildSoundboardSoundCreate:invoke(classes.soundboard.sound.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildSoundboardSoundUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildSoundboardSoundUpdatePayload

				self.onGuildSoundboardSoundUpdate:invoke(classes.soundboard.sound.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildSoundboardSoundDelete"] then
				local typedObject = object.payload :: apiTypes.GuildSoundboardSoundDeletePayload

				self.onGuildSoundboardSoundDelete:invoke({
					soundId = typedObject.d.sound_id,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildSoundboardSoundsUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildSoundboardSoundsUpdatePayload

				local soundboardSounds = {}
				for _, soundData in next, typedObject.d.soundboard_sounds do
					table.insert(soundboardSounds, classes.soundboard.sound.new(soundData))
				end

				self.onGuildSoundboardSoundsUpdate:invoke({
					guildId = typedObject.d.guild_id,
					soundboardSounds = soundboardSounds,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["VoiceChannelEffectSend"] then
				local typedObject = object.payload :: apiTypes.VoiceChannelEffectSendPayload

				self.onVoiceChannelEffectSend:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					userId = typedObject.d.user_id,
					emoji = typedObject.d.emoji and classes.emoji.new(typedObject.d.emoji),
					animationType = typedObject.d.animation_type,
					animationId = typedObject.d.animation_id,
					soundId = typedObject.d.sound_id,
					soundVolume = typedObject.d.sound_volume,
				})
			end
		end)

		self.state.webSocketManager:connectAsync(gatewayInformation:unwrapOk()):poll()
		self.state.webSocketManager.onConnected:wait()

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within DiscordLuau.Bot

	Returns the list of default soundboard sounds available to all guilds.
]=]
function Bot.Prototype.listDefaultSoundboardSoundsAsync(
	self: Bot
): future.FutureLike<string, { classes.SoundboardSound }>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.listDefaultSoundboardSoundsAsync(request):await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		local sounds = {}
		for _, soundData in next, response:unwrapOk() do
			table.insert(sounds, classes.soundboard.sound.new(soundData))
		end

		return sounds
	end) :: future.FutureLike<string, { classes.SoundboardSound }>
end

--[=[
	@within DiscordLuau.Bot

	Returns the classes.guild object for the given id. If with_counts is set to true, this endpoint will also return
	approximate_member_count and approximate_presence_count for the classes.guild.
]=]
function Bot.Prototype.getGuildAsync(
	self: Bot,
	guildId: string,
	withCount: boolean?
): future.FutureLike<string, classes.Guild>
	return future.Future.new(function()
		local cachedGuildData = self.state.cache.guilds:get(guildId)

		if cachedGuildData then
			return classes.guild.guild.new(self.state, cachedGuildData)
		end

		local request = self.state.rest:newRequest()

		local response = rest.guild
			.getGuildAsync(request, guildId, {
				withCounts = withCount,
			})
			:await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return classes.guild.guild.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, classes.Guild>
end

--[=[
	@within DiscordLuau.Bot

	Returns a channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a channel.
	The channel type is determined by the generic type parameter T.
]=]
function Bot.Prototype.getChannelAsync<T>(self: Bot, channelId: string): future.FutureLike<string, classes.Channel>
	return future.Future.new(function()
		local cachedChannelIdData = self.state.cache.channels:get(channelId)

		if cachedChannelIdData then
			return classes.channels.construct(self.state, cachedChannelIdData) :: any
		end

		local request = self.state.rest:newRequest()

		local response = rest.channel.getChannelAsync(request, channelId):await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return classes.channels.construct(self.state, response:unwrapOk()) :: any
	end) :: future.FutureLike<string, classes.Channel>
end

--[=[
	@within DiscordLuau.Bot

	Returns a DM channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a DM channel.
]=]
function Bot.Prototype.getDMChannelAsync(self: Bot, channelId: string): future.FutureLike<string, classes.DM>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.DM>
end

--[=[
	@within DiscordLuau.Bot

	Returns a Group DM channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a Group DM channel.
]=]
function Bot.Prototype.getGroupDMChannelAsync(self: Bot, channelId: string): future.FutureLike<string, classes.GroupDM>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GroupDM>
end

--[=[
	@within DiscordLuau.Bot

	Returns an announcement channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about an announcement channel.
]=]
function Bot.Prototype.getAnnouncementChannelAsync(
	self: Bot,
	channelId: string
): future.FutureLike<string, classes.GuildAnnouncement>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildAnnouncement>
end

--[=[
	@within DiscordLuau.Bot

	Returns a category channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a category channel.
]=]
function Bot.Prototype.getCategoryChannelAsync(
	self: Bot,
	channelId: string
): future.FutureLike<string, classes.GuildCategory>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildCategory>
end

--[=[
	@within DiscordLuau.Bot

	Returns a directory channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a directory channel.
]=]
function Bot.Prototype.getDirectoryChannelAsync(
	self: Bot,
	channelId: string
): future.FutureLike<string, classes.GuildDirectory>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildDirectory>
end

--[=[
	@within DiscordLuau.Bot

	Returns a stage voice channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a stage voice channel.
]=]
function Bot.Prototype.getStageVCChannelAsync(
	self: Bot,
	channelId: string
): future.FutureLike<string, classes.GuildStageVoice>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildStageVoice>
end

--[=[
	@within DiscordLuau.Bot

	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]=]
function Bot.Prototype.getTextChannelAsync(self: Bot, channelId: string): future.FutureLike<string, classes.GuildText>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildText>
end

--[=[
	@within DiscordLuau.Bot

	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]=]
function Bot.Prototype.getForumChannelAsync(
	self: Bot,
	channelId: string
): future.FutureLike<string, classes.ThreadForum>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.ThreadForum>
end

--[=[
	@within DiscordLuau.Bot

	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]=]
function Bot.Prototype.getMediaChannelAsync(
	self: Bot,
	channelId: string
): future.FutureLike<string, classes.ThreadMedia>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.ThreadMedia>
end

--[=[
	@within DiscordLuau.Bot

	Returns a user object for the given user ID.

	This function sends a request to the Discord API to retrieve information about a user. 
]=]
function Bot.Prototype.getUserAsync(self: Bot, userId: string): future.FutureLike<string, classes.User>
	return future.Future.new(function()
		local cachedUserData = self.state.cache.users:get(userId)

		if cachedUserData then
			return classes.user.new(cachedUserData)
		end

		local request = self.state.rest:newRequest()

		local response = rest.user.getUserAsync(request, userId):await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		local data = response:unwrapOk()

		self.state.cache.users:set(userId, data)

		return classes.user.new(data)
	end) :: future.FutureLike<string, classes.User>
end

--[=[
	@within DiscordLuau.Bot

	Will set the Log Level for the bot, and all instantiated objects within the bot.
]=]
function Bot.Prototype.setLogLevel(self: Bot, logLevel: logger.LogLevel)
	self.logger:setLogLevel(logLevel)

	self.state.webSocketManager.logger:setLogLevel(logLevel)
	self.state.rest.logger:setLogLevel(logLevel)

	for _, shard in self.state.webSocketManager.shards do
		shard.logger:setLogLevel(logLevel)
	end
end

--[=[
	@within DiscordLuau.Bot

	Returns a voice channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a voice channel.
]=]
function Bot.Prototype.getVoiceChannelAsync(self: Bot, channelId: string): future.FutureLike<string, classes.GuildVoice>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildVoice>
end

--[=[
	@within DiscordLuau.Bot

	Requests guild members from the Discord Gateway. Limited to 1 request per guild every 30 seconds
	when using limit=0 with an empty query. Returns a failed future if the guild is currently rate limited.
]=]
function Bot.Prototype.requestGuildMembersAsync(
	self: Bot,
	guildId: apiTypes.Snowflake,
	params: {
		query: string?,
		limit: number,
		presences: boolean?,
		userIds: { apiTypes.Snowflake }?,
		nonce: string?,
	}
): future.FutureLike<string, nil>
	return future.Future.new(function()
		assert(not self.rateLimitedGuilds[guildId], `requestGuildMembers is rate limited for guild {guildId}`)

		self.state.webSocketManager:sendAsync(apiTypes.gateway.opcodes.RequestGuildMembers, {
			guild_id = guildId,
			query = params.query,
			limit = params.limit,
			presences = params.presences,
			user_ids = params.userIds,
			nonce = params.nonce,
		}):await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within DiscordLuau.Bot

	Allows you to set the presence for the Discord Bot.

	:::caution
		Because discord-luau is currently unable to capture when the user cancels the program, we can't close the current
		websocket, which causes us to enter this Zombified state..

		Due to this zombified state - presences may be delayed, or won't render immediately
	:::
]=]
function Bot.Prototype.setPresenceAsync(self: Bot, presence: builders.presenceJSON)
	return self.state.webSocketManager:sendAsync(apiTypes.gateway.opcodes.PresenceUpdate, presence)
end

--[=[
	@within DiscordLuau.Bot

	Construct a new DiscordLuau object
]=]
function Bot.Interface.new(options: {
	token: string,
	intents: number,
	reconnect: boolean?,
	logLevel: logger.LogLevel?,
	globalRatelimit: number?,
})
	local self = setmetatable(
		{
			state = state.state.new({
				token = options.token,
				intents = options.intents,
				logLevel = options.logLevel,
				version = DISCORD_VERSION,
				reconnect = options.reconnect or false,
				globalRatelimit = options.globalRatelimit or 50,
			}),

			logger = logger.new("Bot"),

			onReady = emitter.new(),
			onAllShardsReady = emitter.new(),
			onShardDisconnected = emitter.new(),
			onShardReconnected = emitter.new(),
			onMessage = emitter.new(),
			onMessageChanged = emitter.new(),
			onMessageDeleted = emitter.new(),
			onMessageBulkDeleted = emitter.new(),

			onGroupDMChannelCreate = emitter.new(),
			onCategoryChannelCreate = emitter.new(),
			onAnnouncementChannelCreate = emitter.new(),
			onDirectoryChannelCreate = emitter.new(),
			onDMChannelCreate = emitter.new(),
			onTextChannelCreate = emitter.new(),
			onVoiceChannelCreate = emitter.new(),
			onStageVoiceChannelCreate = emitter.new(),

			onGroupDMChannelUpdated = emitter.new(),
			onCategoryChannelUpdated = emitter.new(),
			onAnnouncementChannelUpdated = emitter.new(),
			onDirectoryChannelUpdated = emitter.new(),
			onDMChannelUpdated = emitter.new(),
			onTextChannelUpdated = emitter.new(),
			onVoiceChannelUpdated = emitter.new(),
			onStageVoiceChannelUpdated = emitter.new(),

			onGroupDMChannelDeleted = emitter.new(),
			onCategoryChannelDeleted = emitter.new(),
			onAnnouncementChannelDeleted = emitter.new(),
			onDirectoryChannelDeleted = emitter.new(),
			onDMChannelDeleted = emitter.new(),
			onTextChannelDeleted = emitter.new(),
			onVoiceChannelDeleted = emitter.new(),
			onStageVoiceChannelDeleted = emitter.new(),

			onUserUpdated = emitter.new(),
			onChannelPinsUpdate = emitter.new(),

			onGuildCreate = emitter.new(),
			onGuildUpdate = emitter.new(),
			onGuildDelete = emitter.new(),

			onGuildMemberBanned = emitter.new(),
			onGuildMemberUnbanned = emitter.new(),

			onGuildMemberJoined = emitter.new(),
			onGuildMemberLeft = emitter.new(),
			onGuildMemberUpdated = emitter.new(),

			onMessageReactionAdd = emitter.new(),
			onMessageReactionRemove = emitter.new(),
			onMessageReactionRemoveAll = emitter.new(),
			onMessageReactionRemoveEmoji = emitter.new(),

			onThreadListSync = emitter.new(),
			onThreadMemberUpdate = emitter.new(),
			onThreadMembersUpdate = emitter.new(),

			onEntitlementCreate = emitter.new(),
			onEntitlementUpdate = emitter.new(),
			onEntitlementDelete = emitter.new(),

			onGuildAuditLogEntryCreate = emitter.new(),

			onGuildEmojisUpdate = emitter.new(),
			onGuildStickersUpdate = emitter.new(),

			onGuildScheduledEventCreate = emitter.new(),
			onGuildScheduledEventUpdate = emitter.new(),
			onGuildScheduledEventDelete = emitter.new(),
			onGuildScheduledEventUserAdd = emitter.new(),
			onGuildScheduledEventUserRemove = emitter.new(),

			onIntegrationCreate = emitter.new(),
			onIntegrationUpdate = emitter.new(),
			onIntegrationDelete = emitter.new(),

			onInviteCreate = emitter.new(),
			onInviteDelete = emitter.new(),

			onAutoModerationRuleCreate = emitter.new(),
			onAutoModerationRuleUpdate = emitter.new(),
			onAutoModerationRuleDelete = emitter.new(),
			onAutoModerationActionExecution = emitter.new(),

			onApplicationCommandPermissionsUpdate = emitter.new(),

			onMessagePollVoteAdd = emitter.new(),
			onMessagePollVoteRemove = emitter.new(),

			onPresenceUpdate = emitter.new(),
			onTypingStart = emitter.new(),
			onGuildMembersChunk = emitter.new(),
			onGuildIntegrationsUpdate = emitter.new(),
			onWebhooksUpdate = emitter.new(),
			onResumed = emitter.new(),

			onVoiceStateUpdate = emitter.new(),
			onVoiceServerUpdate = emitter.new(),

			onStageInstanceCreate = emitter.new(),
			onStageInstanceUpdate = emitter.new(),
			onStageInstanceDelete = emitter.new(),

			onGuildSoundboardSoundCreate = emitter.new(),
			onGuildSoundboardSoundUpdate = emitter.new(),
			onGuildSoundboardSoundDelete = emitter.new(),
			onGuildSoundboardSoundsUpdate = emitter.new(),
			onVoiceChannelEffectSend = emitter.new(),

			onRateLimited = emitter.new(),

			rateLimitedGuilds = {},

			onGuildRoleCreate = emitter.new(),
			onGuildRoleUpdate = emitter.new(),
			onGuildRoleDelete = emitter.new(),

			onAnnouncementThreadCreate = emitter.new(),
			onPublicThreadCreate = emitter.new(),
			onPrivateThreadCreate = emitter.new(),

			onAnnouncementThreadUpdate = emitter.new(),
			onPublicThreadUpdate = emitter.new(),
			onPrivateThreadUpdate = emitter.new(),

			onThreadDelete = emitter.new(),

			onPingInteraction = emitter.new(),
			onCommandInteraction = emitter.new(),
			onComponentInteraction = emitter.new(),
			onAutocompleteInteraction = emitter.new(),
			onModalInteraction = emitter.new(),
		} :: Bot,
		{ __index = Bot.Prototype }
	)

	if options.logLevel then
		self:setLogLevel(options.logLevel)
	end

	return self
end

export type Bot =
	typeof(Bot.Prototype)
	& {
		state: state.State,

		logger: logger.Logger,

		application: classes.Application?,

		user: classes.User?,

		onReady: emitter.Emitter<number>,

		onAllShardsReady: emitter.Emitter<()>,

		onShardDisconnected: emitter.Emitter<number, string>,

		onShardReconnected: emitter.Emitter<number>,

		onMessage: emitter.Emitter<classes.Message>,

		onMessageChanged: emitter.Emitter<classes.Message>,

		onMessageDeleted: emitter.Emitter<{ messageId: apiTypes.Snowflake, channelId: apiTypes.Snowflake, guildId: apiTypes.Snowflake }>,

		onMessageBulkDeleted: emitter.Emitter<{ channelId: string, guildId: string, ids: { string } }>,

		onGroupDMChannelCreate: emitter.Emitter<classes.GroupDM>,

		onCategoryChannelCreate: emitter.Emitter<classes.GuildCategory>,

		onAnnouncementChannelCreate: emitter.Emitter<classes.GuildAnnouncement>,

		onDirectoryChannelCreate: emitter.Emitter<classes.GuildDirectory>,

		onDMChannelCreate: emitter.Emitter<classes.DM>,

		onTextChannelCreate: emitter.Emitter<classes.GuildText>,

		onVoiceChannelCreate: emitter.Emitter<classes.GuildVoice>,

		onStageVoiceChannelCreate: emitter.Emitter<classes.GuildStageVoice>,

		onGroupDMChannelUpdated: emitter.Emitter<classes.GroupDM>,

		onCategoryChannelUpdated: emitter.Emitter<classes.GuildCategory>,

		onAnnouncementChannelUpdated: emitter.Emitter<classes.GuildAnnouncement>,

		onDirectoryChannelUpdated: emitter.Emitter<classes.GuildDirectory>,

		onDMChannelUpdated: emitter.Emitter<classes.DM>,

		onTextChannelUpdated: emitter.Emitter<classes.GuildText>,

		onVoiceChannelUpdated: emitter.Emitter<classes.GuildVoice>,

		onStageVoiceChannelUpdated: emitter.Emitter<classes.GuildStageVoice>,

		onGroupDMChannelDeleted: emitter.Emitter<classes.GroupDM>,

		onCategoryChannelDeleted: emitter.Emitter<classes.GuildCategory>,

		onAnnouncementChannelDeleted: emitter.Emitter<classes.GuildAnnouncement>,

		onDirectoryChannelDeleted: emitter.Emitter<classes.GuildDirectory>,

		onDMChannelDeleted: emitter.Emitter<classes.DM>,

		onTextChannelDeleted: emitter.Emitter<classes.GuildText>,

		onVoiceChannelDeleted: emitter.Emitter<classes.GuildVoice>,

		onStageVoiceChannelDeleted: emitter.Emitter<classes.GuildStageVoice>,

		onUserUpdated: emitter.Emitter<classes.User>,

		onChannelPinsUpdate: emitter.Emitter<{ guildId: string, channelId: string, lastPinTimestamp: stdPolyfills.DateTime? }>,

		onGuildCreate: emitter.Emitter<classes.UnavailableGuild | classes.Guild>,

		onGuildUpdate: emitter.Emitter<classes.Guild>,

		onGuildDelete: emitter.Emitter<classes.UnavailableGuild>,

		onGuildMemberBanned: emitter.Emitter<{ guildId: string, user: classes.User }>,

		onGuildMemberUnbanned: emitter.Emitter<{ guildId: string, user: classes.User }>,

		onGuildMemberJoined: emitter.Emitter<classes.GuildMember & { guildId: string }>,

		onGuildMemberLeft: emitter.Emitter<{ guildId: string, user: classes.User }>,

		onGuildMemberUpdated: emitter.Emitter<{
			guildId: string,
			roles: { string },
			user: classes.User,
			nick: string?,
			avatar: string,
			joinedAt: stdPolyfills.DateTime,
			premiumSince: stdPolyfills.DateTime,
			deaf: boolean?,
			mute: boolean?,
			pending: boolean?,
			communicationDisabledUntil: stdPolyfills.DateTime?,
		}>,

		onMessageReactionAdd: emitter.Emitter<{
			userId: string,
			channelId: string,
			messageId: string,
			guildId: string?,
			member: classes.GuildMember?,
			emoji: classes.Emoji,
			messageAuthorId: string?,
			burst: boolean,
			burstColors: { string },
			reactionType: number,
		}>,

		onMessageReactionRemove: emitter.Emitter<{
			userId: string,
			channelId: string,
			messageId: string,
			guildId: string?,
			emoji: classes.Emoji,
			burst: boolean,
			reactionType: number,
		}>,

		onMessageReactionRemoveAll: emitter.Emitter<{ channelId: string, messageId: string, guildId: string? }>,

		onMessageReactionRemoveEmoji: emitter.Emitter<{ channelId: string, messageId: string, guildId: string?, emoji: classes.Emoji }>,

		onThreadListSync: emitter.Emitter<{ guildId: string, channelIds: { string }?, members: { classes.ThreadMember } }>,

		onThreadMemberUpdate: emitter.Emitter<{ guildId: string, threadMember: classes.ThreadMember }>,

		onThreadMembersUpdate: emitter.Emitter<{
			id: string,
			guildId: string,
			memberCount: number,
			addedMembers: { classes.ThreadMember },
			removedMemberIds: { string }?,
		}>,

		onEntitlementCreate: emitter.Emitter<classes.Entitlement>,

		onEntitlementUpdate: emitter.Emitter<classes.Entitlement>,

		onEntitlementDelete: emitter.Emitter<classes.Entitlement>,

		onGuildAuditLogEntryCreate: emitter.Emitter<classes.AuditLogEntry>,

		onGuildEmojisUpdate: emitter.Emitter<{ guildId: string, emojis: { classes.Emoji } }>,

		onGuildStickersUpdate: emitter.Emitter<{ guildId: string, stickers: { classes.Sticker } }>,

		onGuildScheduledEventCreate: emitter.Emitter<classes.ScheduledEvent>,

		onGuildScheduledEventUpdate: emitter.Emitter<classes.ScheduledEvent>,

		onGuildScheduledEventDelete: emitter.Emitter<classes.ScheduledEvent>,

		onGuildScheduledEventUserAdd: emitter.Emitter<{ guildScheduledEventId: string, userId: string, guildId: string }>,

		onGuildScheduledEventUserRemove: emitter.Emitter<{ guildScheduledEventId: string, userId: string, guildId: string }>,

		onIntegrationCreate: emitter.Emitter<classes.Integration>,

		onIntegrationUpdate: emitter.Emitter<classes.Integration>,

		onIntegrationDelete: emitter.Emitter<{ id: string, guildId: string, applicationId: string? }>,

		onInviteCreate: emitter.Emitter<{
			channelId: string,
			code: string,
			createdAt: stdPolyfills.DateTime,
			guildId: string?,
			inviter: classes.User?,
			maxAge: number,
			maxUses: number,
			targetType: number?,
			targetUser: classes.User?,
			temporary: boolean,
			uses: number,
		}>,

		onInviteDelete: emitter.Emitter<{ channelId: string, code: string, guildId: string? }>,

		onAutoModerationRuleCreate: emitter.Emitter<classes.AutomoderationRule>,

		onAutoModerationRuleUpdate: emitter.Emitter<classes.AutomoderationRule>,

		onAutoModerationRuleDelete: emitter.Emitter<classes.AutomoderationRule>,

		onAutoModerationActionExecution: emitter.Emitter<{
			guildId: string,
			action: apiTypes.AutomoderationActionObject,
			ruleId: string,
			ruleTriggerType: apiTypes.AutomoderationRuleTriggerType,
			userId: string,
			channelId: string?,
			messageId: string?,
			alertSystemMessageId: string?,
			content: string,
			matchedKeyword: string?,
			matchedContent: string?,
		}>,

		onApplicationCommandPermissionsUpdate: emitter.Emitter<{
			id: string,
			applicationId: string,
			guildId: string,
			permissions: { apiTypes.GuildApplicationCommandPermissionObject },
		}>,

		onMessagePollVoteAdd: emitter.Emitter<{ userId: string, channelId: string, messageId: string, guildId: string?, answerId: number }>,

		onMessagePollVoteRemove: emitter.Emitter<{ userId: string, channelId: string, messageId: string, guildId: string?, answerId: number }>,

		onPresenceUpdate: emitter.Emitter<classes.Presence>,

		onTypingStart: emitter.Emitter<{
			channelId: string,
			guildId: string?,
			userId: string,
			timestamp: number,
			member: classes.GuildMember?,
		}>,

		onGuildMembersChunk: emitter.Emitter<{
			guildId: string,
			members: { classes.GuildMember },
			chunkIndex: number,
			chunkCount: number,
			notFound: { string }?,
			nonce: string?,
		}>,

		onGuildIntegrationsUpdate: emitter.Emitter<{ guildId: string }>,

		onWebhooksUpdate: emitter.Emitter<{ guildId: string, channelId: string }>,

		onResumed: emitter.Emitter<()>,

		onVoiceStateUpdate: emitter.Emitter<classes.VoiceState>,

		onVoiceServerUpdate: emitter.Emitter<{ token: string, guildId: string, endpoint: string? }>,

		onStageInstanceCreate: emitter.Emitter<classes.StageInstance>,

		onStageInstanceUpdate: emitter.Emitter<classes.StageInstance>,

		onStageInstanceDelete: emitter.Emitter<classes.StageInstance>,

		onGuildRoleCreate: emitter.Emitter<classes.Role>,

		onGuildRoleUpdate: emitter.Emitter<classes.Role>,

		onGuildRoleDelete: emitter.Emitter<{ guildId: string, roleId: string }>,

		onAnnouncementThreadCreate: emitter.Emitter<classes.Announcement>,

		onPublicThreadCreate: emitter.Emitter<classes.Public>,

		onPrivateThreadCreate: emitter.Emitter<classes.Private>,

		onAnnouncementThreadUpdate: emitter.Emitter<classes.Announcement>,

		onPublicThreadUpdate: emitter.Emitter<classes.Public>,

		onPrivateThreadUpdate: emitter.Emitter<classes.Private>,

		onThreadDelete: emitter.Emitter<{ id: string, guildId: string, parentId: string, type: number }>,

		onPingInteraction: emitter.Emitter<classes.Ping>,

		onCommandInteraction: emitter.Emitter<classes.TypesCommand>,

		onComponentInteraction: emitter.Emitter<classes.Component>,

		onAutocompleteInteraction: emitter.Emitter<classes.Autocomplete>,

		onModalInteraction: emitter.Emitter<classes.Modal>,

		onGuildSoundboardSoundCreate: emitter.Emitter<classes.SoundboardSound>,

		onGuildSoundboardSoundUpdate: emitter.Emitter<classes.SoundboardSound>,

		onGuildSoundboardSoundDelete: emitter.Emitter<{ soundId: string, guildId: string }>,

		onGuildSoundboardSoundsUpdate: emitter.Emitter<{ guildId: string, soundboardSounds: { classes.SoundboardSound } }>,

		onVoiceChannelEffectSend: emitter.Emitter<{
			channelId: string,
			guildId: string,
			userId: string,
			emoji: classes.Emoji?,
			animationType: number?,
			animationId: number?,
			soundId: string?,
			soundVolume: number?,
		}>,

		onRateLimited: emitter.Emitter<{ opcode: number, retryAfter: number, guildId: string? }>,

		rateLimitedGuilds: { [string]: boolean },
	}

return Bot.Interface
