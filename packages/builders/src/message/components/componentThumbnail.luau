--[=[
	@class Builders.Message.ComponentThumbnail
	@__index Prototype

	Implementation of Discord's Thumbnail component as a Luau builder.
	This is a Components V2 layout component, distinct from the embed thumbnail.

	https://discord.com/developers/docs/components/reference#thumbnail
]=]

--[=[
	@prop url string?
	@within Builders.Message.ComponentThumbnail
	The URL of the media to display. Use attachment://filename for uploaded files.
]=]

--[=[
	@prop description string?
	@within Builders.Message.ComponentThumbnail
	Alt text for the thumbnail image.
]=]

--[=[
	@prop spoiler boolean?
	@within Builders.Message.ComponentThumbnail
	Whether the thumbnail is blurred as a spoiler.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local ComponentThumbnail = {}

ComponentThumbnail.Prototype = {}
ComponentThumbnail.Interface = {}

--[=[
	@within Builders.Message.ComponentThumbnail

	Sets the media URL for the thumbnail.
]=]
function ComponentThumbnail.Prototype.setUrl(self: ComponentThumbnail, url: string): ComponentThumbnail
	self.url = url

	return self
end

--[=[
	@within Builders.Message.ComponentThumbnail

	Sets the alt text description for the thumbnail.
]=]
function ComponentThumbnail.Prototype.setDescription(self: ComponentThumbnail, description: string): ComponentThumbnail
	self.description = description

	return self
end

--[=[
	@within Builders.Message.ComponentThumbnail

	Sets whether the thumbnail is blurred as a spoiler.
]=]
function ComponentThumbnail.Prototype.setSpoiler(self: ComponentThumbnail, spoiler: boolean): ComponentThumbnail
	self.spoiler = spoiler

	return self
end

--[=[
	@within Builders.Message.ComponentThumbnail

	Responsible for building the ComponentThumbnail JSON that can be parsed by the Discord API.
]=]
function ComponentThumbnail.Prototype.build(self: ComponentThumbnail): JSON
	assert(self.url, "ComponentThumbnail.url is required")

	return {
		type = 11,
		media = { url = self.url },
		description = self.description,
		spoiler = self.spoiler,
	}
end

--[=[
	@within Builders.Message.ComponentThumbnail

	Responsible for creating a new ComponentThumbnail.
]=]
function ComponentThumbnail.Interface.new(resource: {
	url: string?,
	description: string?,
	spoiler: boolean?,
}?): ComponentThumbnail
	local self = setmetatable(
		{
			url = nil,
			description = nil,
			spoiler = nil,
		} :: ComponentThumbnail,
		{
			__index = ComponentThumbnail.Prototype,
		}
	)

	if resource then
		if resource.url then
			self:setUrl(resource.url)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.spoiler ~= nil then
			self:setSpoiler(resource.spoiler)
		end
	end

	return self
end

export type ComponentThumbnail = typeof(ComponentThumbnail.Prototype) & {
	url: string?,
	description: string?,
	spoiler: boolean?,
}

export type JSON = apiTypes.ThumbnailComponentObject

return ComponentThumbnail.Interface
