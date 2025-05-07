--[=[
	@class Classes.Thumbnail
	@__index Prototype

	Implementation of the Discord Thumbnail class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-thumbnail-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Thumbnail = {}

Thumbnail.Interface = {}
Thumbnail.Prototype = {}

--[=[
	@within Classes.Thumbnail
	@private

	Responsible for syncing data to this thumbnail object. This is typically called by the API when this object is
	created or updated.
]=]
function Thumbnail.Prototype.sync(self: Thumbnail, thumbnailData: apiTypes.EmbedThumbnailObject)
	--[=[
		@prop url string
		@within Classes.Thumbnail

		The source URL of the thumbnail
	]=]
	self.url = thumbnailData.url

	--[=[
		@prop proxyUrl string?
		@within Classes.Thumbnail

		A proxied URL of the thumbnail
	]=]
	self.proxyUrl = thumbnailData.proxy_url

	--[=[
		@prop height number?
		@within Classes.Thumbnail

		Height of the thumbnail
	]=]
	self.height = thumbnailData.height

	--[=[
		@prop width number?
		@within Classes.Thumbnail

		Width of the thumbnail
	]=]
	self.width = thumbnailData.width
end

--[=[
	@within Classes.Thumbnail
	@private

	Responsible for constructing this class.
]=]
function Thumbnail.Interface.new(thumbnailData: apiTypes.EmbedThumbnailObject): Thumbnail
	local self = setmetatable({} :: Thumbnail, { __index = Thumbnail.Prototype })

	self:sync(thumbnailData)

	return self
end

export type Thumbnail = typeof(Thumbnail.Prototype) & {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}

return Thumbnail.Interface
