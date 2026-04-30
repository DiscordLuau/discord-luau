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

				if typedObject.d.type == 0 then
					self.onTextChannelCreate:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelCreate:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelCreate:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelCreate:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelCreate:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelCreate:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelCreate:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelCreate:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelUpdate"] then
				local typedObject = object.payload :: apiTypes.UpdateChannelPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == 0 then
					self.onTextChannelUpdated:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelUpdated:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelUpdated:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelUpdated:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelUpdated:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelUpdated:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelUpdated:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelUpdated:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelDelete"] then
				local typedObject = object.payload :: apiTypes.DeleteChannelPayload

				self.state.cache.channels:remove(typedObject.d.id :: apiTypes.Snowflake)

				if typedObject.d.type == 0 then
					self.onTextChannelDeleted:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelDeleted:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelDeleted:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelDeleted:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelDeleted:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelDeleted:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelDeleted:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 14 then
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
			elseif object.event == apiTypes.gateway.receiveEvents["InteractionCreate"] then
				local typedObject = object.payload :: apiTypes.InteractionCreatePayload

				if typedObject.d.type == 1 then
					self.onPingInteraction:invoke(classes.interaction.types.ping.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onCommandInteraction:invoke(classes.interaction.types.command.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onComponentInteraction:invoke(
						classes.interaction.types.component.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 4 then
					self.onAutocompleteInteraction:invoke(
						classes.interaction.types.autocomplete.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onModalInteraction:invoke(classes.interaction.types.modal.new(self.state, typedObject.d))
				else
					error(`Unknown interaction type: {typedObject.d.type}`)
				end
			end
		end)

		self.state.webSocketManager:connectAsync(gatewayInformation:unwrapOk()):poll()
		self.state.webSocketManager.onConnected:wait()

		return nil
	end) :: future.FutureLike<string, nil>
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

	Will create a new Guild instance, returns this instance.
]=]
function Bot.Prototype.createGuildAsync(
	self: Bot,
	guildData: builders.guildJSON & {
		name: string,
	}
): future.FutureLike<string, classes.Guild>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.createGuildAsync(request, guildData :: any):await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return classes.guild.guild.new(self.state, response:unwrapOk()) :: any
	end) :: future.FutureLike<string, classes.Guild>
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

		onPingInteraction: emitter.Emitter<classes.Ping>,

		onCommandInteraction: emitter.Emitter<classes.TypesCommand>,

		onComponentInteraction: emitter.Emitter<classes.Component>,

		onAutocompleteInteraction: emitter.Emitter<classes.Autocomplete>,

		onModalInteraction: emitter.Emitter<classes.Modal>,
	}

return Bot.Interface
