--[[
	Implementation of the Discord Private class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local textBehaviour = require("@classes/channels/behaviour/text")
local threadBehaviour = require("@classes/channels/behaviour/thread")

local state = require("@classes/state")

local Private = {}

Private.Interface = {}
Private.Prototype = {}
Private.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	textBehaviour,
}

function Private.Prototype.sync(self: Private, channelData: apiTypes.ChannelObject)
	for _, behaviour in Private.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

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
