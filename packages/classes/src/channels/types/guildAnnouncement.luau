--[[
	Implementation of the Discord GuildAnnouncement class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

-- https://discord.com/developers/docs/resources/message#crosspost-message
-- https://discord.com/developers/docs/resources/channel#follow-announcement-channel

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")

local GuildAnnouncement = {}

GuildAnnouncement.Interface = {}
GuildAnnouncement.Prototype = {}
GuildAnnouncement.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	textBehaviour,
}

function GuildAnnouncement.Prototype.sync(self: GuildAnnouncement, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildAnnouncement.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function GuildAnnouncement.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildAnnouncement
	local self = setmetatable(
		{
			state = state,
		} :: GuildAnnouncement,
		{ __index = GuildAnnouncement.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GuildAnnouncement = typeof(GuildAnnouncement.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & textBehaviour.TextBehaviour & guildBehaviour.GuildBehaviour

return GuildAnnouncement.Interface
