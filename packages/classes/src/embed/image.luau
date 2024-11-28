--[[
	Implementation of the Discord Image class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-image-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Image = {}

Image.Interface = {}
Image.Prototype = {}

function Image.Prototype.sync(self: Image, imageData: apiTypes.EmbedImageObject)
	self.url = imageData.url
	self.proxyUrl = imageData.proxy_url
	self.height = imageData.height
	self.width = imageData.width
end

function Image.Interface.new(imageData: apiTypes.EmbedImageObject): Image
	local self = setmetatable({} :: Image, { __index = Image.Prototype })

	self:sync(imageData)

	return self
end

export type Image = typeof(Image.Prototype) & {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}

return Image.Interface
