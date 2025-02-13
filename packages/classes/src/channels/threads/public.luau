--[[
	Implementation of the Discord Public class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

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

function Public.Prototype.sync(self: Public, channelData: apiTypes.ChannelObject)
	for _, behaviour in Public.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function Public.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Public
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
