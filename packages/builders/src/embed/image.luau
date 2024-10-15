--[[
	Implementation of discords Image object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#embed-object-embed-image-structure
]]

local Image = {}

Image.Prototype = {}
Image.Interface = {}

--[[
	Set the image url for this embed.
]]
function Image.Prototype.setUrl(self: Image, url: string, proxyUrl: string?): Image
	self.url = url
	self.proxyUrl = proxyUrl

	return self
end

--[[
	Set the image height for this embed.
]]
function Image.Prototype.setHeight(self: Image, height: number): Image
	self.height = height

	return self
end

--[[
	Set the image width for this embed.
]]
function Image.Prototype.setWidth(self: Image, width: number): Image
	self.width = width

	return self
end

--[[
	Responsible for building the function Image.Prototype.build(self: Image): JSON
 JSON that can be parsed by the Discord API.
]]
function Image.Prototype.build(self: Image): JSON
	return {
		url = self.url,
		proxy_url = self.proxyUrl,
		height = self.height,
		width = self.width,
	}
end

--[[
	Responsible for creating a new Image.

	```lua
	
	```
]]
function Image.Interface.new(resource: {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}?): Image
	local self = setmetatable({} :: Image, {
		__index = Image.Prototype,
	})

	if resource then
		if resource.url then
			self:setUrl(resource.url, resource.proxyUrl)
		end

		if resource.height then
			self:setHeight(resource.height)
		end

		if resource.width then
			self:setWidth(resource.width)
		end
	end

	return self
end

export type Image = typeof(Image.Prototype) & {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}

export type JSON = typeof(Image.Prototype.build({} :: any))

return Image.Interface
