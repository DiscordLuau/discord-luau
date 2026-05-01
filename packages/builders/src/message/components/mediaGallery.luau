--[=[
	@class Builders.Message.MediaGallery
	@__index Prototype

	Implementation of Discord's Media Gallery component as a Luau builder.

	https://discord.com/developers/docs/components/reference#media-gallery
]=]

--[=[
	@prop items { { url: string, description: string?, spoiler: boolean? } }
	@within Builders.Message.MediaGallery
	The list of media items in this gallery. Maximum 10 items.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local MediaGallery = {}

MediaGallery.Prototype = {}
MediaGallery.Interface = {}

--[=[
	@within Builders.Message.MediaGallery

	Adds a media item to the gallery.
]=]
function MediaGallery.Prototype.addItem(
	self: MediaGallery,
	url: string,
	description: string?,
	spoiler: boolean?
): MediaGallery
	assert(#self.items < 10, "media galleries cannot have more than 10 items")

	table.insert(self.items, {
		media = { url = url },
		description = description,
		spoiler = spoiler,
	})

	return self
end

--[=[
	@within Builders.Message.MediaGallery

	Responsible for building the MediaGallery JSON that can be parsed by the Discord API.
]=]
function MediaGallery.Prototype.build(self: MediaGallery): JSON
	assert(#self.items >= 1, "media galleries must have at least 1 item")

	return {
		type = 12,
		items = self.items,
	}
end

--[=[
	@within Builders.Message.MediaGallery

	Responsible for creating a new MediaGallery.
]=]
function MediaGallery.Interface.new(): MediaGallery
	local self = setmetatable(
		{
			items = {},
		} :: MediaGallery,
		{
			__index = MediaGallery.Prototype,
		}
	)

	return self
end

export type MediaGallery = typeof(MediaGallery.Prototype) & {
	items: { apiTypes.MediaGalleryItemObject },
}

export type JSON = apiTypes.MediaGalleryComponentObject

return MediaGallery.Interface
