--[[
	Channel Behaviour, responsible for implementing the various properties, and methods for a generic
	channel object.
]]

local future = require("@vendor/future")

local apiTypes: string = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local channelRest = require("@rest/channel")

local state = require("@classes/state")
local channelBitflags = require("@classes/bitflags/channel")

local channelBuilder = require("@builders/channel")

local ChannelBehaviour = {}

ChannelBehaviour.Interface = {}
ChannelBehaviour.Prototype = {}

--[[
	Delete a channel, or close a private message. Requires the MANAGE_CHANNELS permission for the guild, or MANAGE_THREADS
	if the channel is a thread. Deleting a category does not delete its child channels; they will have their parent_id
	removed and a Channel Update Gateway event will fire for each of them.
]]
function ChannelBehaviour.Prototype.deleteChannelAsync<T>(self: Channel<T>): future.Future<T>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.deleteOrCloseChannelAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		self:sync(response)

		return self
	end)
end

--[[
	Post a typing indicator for the specified channel, which expires after 10 seconds.

	Generally bots should not use this route. However, if a bot is responding to a command and expects the computation to
	take a few seconds, this endpoint may be called to let the user know that the bot is processing their message.
]]
function ChannelBehaviour.Prototype.triggerTypingIndicatorAsync<T>(self: Channel<T>): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.triggerTypingIndicatorAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Lists all private archived threads that the current user has joined. Returns thread and member information.
]]
function ChannelBehaviour.Prototype.modifyAsync<T>(
	self: Channel<T>,
	json: channelBuilder.JSON,
	reason: string?
): future.Future<Channel<T>>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.modifyChannelAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		self:sync(response)

		return self
	end)
end

function ChannelBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.type = channelTypes.ChannelTypes[channelData.type]

	class.id = channelData.id
	class.name = channelData.name

	class.flags = channelData.flags and channelBitflags.new(channelData.flags)
end

function ChannelBehaviour.Interface.inheritMethods(class: any)
	for key, value in ChannelBehaviour.Prototype do
		class[key] = value
	end
end

type Channel<T> = T & ChannelBehaviour & {
	state: state.State,

	sync: (...any) -> (),
}

export type ChannelBehaviourMethods = typeof(ChannelBehaviour.Prototype)
export type ChannelBehaviourProperties = {
	id: apiTypes.Snowflake,
	type: channelTypes.ChannelType,
	name: string?,
	flags: channelBitflags.ChannelBitflag?,
}

export type ChannelBehaviour = ChannelBehaviourMethods & ChannelBehaviourProperties

return ChannelBehaviour.Interface
