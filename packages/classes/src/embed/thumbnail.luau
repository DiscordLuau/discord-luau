--[[
	Implementation of the Discord Thumbnail class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-thumbnail-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Thumbnail = {}

Thumbnail.Interface = {}
Thumbnail.Prototype = {}

function Thumbnail.Prototype.sync(self: Thumbnail, thumbnailData: apiTypes.EmbedThumbnailObject)
	self.url = thumbnailData.url
	self.proxyUrl = thumbnailData.proxy_url
	self.height = thumbnailData.height
	self.width = thumbnailData.width
end

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
