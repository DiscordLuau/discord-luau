--[=[
	@class Classes.Video
	@__index Prototype

	Implementation of the Discord Video class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-video-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Video = {}

Video.Interface = {}
Video.Prototype = {}

--[=[
	@within Classes.Video
	@private

	Responsible for syncing data to this video object. This is typically called by the API when this object is
	created or updated.
]=]
function Video.Prototype.sync(self: Video, videoData: apiTypes.EmbedVideoObject)
	--[=[
		@prop url string
		@within Classes.Video
		The source URL of the video
	]=]
	self.url = videoData.url

	--[=[
		@prop proxyUrl string?
		@within Classes.Video
		A proxied URL of the video
	]=]
	self.proxyUrl = videoData.proxy_url

	--[=[
		@prop height number?
		@within Classes.Video
		Height of the video
	]=]
	self.height = videoData.height

	--[=[
		@prop width number?
		@within Classes.Video
		Width of the video
	]=]
	self.width = videoData.width
end

--[=[
	@within Classes.Video
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
