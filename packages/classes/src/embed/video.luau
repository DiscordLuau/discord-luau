--[=[
	@class Classes.Embed.Video
	@__index Prototype

	Implementation of the Discord Video class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-video-structure
]=]

--[=[
	@prop url string
	@within Classes.Embed.Video
	The source URL of the video
]=]

--[=[
	@prop proxyUrl string?
	@within Classes.Embed.Video
	A proxied URL of the video
]=]

--[=[
	@prop height number?
	@within Classes.Embed.Video
	Height of the video
]=]

--[=[
	@prop width number?
	@within Classes.Embed.Video
	Width of the video
]=]

local apiTypes = require("../../luau_packages/api_types")

local Video = {}

Video.Interface = {}
Video.Prototype = {}

--[=[
	@within Classes.Embed.Video
	@private

	Responsible for syncing data to this video object. This is typically called by the API when this object is
	created or updated.
]=]
function Video.Prototype.sync(self: Video, videoData: apiTypes.EmbedVideoObject)
	self.url = videoData.url

	self.proxyUrl = videoData.proxy_url

	self.height = videoData.height

	self.width = videoData.width
end

--[=[
	@within Classes.Embed.Video
	@private

	Responsible for constructing this class.
]=]
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
