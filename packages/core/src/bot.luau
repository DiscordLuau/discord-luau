local future = require("@vendor/future")
local logger = require("@vendor/logger")
local emitter = require("@vendor/emitter")

local gateway = require("@rest/gateway")

local gatewayTypes = require("@api-types/gateway/types")
local apiTypes = require("@api-types/apiTypes")

local receiveEvents = require("@api-types/gateway/receiveEvents")

local guild = require("@classes/guild/guild")
local user = require("@classes/user")
local guildMember = require("@classes/guildMember")
local message = require("@classes/message/message")

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

		assert(status == "Fulfilled", response)

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
			onMessage = emitter.new(),
			onMessageChanged = emitter.new(),
			onMessageDeleted = emitter.new(),
			onMessageBulkDeleted = emitter.new(),
			onChannelCreate = emitter.new(),
			onChannelUpdate = emitter.new(),
			onChannelDelete = emitter.new(),
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
			onInteraction = emitter.new(),
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

		onReady: emitter.Emitter<number>,

		onMessage: emitter.Emitter<message.Message>,
		onMessageChanged: emitter.Emitter<message.Message>,
		onMessageDeleted: emitter.Emitter<{ messageId: apiTypes.Snowflake, channelId: apiTypes.Snowflake, guildId: apiTypes.Snowflake }>,
		onMessageBulkDeleted: emitter.Emitter<{ channelId: string, guildId: string, ids: { string } }>,

		onChannelCreate: emitter.Emitter<unknown>,
		onChannelUpdate: emitter.Emitter<unknown>,
		onChannelDelete: emitter.Emitter<unknown>,

		onUserUpdated: emitter.Emitter<user.User>,

		onChannelPinsUpdate: emitter.Emitter<{ guildId: string, channelId: string, lastPinTimestamp: string }>,

		onGuildCreate: emitter.Emitter<guild.Guild>,
		onGuildUpdate: emitter.Emitter<guild.Guild>,
		onGuildDelete: emitter.Emitter<guild.Guild>,

		onGuildMemberBanned: emitter.Emitter<{ guildId: string, user: user.User }>,
		onGuildMemberUnbanned: emitter.Emitter<{ guildId: string, user: user.User }>,

		onGuildMemberJoined: emitter.Emitter<guildMember.GuildMember & { guildId: string }>,
		onGuildMemberLeft: emitter.Emitter<{ guildId: string, user: user.User }>,
		onGuildMemberUpdated: emitter.Emitter<{
			guildId: string,
			roles: { string },
			user: user.User,
			nick: string?,
			avatar: string,
			joinedAt: string,
			premiumSince: string,
			deaf: boolean?,
			mute: boolean?,
			pending: boolean?,
			communicationDisabledUntil: string?,
		}>,

		onInteraction: emitter.Emitter<unknown>,
	}

return Bot.Interface
