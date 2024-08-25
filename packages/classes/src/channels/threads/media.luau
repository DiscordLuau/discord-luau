--[[
	Implementation of the Discord Media class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local textBehaviour = require("@classes/channels/behaviour/text")
local threadBehaviour = require("@classes/channels/behaviour/thread")
local mediaBehaviour = require("@classes/channels/behaviour/media")

local Media = {}

Media.Interface = {}
Media.Prototype = {}
Media.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	mediaBehaviour,
	textBehaviour,
}

function Media.Prototype.sync(self: Media, channelData: apiTypes.ChannelObject)
	for _, behaviour in Media.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function Media.Interface.new(channelData: apiTypes.ChannelObject): Media
	local self = setmetatable({} :: Media, { __index = Media.Prototype })

	self:sync(channelData)

	return self
end

export type Media =
	typeof(Media.Prototype)
	& {}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour
	& mediaBehaviour.MediaBehaviour

return Media.Interface
