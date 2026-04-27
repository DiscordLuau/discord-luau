--[=[
	@class Classes.Channels.PrivateThread
	@__index Prototype
	@tag inherit:Classes.Channels.Channel
	@tag inherit:Classes.Channels.GuildBehaviour
	@tag inherit:Classes.Channels.ThreadBehaviour
	@tag inherit:Classes.Channels.TextBehaviour

	Implementation of the Discord Private class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

--[=[
	@prop state Classes.State
	@within Classes.Channels.PrivateThread
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")
local threadBehaviour = require("../behaviour/thread")

local Private = {}

Private.Interface = {}
Private.Prototype = {}
Private.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.Channels.PrivateThread
	@private

	Responsible for syncing data to this private thread object. This is typically called by the API when this object is
	created or updated.
]=]
function Private.Prototype.sync(self: Private, channelData: apiTypes.ChannelObject)
	for _, behaviour in Private.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Channels.PrivateThread
	@private

	Responsible for constructing this class.
]=]
function Private.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Private
	local self = setmetatable(
		{
			state = state,
		} :: Private,
		{ __index = Private.Prototype }
	)

	self:sync(channelData)

	return self
end

export type Private =
	typeof(Private.Prototype)
	& {
		state: state.State,
	}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour

return Private.Interface
