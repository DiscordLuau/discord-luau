--[[
	Implementation of discords Thumbnail object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#embed-object-embed-thumbnail-structure
]]

local Thumbnail = {}

Thumbnail.Prototype = {}
Thumbnail.Interface = {}

--[[
	Set the image url for this embed.
]]
function Thumbnail.Prototype.setUrl(self: Thumbnail, url: string, proxyUrl: string?): Thumbnail
	self.url = url
	self.proxyUrl = proxyUrl

	return self
end

--[[
	Set the image height for this embed.
]]
function Thumbnail.Prototype.setHeight(self: Thumbnail, height: number): Thumbnail
	self.height = height

	return self
end

--[[
	Set the image width for this embed.
]]
function Thumbnail.Prototype.setWidth(self: Thumbnail, width: number): Thumbnail
	self.width = width

	return self
end

--[[
	Responsible for building the Thumbnail JSON that can be parsed by the Discord API.
]]
function Thumbnail.Prototype.build(self: Thumbnail): JSON
	return {
		url = self.url,
		proxy_url = self.proxyUrl,
		height = self.height,
		width = self.width,
	}
end

--[[
	Responsible for creating a new Thumbnail.

	```lua
	
	```
]]
function Thumbnail.Interface.new(resource: {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}?): Thumbnail
	local self = setmetatable({} :: Thumbnail, {
		__index = Thumbnail.Prototype,
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

export type Thumbnail = typeof(Thumbnail.Prototype) & {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}

export type JSON = typeof(Thumbnail.Prototype.build({} :: any))

return Thumbnail.Interface
