--[[
	Text Behaviour, responsible for implementing the various properties, and methods for a text-able channels.
]]

local apiTypes = require("../../../lune_packages/api_types")
local stdPolyfills = require("../../../lune_packages/std_polyfills")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")
local builders = require("../../../lune_packages/builders")

local message = require("../../message/message")

local TextBehaviour = {}

TextBehaviour.Interface = {}
TextBehaviour.Prototype = {}

--[[
	Delete multiple messages in a single request. This endpoint can only be used on guild channels and requires the
	MANAGE_MESSAGES permission.
]]
function TextBehaviour.Prototype.bulkDeleteMessagesAsync<T>(self: Channel<T>, messageIds: { string }, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message
			.bulkDeleteMessagesAsync(request, self.id, {
				messages = messageIds,
			}, reason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
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
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message
			.getChannelMessagesAsync(request, self.id, {
				around = around,
				before = before,
				after = after,
				limit = limit,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local messages = {}

		for _, messageData in response:unwrapOk() do
			table.insert(messages, message.new(self.state, messageData))
		end

		return messages
	end) :: future.FutureLike<string, { message.Message }>
end

--[[
	Gets a specific message from a channel using its ID. Returns a message object.
]]
function TextBehaviour.Prototype.getMessageAsync<T>(self: Channel<T>, messageId: apiTypes.Snowflake)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message.getChannelMessageAsync(request, self.id, messageId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[[
	Creates a new message in the channel. Returns the created message object.
]]
function TextBehaviour.Prototype.createMessageAsync<T>(self: Channel<T>, json: builders.messageJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message.createMessageAsync(request, self.id, json):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[[
	Gets all pinned messages in the channel. Returns an array of message objects.
]]
function TextBehaviour.Prototype.getPinnedMessagesAsync<T>(self: Channel<T>)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.getPinnedMessagesAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local messages = {}

		for _, messageData in response:unwrapOk() do
			table.insert(messages, message.new(self.state, messageData))
		end

		return messages
	end) :: future.FutureLike<string, { message.Message }>
end

--[[
	Pins a message in the channel.
]]
function TextBehaviour.Prototype.pinMessageAsync<T>(self: Channel<T>, messageId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.pinMessageAsync(request, self.id, messageId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Unpins a message from the channel.
]]
function TextBehaviour.Prototype.unpinMessageAsync<T>(self: Channel<T>, messageId: string, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.unpinMessageAsync(request, self.id, messageId, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Starts a new thread in the channel without an associated message. Returns the thread ID.
]]
function TextBehaviour.Prototype.startThread<T>(self: Channel<T>, json: builders.noMessageThreadJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.startThreadWithoutMessageAsync(request, self.id, json):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().id :: any
	end) :: future.FutureLike<string, apiTypes.Snowflake>
end

function TextBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.lastMessageId = channelData.last_message_id
	class.lastPinTimestamp = channelData.last_pin_timestamp
		and stdPolyfills.datetime.fromIsoDate(channelData.last_pin_timestamp)
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
	lastPinTimestamp: stdPolyfills.DateTime?,
	rateLimitPerUser: number,
}

export type TextBehaviour = TextBehaviourMethods & TextBehaviourProperties

return TextBehaviour.Interface
