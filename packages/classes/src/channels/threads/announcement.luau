--[[
	Implementation of the Discord Announcement class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")
local threadBehaviour = require("../behaviour/thread")

local Announcement = {}

Announcement.Interface = {}
Announcement.Prototype = {}
Announcement.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	textBehaviour,
}

function Announcement.Prototype.sync(self: Announcement, channelData: apiTypes.ChannelObject)
	for _, behaviour in Announcement.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function Announcement.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Announcement
	local self = setmetatable(
		{
			state = state,
		} :: Announcement,
		{ __index = Announcement.Prototype }
	)

	self:sync(channelData)

	return self
end

export type Announcement =
	typeof(Announcement.Prototype)
	& {
		state: state.State,
	}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour

return Announcement.Interface
