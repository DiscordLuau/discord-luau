--[[
	Implementation of the Discord Video class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-video-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Video = {}

Video.Interface = {}
Video.Prototype = {}

function Video.Prototype.sync(self: Video, videoData: apiTypes.EmbedVideoObject)
	self.url = videoData.url
	self.proxyUrl = videoData.proxy_url
	self.height = videoData.height
	self.width = videoData.width
end

function Video.Interface.new(videoData: apiTypes.EmbedVideoObject): Video
	local self = setmetatable({} :: Video, { __index = Video.Prototype })

	self:sync(videoData)

	return self
end

export type Video = typeof(Video.Prototype) & {
	url: string,
	proxyUrl: string?,
	height: number?,
	width: number?,
}

return Video.Interface
