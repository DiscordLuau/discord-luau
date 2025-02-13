--[[
	Implementation of the Discord MediaObject class in Luau

	https://discord.com/developers/docs/resources/poll#poll-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local emoji = require("../../emoji")

local MediaObject = {}

MediaObject.Interface = {}
MediaObject.Prototype = {}

function MediaObject.Prototype.sync(self: MediaObject, mediaData: apiTypes.PollMediaObject)
	self.text = mediaData.text
	self.emoji = mediaData.emoji and emoji.new(mediaData.emoji)
end

function MediaObject.Interface.new(mediaData: apiTypes.PollMediaObject): MediaObject
	local self = setmetatable({} :: MediaObject, { __index = MediaObject.Prototype })

	self:sync(mediaData)

	return self
end

export type MediaObject = typeof(MediaObject.Prototype) & {
	text: string?,
	emoji: emoji.Emoji?,
}

return MediaObject.Interface
