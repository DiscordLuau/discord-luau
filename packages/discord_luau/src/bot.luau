local future = require("../luau_packages/future")
local stdPolyfills = require("../lune_packages/std_polyfills")
local apiTypes = require("../lune_packages/api_types")
local state = require("../lune_packages/state")
local rest = require("../lune_packages/rest")
local logger = require("../lune_packages/logger")
local emitter = require("../luau_packages/emitter")
local classes = require("../lune_packages/classes")

local DISCORD_VERSION = 10

-- https://discord.com/developers/docs/resources/channel#get-channel

local Bot = {}

Bot.Interface = {}
Bot.Prototype = {}

--[[
	Queries the Discord Gateway for bot information.
	
	This function sends a request to the Discord Gateway to retrieve information
	about the bot, such as the recommended number of shards and session start limit.
]]
function Bot.Prototype.queryGatewayInformation(self: Bot)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.gateway.getGatewayBotAsync(request):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk()
	end) :: future.FutureLike<string, apiTypes.GetGatewayBotResponse>
end

--[[
	Connects the bot to the Discord gateway asynchronously.

	This function performs the following steps:
	1. Queries gateway information
	2. Asserts that the query was successful
	3. Connects to the WebSocket using the obtained gateway information

	Returns a async that resolves when the connection is established.
]]
function Bot.Prototype.connectAsync(self: Bot)
	return future.Future.new(function()
		local gatewayInformation = self:queryGatewayInformation():await()

		assert(gatewayInformation:isOk(), gatewayInformation:unwrapErr())

		self.state.webSocketManager.onAllShardsReady:listen(function(data)
			local application = classes.application.application.new(self.state, data.payload.d.application)
			local user = classes.user.new(data.payload.d.user)

			self.application = application
			self.user = user

			self.state:setApplicationId(application.id)

			self.onAllShardsReady:invoke()
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

--[[
	Returns the classes.guild object for the given id. If with_counts is set to true, this endpoint will also return
	approximate_member_count and approximate_presence_count for the classes.guild.
]]
function Bot.Prototype.getGuildAsync(self: Bot, guildId: string, withCount: boolean?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.getGuildAsync(request, guildId, {
				withCounts = withCount,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return classes.guild.guild.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, classes.Guild>
end

--[[
	Returns a channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a channel.
	The channel type is determined by the generic type parameter T.
]]
function Bot.Prototype.getChannelAsync<T>(self: Bot, channelId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.getChannelAsync(request, channelId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return classes.channels.construct(self.state, response:unwrapOk()) :: any
	end) :: future.FutureLike<string, classes.Channel>
end

--[[
	Returns a DM channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a DM channel.
]]
function Bot.Prototype.getDMChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.DM>
end

--[[
	Returns a Group DM channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a Group DM channel.
]]
function Bot.Prototype.getGroupDMChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GroupDM>
end

--[[
	Returns an announcement channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about an announcement channel.
]]
function Bot.Prototype.getAnnouncementChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildAnnouncement>
end

--[[
	Returns a category channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a category channel.
]]
function Bot.Prototype.getCategoryChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildCategory>
end

--[[
	Returns a directory channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a directory channel.
]]
function Bot.Prototype.getDirectoryChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildDirectory>
end

--[[
	Returns a stage voice channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a stage voice channel.
]]
function Bot.Prototype.getStageVCChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildStageVoice>
end

--[[
	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]]
function Bot.Prototype.getTextChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildText>
end

--[[
	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]]
function Bot.Prototype.getForumChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.ThreadForum>
end

--[[
	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]]
function Bot.Prototype.getMediaChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.ThreadMedia>
end

--[[
	Returns a voice channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a voice channel.
]]
function Bot.Prototype.getVoiceChannelAsync(self: Bot, channelId: string)
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildVoice>
end

function Bot.Interface.new(options: {
	token: string,
	intents: number,
})
	local self = setmetatable(
		{
			state = state.state.new(options.token, options.intents, DISCORD_VERSION),
			logger = logger.new("Bot"),

			onReady = emitter.new(),
			onAllShardsReady = emitter.new(),
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
		onCommandInteraction: emitter.Emitter<classes.Command>,
		onComponentInteraction: emitter.Emitter<classes.Component>,
		onAutocompleteInteraction: emitter.Emitter<classes.Autocomplete>,
		onModalInteraction: emitter.Emitter<classes.Modal>,
	}

return Bot.Interface
