--[=[
	@class Classes.Private
	@__index Prototype

	Implementation of the Discord Private class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

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
	@within Classes.Private
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
	@within Classes.Private
	@private

	Responsible for constructing this class.
]=]
function Private.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Private
	local self = setmetatable(
		{
			--[=[
				@prop state Classes.State
				@within Classes.Private
			]=]
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
