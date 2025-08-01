--[=[
	@class Classes.Public
	@__index Prototype

	Implementation of the Discord Public class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")
local threadBehaviour = require("../behaviour/thread")

local Public = {}

Public.Interface = {}
Public.Prototype = {}
Public.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.Public
	@private

	Responsible for syncing data to this public thread object. This is typically called by the API when this object is
	created or updated.
]=]
function Public.Prototype.sync(self: Public, channelData: apiTypes.ChannelObject)
	for _, behaviour in Public.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Public
	@private

	Responsible for constructing this class.
]=]
function Public.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Public
	--[=[
		@prop state Classes.State
		@within Classes.Public
	]=]
	local self = setmetatable(
		{
			state = state,
		} :: Public,
		{ __index = Public.Prototype }
	)

	self:sync(channelData)

	return self
end

export type Public =
	typeof(Public.Prototype)
	& {
		state: state.State,
	}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour

return Public.Interface
