--[=[
	@class Classes.Embed.Image
	@__index Prototype

	Implementation of the Discord Image class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-image-structure
]=]

--[=[
	@prop url string
	@within Classes.Embed.Image

	The source URL of the image. Only supports HTTP(S).
]=]

--[=[
	@prop proxyUrl string?
	@within Classes.Embed.Image

	A proxied URL of the image. This is used to prevent malicious images from being loaded directly.
]=]

--[=[
	@prop height number?
	@within Classes.Embed.Image

	The height of the image in pixels.
]=]

--[=[
	@prop width number?
	@within Classes.Embed.Image

	The width of the image in pixels.
]=]

local apiTypes = require("../../luau_packages/api_types")

local Image = {}

Image.Interface = {}
Image.Prototype = {}

--[=[
	@within Classes.Embed.Image
	@private

	Responsible for syncing data to this image object. This is typically called by the API when this object is
	created or updated.
]=]
function Image.Prototype.sync(self: Image, imageData: apiTypes.EmbedImageObject)
	self.url = imageData.url

	self.proxyUrl = imageData.proxy_url

	self.height = imageData.height

	self.width = imageData.width
end

--[=[
	@within Classes.Embed.Image
	@private

	Responsible for constructing this class.
]=]
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
