--[[
	Implementation of the Discord Embed class in Luau

	https://discord.com/developers/docs/resources/message#attachment-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")
local embedTypes = require("@api-types/embed")

local author = require("@classes/embed/author")
local footer = require("@classes/embed/footer")
local image = require("@classes/embed/image")
local thumbnail = require("@classes/embed/thumbnail")
local video = require("@classes/embed/video")
local provider = require("@classes/embed/provider")
local field = require("@classes/embed/field")

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
	self.timestamp = embedData.timestamp and datetime.fromIsoDate(embedData.timestamp)
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
	type: embedTypes.EmbedType?,
	description: string?,
	url: string?,
	timestamp: datetime.DateTime?,
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
