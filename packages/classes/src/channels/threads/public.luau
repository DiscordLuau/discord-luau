--[[
	Implementation of the Discord Public class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local textBehaviour = require("@classes/channels/behaviour/text")
local threadBehaviour = require("@classes/channels/behaviour/thread")

local state = require("@classes/state")

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
