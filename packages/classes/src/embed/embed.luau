--[[
	Implementation of the Discord Embed class in Luau

	https://discord.com/developers/docs/resources/message#attachment-object
]]

local apiTypes = require("../../lune_packages/api_types")
local stdPolyfills = require("../../lune_packages/std_polyfills")

local author = require("./author")
local footer = require("./footer")
local image = require("./image")
local thumbnail = require("./thumbnail")
local video = require("./video")
local provider = require("./provider")
local field = require("./field")

local Embed = {}

Embed.Interface = {}
Embed.Prototype = {}

function Embed.Prototype.sync(self: Embed, embedData: apiTypes.EmbedObject)
	local fieldArray = {}

	for _, fieldData in next, embedData.fields or {} do
		table.insert(fieldArray, field.new(fieldData))
	end

	self.fields = fieldArray

	self.title = embedData.title
	self.type = embedData.type :: any
	self.description = embedData.description
	self.url = embedData.url
	self.timestamp = embedData.timestamp and stdPolyfills.datetime.fromIsoDate(embedData.timestamp)
	self.color = embedData.color
	self.footer = embedData.footer and footer.new(embedData.footer)
	self.image = embedData.image and image.new(embedData.image)
	self.thumbnail = embedData.thumbnail and thumbnail.new(embedData.thumbnail)
	self.video = embedData.video and video.new(embedData.video)
	self.provider = embedData.provider and provider.new(embedData.provider)
	self.author = embedData.author and author.new(embedData.author)
end

function Embed.Interface.new(embedData: apiTypes.EmbedObject): Embed
	local self = setmetatable({} :: Embed, { __index = Embed.Prototype })

	self:sync(embedData)

	return self
end

export type Embed = typeof(Embed.Prototype) & {
	title: string?,
	type: apiTypes.EmbedType?,
	description: string?,
	url: string?,
	timestamp: stdPolyfills.DateTime?,
	color: number?,
	footer: footer.Footer?,
	image: image.Image?,
	thumbnail: thumbnail.Thumbnail?,
	video: video.Video?,
	provider: provider.Provider?,
	author: author.Author?,
	fields: { field.Field }?,
}

return Embed.Interface
