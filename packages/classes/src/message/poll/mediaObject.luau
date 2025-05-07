--[=[
	@class Classes.MediaObject
	@__index Prototype

	Implementation of the Discord MediaObject class in Luau

	https://discord.com/developers/docs/resources/poll#poll-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local emoji = require("../../emoji")

local MediaObject = {}

MediaObject.Interface = {}
MediaObject.Prototype = {}

--[=[
	@within Classes.MediaObject
	@private

	Responsible for syncing data to this media object. This is typically called by the API when this object is
	created or updated.
]=]
function MediaObject.Prototype.sync(self: MediaObject, mediaData: apiTypes.PollMediaObject)
	--[=[
		@prop text string?
		@within Classes.MediaObject
		The text content of the media object
	]=]
	self.text = mediaData.text

	--[=[
		@prop emoji Classes.Emoji?
		@within Classes.MediaObject
		The emoji attached to the media object, if any
	]=]
	self.emoji = mediaData.emoji and emoji.new(mediaData.emoji)
end

--[=[
	@within Classes.MediaObject
	@private

	Responsible for constructing this class.
]=]
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
