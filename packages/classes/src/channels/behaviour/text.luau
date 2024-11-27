--[[
	Text Behaviour, responsible for implementing the various properties, and methods for a text-able channels.
]]

local datetime = require("@std-polyfills/datetime")

local future = require("@vendor/future")

local channelRest = require("@rest/channel")
local messageRest = require("@rest/message")

local apiTypes = require("@api-types/apiTypes")

local state = require("@classes/state")
local message = require("@classes/message/message")

local messageBuilder = require("@builders/message/message")
local noMessageThreadBuilder = require("@builders/thread/noMessageThread")

local TextBehaviour = {}

TextBehaviour.Interface = {}
TextBehaviour.Prototype = {}

--[[
	Delete multiple messages in a single request. This endpoint can only be used on guild channels and requires the
	MANAGE_MESSAGES permission.
]]
function TextBehaviour.Prototype.bulkDeleteMessagesAsync<T>(
	self: Channel<T>,
	messageIds: { string },
	reason: string?
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = messageRest
			.bulkDeleteMessagesAsync(request, self.id, {
				messages = messageIds,
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Gets messages from a channel. Returns an array of message objects.
]]
function TextBehaviour.Prototype.getMessagesAsync<T>(
	self: Channel<T>,
	around: apiTypes.Snowflake?,
	before: apiTypes.Snowflake?,
	after: apiTypes.Snowflake?,
	limit: number?
): future.Future<{ message.Message }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = messageRest
			.getChannelMessagesAsync(request, self.id, {
				around = around,
				before = before,
				after = after,
				limit = limit,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local messages = {}

		for _, messageData in response do
			table.insert(messages, message.new(self.state, messageData))
		end

		return messages
	end)
end

--[[
	Gets a specific message from a channel using its ID. Returns a message object.
]]
function TextBehaviour.Prototype.getMessageAsync<T>(
	self: Channel<T>,
	messageId: apiTypes.Snowflake
): future.Future<message.Message>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = messageRest.getChannelMessageAsync(request, self.id, messageId):await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	Creates a new message in the channel. Returns the created message object.
]]
function TextBehaviour.Prototype.createMessageAsync<T>(
	self: Channel<T>,
	json: messageBuilder.JSON
): future.Future<message.Message>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = messageRest.createMessageAsync(request, self.id, json):await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	Gets all pinned messages in the channel. Returns an array of message objects.
]]
function TextBehaviour.Prototype.getPinnedMessagesAsync<T>(self: Channel<T>): future.Future<{ message.Message }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.getPinnedMessagesAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local messages = {}

		for _, messageData in response do
			table.insert(messages, message.new(self.state, messageData))
		end

		return messages
	end)
end

--[[
	Pins a message in the channel.
]]
function TextBehaviour.Prototype.pinMessageAsync<T>(self: Channel<T>, messageId: string): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.pinMessageAsync(request, self.id, messageId):await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Unpins a message from the channel.
]]
function TextBehaviour.Prototype.unpinMessageAsync<T>(
	self: Channel<T>,
	messageId: string,
	reason: string?
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.unpinMessageAsync(request, self.id, messageId, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Starts a new thread in the channel without an associated message. Returns the thread ID.
]]
function TextBehaviour.Prototype.startThread<T>(self: Channel<T>, json: noMessageThreadBuilder.JSON): future.Future<string>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.startThreadWithoutMessageAsync(request, self.id, json):await()

		assert(status == "Fulfilled", tostring(response))

		return response.id
	end)
end

function TextBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.lastMessageId = channelData.last_message_id
	class.lastPinTimestamp = channelData.last_pin_timestamp and datetime.fromIsoDate(channelData.last_pin_timestamp)
	class.rateLimitPerUser = channelData.rate_limit_per_user
end

function TextBehaviour.Interface.inheritMethods(class: any)
	for key, value in TextBehaviour.Prototype do
		class[key] = value
	end
end

type Channel<T> = T & TextBehaviour & {
	state: state.State,
	id: string,
	guildId: string,

	sync: (...any) -> (),
}

export type TextBehaviourMethods = typeof(TextBehaviour.Prototype)
export type TextBehaviourProperties = {
	lastMessageId: string?,
	lastPinTimestamp: datetime.DateTime?,
	rateLimitPerUser: number,
}

export type TextBehaviour = TextBehaviourMethods & TextBehaviourProperties

return TextBehaviour.Interface
