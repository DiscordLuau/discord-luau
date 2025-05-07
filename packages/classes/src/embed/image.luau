--[=[
	@class Classes.Image
	@__index Prototype

	Implementation of the Discord Image class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-image-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Image = {}

Image.Interface = {}
Image.Prototype = {}

--[=[
	@within Classes.Image
	@private

	Responsible for syncing data to this image object. This is typically called by the API when this object is
	created or updated.
]=]
function Image.Prototype.sync(self: Image, imageData: apiTypes.EmbedImageObject)
	--[=[
		@prop url string
		@within Classes.Image

		The source URL of the image. Only supports HTTP(S).
	]=]
	self.url = imageData.url

	--[=[
		@prop proxyUrl string?
		@within Classes.Image

		A proxied URL of the image. This is used to prevent malicious images from being loaded directly.
	]=]
	self.proxyUrl = imageData.proxy_url

	--[=[
		@prop height number?
		@within Classes.Image

		The height of the image in pixels.
	]=]
	self.height = imageData.height

	--[=[
		@prop width number?
		@within Classes.Image

		The width of the image in pixels.
	]=]
	self.width = imageData.width
end

--[=[
	@within Classes.Image
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
