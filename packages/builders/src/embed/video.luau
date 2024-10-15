--[[
	Implementation of discords Video object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#embed-object-embed-video-structure
]]

local Video = {}

Video.Prototype = {}
Video.Interface = {}

--[[
	Set the image url for this embed.
]]
function Video.Prototype.setUrl(self: Video, url: string, proxyUrl: string?): Video
	self.url = url
	self.proxyUrl = proxyUrl

	return self
end

--[[
	Set the image height for this embed.
]]
function Video.Prototype.setHeight(self: Video, height: number): Video
	self.height = height

	return self
end

--[[
	Set the image width for this embed.
]]
function Video.Prototype.setWidth(self: Video, width: number): Video
	self.width = width

	return self
end

--[[
	Responsible for building the Video JSON that can be parsed by the Discord API.
]]
function Video.Prototype.build(self: Video): JSON
	return {
		url = self.url,
		proxy_url = self.proxyUrl,
		height = self.height,
		width = self.width,
	}
end

--[[
	Responsible for creating a new Video.

	```lua
	
	```
]]
function Video.Interface.new(resource: {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}?): Video
	local self = setmetatable({} :: Video, {
		__index = Video.Prototype,
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

export type Video = typeof(Video.Prototype) & {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}

export type JSON = typeof(Video.Prototype.build({} :: any))

return Video.Interface
