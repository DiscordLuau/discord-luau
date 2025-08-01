--[=[
	@class Classes.Channel
	@__index Prototype

	Implementation of the Discord Channel class in Luau. Responsible for implementing the various properties, and methods
	for a generic channel object.
]=]

local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")
local builders = require("../../../lune_packages/builders")

local channelBitflags = require("../../bitflags/channel")

local ChannelBehaviour = {}

ChannelBehaviour.Interface = {}
ChannelBehaviour.Prototype = {}

--[=[
	@within Classes.Channel
	@private

	Delete a channel, or close a private message. Requires the MANAGE_CHANNELS permission for the guild, or MANAGE_THREADS
	if the channel is a thread. Deleting a category does not delete its child channels; they will have their parent_id
	removed and a Channel Update Gateway event will fire for each of them.
]=]
function ChannelBehaviour.Prototype.deleteChannelAsync<T>(self: Channel<T>)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.deleteOrCloseChannelAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self:sync(response:unwrapOk())

		return self
	end) :: future.FutureLike<string, Channel<T>>
end

--[=[
	@within Classes.Channel

	Post a typing indicator for the specified channel, which expires after 10 seconds.

	Generally bots should not use this route. However, if a bot is responding to a command and expects the computation to
	take a few seconds, this endpoint may be called to let the user know that the bot is processing their message.
]=]
function ChannelBehaviour.Prototype.triggerTypingIndicatorAsync<T>(self: Channel<T>)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.triggerTypingIndicatorAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channel

	Lists all private archived threads that the current user has joined. Returns thread and member information.
]=]
function ChannelBehaviour.Prototype.modifyAsync<T>(self: Channel<T>, json: builders.channelJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.modifyChannelAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self:sync(response:unwrapOk())

		return self
	end) :: future.FutureLike<string, Channel<T>>
end

function ChannelBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	--[=[
		@prop type string
		@within Classes.Channel
		The type of the channel, indicating its functionality and behavior.
	]=]
	class.type = apiTypes.channel.ChannelTypes[channelData.type]

	--[=[
		@prop id string
		@within Classes.Channel
		The unique identifier for this channel.
	]=]
	class.id = channelData.id

	--[=[
		@prop name string?
		@within Classes.Channel
		The name of the channel.
	]=]
	class.name = channelData.name

	--[=[
		@prop flags Classes.ChannelBitflag?
		@within Classes.Channel
		The flags that indicate various properties and states of the channel.
	]=]
	class.flags = channelData.flags and channelBitflags.new(channelData.flags)
end

--[=[
	@within Classes.Channel
	@private
]=]
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
	type: apiTypes.ChannelType,
	name: string?,
	flags: channelBitflags.ChannelBitflag?,
}

export type ChannelBehaviour = ChannelBehaviourMethods & ChannelBehaviourProperties

return ChannelBehaviour.Interface
