--[[
	Implementation of the Discord Announcement class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local textBehaviour = require("@classes/channels/behaviour/text")
local threadBehaviour = require("@classes/channels/behaviour/thread")

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

function Announcement.Interface.new(channelData: apiTypes.ChannelObject): Announcement
	local self = setmetatable({} :: Announcement, { __index = Announcement.Prototype })

	self:sync(channelData)

	return self
end

export type Announcement =
	typeof(Announcement.Prototype)
	& {}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour

return Announcement.Interface
