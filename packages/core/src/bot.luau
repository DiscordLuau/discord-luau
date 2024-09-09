local datetime = require("@std-polyfills/datetime")

local future = require("@vendor/future")
local logger = require("@vendor/logger")
local emitter = require("@vendor/emitter")

local gateway = require("@rest/gateway")

local gatewayTypes = require("@api-types/gateway/types")
local apiTypes = require("@api-types/apiTypes")

local receiveEvents = require("@api-types/gateway/receiveEvents")

local application = require("@classes/application/application")
local guild = require("@classes/guild/guild")
local unavailableGuild = require("@classes/guild/unavailableGuild")
local user = require("@classes/user")
local member = require("@classes/guild/member")
local message = require("@classes/message/message")

local autocompleteInteraction = require("@classes/interaction/types/autocomplete")
local commandInteraction = require("@classes/interaction/types/command")
local componentInteraction = require("@classes/interaction/types/component")
local modalInteraction = require("@classes/interaction/types/modal")
local pingInteraction = require("@classes/interaction/types/ping")

local dmChannel = require("@classes/channels/types/dm")
local groupDmChannel = require("@classes/channels/types/groupDm")
local guildAnnouncementChannel = require("@classes/channels/types/guildAnnouncement")
local guildCategoryChannel = require("@classes/channels/types/guildCategory")
local guildDirectoryChannel = require("@classes/channels/types/guildDirectory")
local guildStageVoiceChannel = require("@classes/channels/types/guildStageVoice")
local guildTextChannel = require("@classes/channels/types/guildText")
local guildVoiceChannel = require("@classes/channels/types/guildVoice")

local state = require("@classes/state")

local DISCORD_VERSION = 10

local Bot = {}

Bot.Interface = {}
Bot.Prototype = {}

--[[
	Queries the Discord Gateway for bot information.
	
	This function sends a request to the Discord Gateway to retrieve information
	about the bot, such as the recommended number of shards and session start limit.
]]
function Bot.Prototype.queryGatewayInformation(self: Bot)
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = gateway.getGatewayBotAsync(request):await()

		assert(status == "Fulfilled", tostring(response))

		return response
	end)
end

--[[
	Connects the bot to the Discord gateway asynchronously.

	This function performs the following steps:
	1. Queries gateway information
	2. Asserts that the query was successful
	3. Connects to the WebSocket using the obtained gateway information

	Returns a future that resolves when the connection is established.
]]
function Bot.Prototype.connectAsync(self: Bot)
	return future.new(function()
		local status, gatewayInformation = self:queryGatewayInformation():await()

		assert(status == "Fulfilled", gatewayInformation)

		self.state.webSocketManager.onAllShardsReady:listen(function(data)
			local application = application.new(self.state, data.payload.d.application)
			local user = user.new(data.payload.d.user)

			self.application = application
			self.user = user

			self.state:setApplicationId(application.id)

			self.onAllShardsReady:invoke()
		end)

		self.state.webSocketManager.onDispatch:listen(function(object: {
			shardId: number,
			event: receiveEvents.ReceiveEvent,
			payload: gatewayTypes.Payload<unknown>,
		})
			if object.event == receiveEvents["Ready"] then
				self.onReady:invoke(object.shardId)
			elseif object.event == receiveEvents["MessageCreate"] then
				local typedObject = object.payload :: gatewayTypes.MessageCreatePayload

				self.onMessage:invoke(message.new(self.state, typedObject.d))
			elseif object.event == receiveEvents["MessageUpdate"] then
				local typedObject = object.payload :: gatewayTypes.MessageUpdatePayload

				self.onMessageChanged:invoke(message.new(self.state, typedObject.d))
			elseif object.event == receiveEvents["MessageDelete"] then
				local typedObject = object.payload :: gatewayTypes.MessageDeletePayload

				self.onMessageDeleted:invoke({
					messageId = typedObject.d.id,
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == receiveEvents["MessageDeleteBulk"] then
				local typedObject = object.payload :: gatewayTypes.MessageDeleteBulkPayload

				self.onMessageBulkDeleted:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					ids = typedObject.d.ids,
				})
			elseif object.event == receiveEvents["ChannelCreate"] then
				local typedObject = object.payload :: gatewayTypes.CreateChannelPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == 0 then
					self.onTextChannelCreate:invoke(guildTextChannel.new(typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelCreate:invoke(dmChannel.new(typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelCreate:invoke(guildVoiceChannel.new(typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelCreate:invoke(groupDmChannel.new(typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelCreate:invoke(guildCategoryChannel.new(typedObject.d))
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelCreate:invoke(guildAnnouncementChannel.new(typedObject.d))
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelCreate:invoke(guildStageVoiceChannel.new(typedObject.d))
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelCreate:invoke(guildDirectoryChannel.new(typedObject.d))
				end
			elseif object.event == receiveEvents["ChannelUpdate"] then
				local typedObject = object.payload :: gatewayTypes.UpdateChannelPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == 0 then
					self.onTextChannelUpdated:invoke(guildTextChannel.new(typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelUpdated:invoke(dmChannel.new(typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelUpdated:invoke(guildVoiceChannel.new(typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelUpdated:invoke(groupDmChannel.new(typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelUpdated:invoke(guildCategoryChannel.new(typedObject.d))
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelUpdated:invoke(guildAnnouncementChannel.new(typedObject.d))
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelUpdated:invoke(guildStageVoiceChannel.new(typedObject.d))
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelUpdated:invoke(guildDirectoryChannel.new(typedObject.d))
				end
			elseif object.event == receiveEvents["ChannelDelete"] then
				local typedObject = object.payload :: gatewayTypes.DeleteChannelPayload

				if typedObject.d.type == 0 then
					self.onTextChannelDeleted:invoke(guildTextChannel.new(typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelDeleted:invoke(dmChannel.new(typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelDeleted:invoke(guildVoiceChannel.new(typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelDeleted:invoke(groupDmChannel.new(typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelDeleted:invoke(guildCategoryChannel.new(typedObject.d))
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelDeleted:invoke(guildAnnouncementChannel.new(typedObject.d))
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelDeleted:invoke(guildStageVoiceChannel.new(typedObject.d))
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelDeleted:invoke(guildDirectoryChannel.new(typedObject.d))
				end
			elseif object.event == receiveEvents["ChannelPinsUpdate"] then
				local typedObject = object.payload :: gatewayTypes.ChannelPinsUpdatePayload

				self.onChannelPinsUpdate:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					lastPinTimestamp = typedObject.d.last_pin_timestamp
						and datetime.fromIsoDate(typedObject.d.last_pin_timestamp),
				})
			elseif object.event == receiveEvents["UserUpdate"] then
				local typedObject = object.payload :: gatewayTypes.UserUpdatePayload

				self.state.cache.users:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				self.onUserUpdated:invoke(user.new(typedObject.d))
			elseif object.event == receiveEvents["GuildCreate"] then
				local typedObject = object.payload :: gatewayTypes.GuildCreatePayload

				if typedObject.d.unavailable then
					self.onGuildCreate:invoke(unavailableGuild.new(self.state, typedObject.d.id :: string))
				else
					-- fixme: using 'any' below because otherwise typedObject.d doesn't work with apiTypes.GuildObject?
					local guildData = typedObject.d :: any

					self.state.cache.guilds:set(typedObject.d.id :: apiTypes.Snowflake, guildData)

					self.onGuildCreate:invoke(guild.new(self.state, guildData))
				end
			elseif object.event == receiveEvents["GuildUpdate"] then
				local typedObject = object.payload :: gatewayTypes.GuildUpdatePayload

				self.state.cache.guilds:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				self.onGuildUpdate:invoke(guild.new(self.state, typedObject.d))
			elseif object.event == receiveEvents["GuildDelete"] then
				local typedObject = object.payload :: gatewayTypes.GuildDeletePayload

				self.onGuildDelete:invoke(unavailableGuild.new(self.state, typedObject.d.id))
			elseif object.event == receiveEvents["GuildBanAdd"] then
				local typedObject = object.payload :: gatewayTypes.GuildBanAddPayload

				self.state.cache.users:set(typedObject.d.user.id :: apiTypes.Snowflake, typedObject.d.user)

				self.onGuildMemberBanned:invoke({
					guildId = typedObject.d.guild_id,
					user = user.new(typedObject.d.user),
				})
			elseif object.event == receiveEvents["GuildBanRemove"] then
				local typedObject = object.payload :: gatewayTypes.GuildBanRemovePayload

				self.state.cache.users:set(typedObject.d.user.id :: apiTypes.Snowflake, typedObject.d.user)

				self.onGuildMemberUnbanned:invoke({
					guildId = typedObject.d.guild_id,
					user = user.new(typedObject.d.user),
				})
			elseif object.event == receiveEvents["GuildMemberAdd"] then
				local typedObject = object.payload :: gatewayTypes.GuildMemberAddPayload

				self.onGuildMemberJoined:invoke({
					guildId = typedObject.d.guild_id,
					member = member.new(typedObject.d),
				})
			elseif object.event == receiveEvents["GuildMemberRemove"] then
				local typedObject = object.payload :: gatewayTypes.GuildMemberRemovePayload

				self.onGuildMemberLeft:invoke({
					guildId = typedObject.d.guild_id,
					user = user.new(typedObject.d.user),
				})
			elseif object.event == receiveEvents["GuildMemberUpdate"] then
				local typedObject = object.payload :: gatewayTypes.GuildMemberUpdatePayload

				self.onGuildMemberUpdated:invoke({
					guildId = typedObject.d.guild_id,
					roles = typedObject.d.roles,
					user = user.new(typedObject.d.user),
					nick = typedObject.d.nick,
					avatar = typedObject.d.avatar,
					joinedAt = typedObject.d.joined_at and datetime.fromIsoDate(typedObject.d.joined_at),
					premiumSince = typedObject.d.premium_since and datetime.fromIsoDate(typedObject.d.premium_since),
					deaf = typedObject.d.deaf,
					mute = typedObject.d.mute,
					pending = typedObject.d.pending,
					communicationDisabledUntil = typedObject.d.communication_disabled_until
						and datetime.fromIsoDate(typedObject.d.communication_disabled_until),
				})
			elseif object.event == receiveEvents["InteractionCreate"] then
				local typedObject = object.payload :: gatewayTypes.InteractionCreatePayload

				if typedObject.d.type == 1 then
					self.onPingInteraction:invoke(pingInteraction.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onCommandInteraction:invoke(commandInteraction.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onComponentInteraction:invoke(componentInteraction.new(self.state, typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onAutocompleteInteraction:invoke(autocompleteInteraction.new(self.state, typedObject.d))
				elseif typedObject.d.type == 5 then
					self.onModalInteraction:invoke(modalInteraction.new(self.state, typedObject.d))
				else
					error(`Unknown interaction type: {typedObject.d.type}`)
				end
			end
		end)

		self.state.webSocketManager:connectAsync(gatewayInformation)
		self.state.webSocketManager.onConnected:wait()
	end)
end

function Bot.Interface.new(options: {
	token: string,
	intents: number,
})
	local self = setmetatable(
		{
			state = state.new(options.token, options.intents, DISCORD_VERSION),
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

		application: application.Application?,
		user: user.User?,

		onReady: emitter.Emitter<number>,
		onAllShardsReady: emitter.Emitter<()>,

		onMessage: emitter.Emitter<message.Message>,
		onMessageChanged: emitter.Emitter<message.Message>,
		onMessageDeleted: emitter.Emitter<{ messageId: apiTypes.Snowflake, channelId: apiTypes.Snowflake, guildId: apiTypes.Snowflake }>,
		onMessageBulkDeleted: emitter.Emitter<{ channelId: string, guildId: string, ids: { string } }>,

		onGroupDMChannelCreate: emitter.Emitter<groupDmChannel.GroupDM>,
		onCategoryChannelCreate: emitter.Emitter<guildCategoryChannel.GuildCategory>,
		onAnnouncementChannelCreate: emitter.Emitter<guildAnnouncementChannel.GuildAnnouncement>,
		onDirectoryChannelCreate: emitter.Emitter<guildDirectoryChannel.GuildDirectory>,
		onDMChannelCreate: emitter.Emitter<dmChannel.DM>,
		onTextChannelCreate: emitter.Emitter<guildTextChannel.GuildText>,
		onVoiceChannelCreate: emitter.Emitter<guildVoiceChannel.GuildVoice>,
		onStageVoiceChannelCreate: emitter.Emitter<guildStageVoiceChannel.GuildStageVoice>,

		onGroupDMChannelUpdated: emitter.Emitter<groupDmChannel.GroupDM>,
		onCategoryChannelUpdated: emitter.Emitter<guildCategoryChannel.GuildCategory>,
		onAnnouncementChannelUpdated: emitter.Emitter<guildAnnouncementChannel.GuildAnnouncement>,
		onDirectoryChannelUpdated: emitter.Emitter<guildDirectoryChannel.GuildDirectory>,
		onDMChannelUpdated: emitter.Emitter<dmChannel.DM>,
		onTextChannelUpdated: emitter.Emitter<guildTextChannel.GuildText>,
		onVoiceChannelUpdated: emitter.Emitter<guildVoiceChannel.GuildVoice>,
		onStageVoiceChannelUpdated: emitter.Emitter<guildStageVoiceChannel.GuildStageVoice>,

		onGroupDMChannelDeleted: emitter.Emitter<groupDmChannel.GroupDM>,
		onCategoryChannelDeleted: emitter.Emitter<guildCategoryChannel.GuildCategory>,
		onAnnouncementChannelDeleted: emitter.Emitter<guildAnnouncementChannel.GuildAnnouncement>,
		onDirectoryChannelDeleted: emitter.Emitter<guildDirectoryChannel.GuildDirectory>,
		onDMChannelDeleted: emitter.Emitter<dmChannel.DM>,
		onTextChannelDeleted: emitter.Emitter<guildTextChannel.GuildText>,
		onVoiceChannelDeleted: emitter.Emitter<guildVoiceChannel.GuildVoice>,
		onStageVoiceChannelDeleted: emitter.Emitter<guildStageVoiceChannel.GuildStageVoice>,

		onUserUpdated: emitter.Emitter<user.User>,
		onChannelPinsUpdate: emitter.Emitter<{ guildId: string, channelId: string, lastPinTimestamp: datetime.DateTime? }>,

		onGuildCreate: emitter.Emitter<unavailableGuild.UnavailableGuild | guild.Guild>,
		onGuildUpdate: emitter.Emitter<guild.Guild>,
		onGuildDelete: emitter.Emitter<unavailableGuild.UnavailableGuild>,

		onGuildMemberBanned: emitter.Emitter<{ guildId: string, user: user.User }>,
		onGuildMemberUnbanned: emitter.Emitter<{ guildId: string, user: user.User }>,
		onGuildMemberJoined: emitter.Emitter<member.Member & { guildId: string }>,
		onGuildMemberLeft: emitter.Emitter<{ guildId: string, user: user.User }>,

		onGuildMemberUpdated: emitter.Emitter<{
			guildId: string,
			roles: { string },
			user: user.User,
			nick: string?,
			avatar: string,
			joinedAt: datetime.DateTime,
			premiumSince: datetime.DateTime,
			deaf: boolean?,
			mute: boolean?,
			pending: boolean?,
			communicationDisabledUntil: datetime.DateTime?,
		}>,

		onPingInteraction: emitter.Emitter<pingInteraction.Ping>,
		onCommandInteraction: emitter.Emitter<commandInteraction.Command>,
		onComponentInteraction: emitter.Emitter<componentInteraction.Component>,
		onAutocompleteInteraction: emitter.Emitter<autocompleteInteraction.Autocomplete>,
		onModalInteraction: emitter.Emitter<modalInteraction.Modal>,
	}

return Bot.Interface
