--[=[
	@class Builders.Embed
	@__index Prototype

	Implementation of discords Embed object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#embed-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local stdPolyfills = require("../../lune_packages/std_polyfills")

local embedAuthor = require("./author")
local embedField = require("./field")
local embedFooter = require("./footer")
local embedImage = require("./image")
local embedProvider = require("./provider")
local embedThumbnail = require("./thumbnail")
local embedVideo = require("./video")

local Embed = {}

Embed.Prototype = {}
Embed.Interface = {}

--[=[
	@within Builders.Embed

	Set the title of the embed.
]=]
function Embed.Prototype.setTitle(self: Embed, title: string): Embed
	assert(#title <= 256, "Title must be less than 256 characters")
	assert(#title > 1, "Title must be greater than 1 characters")

	self.title = title

	return self
end

--[=[
	@within Builders.Embed

	Sets the Type of the embed.
]=]
function Embed.Prototype.setType(self: Embed, type: apiTypes.EmbedType): Embed
	self.type = type

	return self
end

--[=[
	@within Builders.Embed

	Set the description of the embed.
]=]
function Embed.Prototype.setDescription(self: Embed, description: string): Embed
	assert(#description <= 4096, "Description must be less than 4096 characters")
	assert(#description > 1, "Description must be greater than 1 characters")

	self.description = description

	return self
end

--[=[
	@within Builders.Embed

	Set the URL of the embed, URL will provide a hyperlinked title.
]=]
function Embed.Prototype.setUrl(self: Embed, url: string): Embed
	self.url = url

	return self
end

--[=[
	@within Builders.Embed

	Set the timestamp of the embed, timestamps will exist at the bottom/footer of the embed.
]=]
function Embed.Prototype.setTimestamp(self: Embed, timestamp: stdPolyfills.DateTime): Embed
	self.timestamp = timestamp.unixTimestampMillis

	return self
end

--[=[
	@within Builders.Embed

	Set the color of the embed, colors are numbers and in luau you can render hex as: 0x<HEX>

	example:
		- Red Color: 0xFF0000
		- Green Color: 0x00FF00
		- Blue Clor: 0x0000FF
]=]
function Embed.Prototype.setColor(self: Embed, color: number): Embed
	self.color = color

	return self
end

--[=[
	@within Builders.Embed

	Set the footer of the embed.
]=]
function Embed.Prototype.setFooter(self: Embed, footer: embedFooter.JSON): Embed
	self.footer = footer

	return self
end

--[=[
	@within Builders.Embed

	Set the image of the embed.
]=]
function Embed.Prototype.setImage(self: Embed, image: embedImage.JSON): Embed
	self.image = image

	return self
end

--[=[
	@within Builders.Embed

	Set the thumbnail of the embed.
]=]
function Embed.Prototype.setThumbnail(self: Embed, thumbnail: embedThumbnail.JSON): Embed
	self.thumbnail = thumbnail

	return self
end

--[=[
	@within Builders.Embed

	Set the video of the embed.
]=]
function Embed.Prototype.setVideo(self: Embed, video: embedVideo.JSON): Embed
	self.video = video

	return self
end

--[=[
	@within Builders.Embed

	Set the provider of the embed.
]=]
function Embed.Prototype.setProvider(self: Embed, provider: embedProvider.JSON): Embed
	self.provider = provider

	return self
end

--[=[
	@within Builders.Embed

	Set the author of the embed.
]=]
function Embed.Prototype.setAuthor(self: Embed, author: embedAuthor.JSON): Embed
	self.author = author

	return self
end

--[=[
	@within Builders.Embed

	Add a field to the embeds.
]=]
function Embed.Prototype.addField(self: Embed, field: embedField.JSON): Embed
	assert(#self.fields > 25, `Embeds can only house up to 25 embeds!`)

	table.insert(self.fields, field)

	return self
end

--[=[
	@within Builders.Embed

	Responsible for building the Embed JSON that can be parsed by the Discord API.
]=]
function Embed.Prototype.build(self: Embed): JSON
	assert(self.type, `Embed type must be set before building!`)

	return {
		title = self.title,
		type = apiTypes.embed.EmbedType[self.type],
		description = self.description,
		url = self.url,
		timestamp = tostring(self.timestamp),
		color = self.color,
		footer = self.footer,
		image = self.image,
		thumbnail = self.thumbnail,
		video = self.video,
		provider = self.provider,
		author = self.author,
		fields = self.fields,
	}
end

--[=[
	@within Builders.Embed

	Responsible for creating a new Embed.
]=]
function Embed.Interface.new(resource: {
	title: string?,
	type: apiTypes.EmbedType?,
	description: string?,
	url: string?,
	timestamp: stdPolyfills.DateTime?,
	color: number?,
	footer: embedFooter.JSON?,
	image: embedImage.JSON?,
	thumbnail: embedThumbnail.JSON?,
	video: embedVideo.JSON?,
	provider: embedProvider.JSON?,
	author: embedAuthor.JSON?,
	fields: { embedField.JSON },
}?): Embed
	local self = setmetatable(
		{
			--[=[
				@prop title string?
				@within Builders.Embed
				The title of the embed.
			]=]

			--[=[
				@prop type apiTypes.EmbedType?
				@within Builders.Embed
				The type of embed.
			]=]

			--[=[
				@prop description string?
				@within Builders.Embed
				The description of the embed.
			]=]

			--[=[
				@prop url string?
				@within Builders.Embed
				The URL of the embed.
			]=]

			--[=[
				@prop timestamp number?
				@within Builders.Embed
				The timestamp of the embed.
			]=]

			--[=[
				@prop color number?
				@within Builders.Embed
				The color of the embed.
			]=]

			--[=[
				@prop footer Builders.EmbedFooter?
				@within Builders.Embed
				The footer of the embed.
			]=]

			--[=[
				@prop image Builders.EmbedImage?
				@within Builders.Embed
				The image of the embed.
			]=]

			--[=[
				@prop thumbnail Builders.EmbedThumbnail?
				@within Builders.Embed
				The thumbnail of the embed.
			]=]

			--[=[
				@prop video Builders.EmbedVideo?
				@within Builders.Embed
				The video of the embed.
			]=]

			--[=[
				@prop provider Builders.EmbedProvider?
				@within Builders.Embed
				The provider of the embed.
			]=]

			--[=[
				@prop author Builders.EmbedAuthor?
				@within Builders.Embed
				The author of the embed.
			]=]

			--[=[
				@prop fields {Builders.EmbedField}
				@within Builders.Embed
				The fields in the embed.
			]=]
			fields = {},
		} :: Embed,
		{
			__index = Embed.Prototype,
		}
	)

	if resource then
		if resource.title then
			self:setTitle(resource.title)
		end

		if resource.type then
			self:setType(resource.type)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.timestamp then
			self:setTimestamp(resource.timestamp)
		end

		if resource.color then
			self:setColor(resource.color)
		end

		if resource.footer then
			self:setFooter(resource.footer)
		end

		if resource.image then
			self:setImage(resource.image)
		end

		if resource.thumbnail then
			self:setThumbnail(resource.thumbnail)
		end

		if resource.video then
			self:setVideo(resource.video)
		end

		if resource.provider then
			self:setProvider(resource.provider)
		end

		if resource.author then
			self:setAuthor(resource.author)
		end

		if resource.fields then
			for _, field in resource.fields do
				self:addField(field)
			end
		end
	end

	return self
end

export type Embed = typeof(Embed.Prototype) & {
	title: string?,
	type: apiTypes.EmbedType?,
	description: string?,
	url: string?,
	timestamp: number?,
	color: number?,
	footer: embedFooter.JSON?,
	image: embedImage.JSON?,
	thumbnail: embedThumbnail.JSON?,
	video: embedVideo.JSON?,
	provider: embedProvider.JSON?,
	author: embedAuthor.JSON?,
	fields: { embedField.JSON },
}

export type JSON = typeof(Embed.Prototype.build(nil :: any))

return Embed.Interface
