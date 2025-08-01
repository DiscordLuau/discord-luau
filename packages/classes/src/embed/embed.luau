--[=[
	@class Classes.Embed
	@__index Prototype

	Implementation of the Discord Embed class in Luau

	https://discord.com/developers/docs/resources/message#attachment-object
]=]

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

--[=[
	@within Classes.Embed
	@private

	Responsible for syncing data to this embed object. This is typically called by the API when this object is
	created or updated.
]=]
function Embed.Prototype.sync(self: Embed, embedData: apiTypes.EmbedObject)
	local fieldArray = {}

	for _, fieldData in next, embedData.fields or {} do
		table.insert(fieldArray, field.new(fieldData))
	end

	--[=[
		@prop title string?
		@within Classes.Embed

		The title of the embed
	]=]
	self.title = embedData.title

	--[=[
		@prop type apiTypes.EmbedType?
		@within Classes.Embed

		The type of embed (always "rich" for webhook embeds)
	]=]
	self.type = embedData.type :: any

	--[=[
		@prop description string?
		@within Classes.Embed

		The description of the embed
	]=]
	self.description = embedData.description

	--[=[
		@prop url string?
		@within Classes.Embed

		The URL of the embed
	]=]
	self.url = embedData.url

	--[=[
		@prop timestamp stdPolyfills.DateTime?
		@within Classes.Embed

		Timestamp of embed content
	]=]
	self.timestamp = embedData.timestamp and stdPolyfills.datetime.fromIsoDate(embedData.timestamp)

	--[=[
		@prop color number?
		@within Classes.Embed

		Color code of the embed
	]=]
	self.color = embedData.color

	--[=[
		@prop footer Classes.Footer?
		@within Classes.Embed

		Footer information for the embed
	]=]
	self.footer = embedData.footer and footer.new(embedData.footer)

	--[=[
		@prop image Classes.Image?
		@within Classes.Embed

		Image information for the embed
	]=]
	self.image = embedData.image and image.new(embedData.image)

	--[=[
		@prop thumbnail Classes.Thumbnail?
		@within Classes.Embed

		Thumbnail information for the embed
	]=]
	self.thumbnail = embedData.thumbnail and thumbnail.new(embedData.thumbnail)

	--[=[
		@prop video Classes.Video?
		@within Classes.Embed

		Video information for the embed
	]=]
	self.video = embedData.video and video.new(embedData.video)

	--[=[
		@prop provider Classes.Provider?
		@within Classes.Embed

		Provider information for the embed
	]=]
	self.provider = embedData.provider and provider.new(embedData.provider)

	--[=[
		@prop author Classes.Author?
		@within Classes.Embed

		Author information for the embed
	]=]
	self.author = embedData.author and author.new(embedData.author)

	--[=[
		@prop fields {Classes.Field}?
		@within Classes.Embed

		Array of embed field objects
	]=]
	self.fields = fieldArray
end

--[=[
	@within Classes.Embed
	@private

	Responsible for constructing this class.
]=]
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
