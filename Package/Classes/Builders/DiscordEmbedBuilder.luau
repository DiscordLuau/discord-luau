local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local datetime = require("@lune/datetime")

--[=[
	@class DiscordEmbedBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordEmbedBuilder = {}

DiscordEmbedBuilder.Interface = {}
DiscordEmbedBuilder.Prototype = {}

DiscordEmbedBuilder.Prototype.type = "DiscordEmbedBuilder"

--[=[
	@prop Type { ... }
	@within DiscordEmbedBuilder 
]=]
DiscordEmbedBuilder.Interface.Type = Enumerate.new({
	Rich = "rich",
	Image = "image",
	Video = "video",
	Gif = "gifv",
	Article = "article",
	Link = "link"
})

--[=[
	@method setTitle
	@within DiscordEmbedBuilder

	@param title string

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setTitle(self: DiscordEmbedBuilder, title: string)
	self.title = title

	return self
end

--[=[
	@method setType
	@within DiscordEmbedBuilder

	@param type string

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setType(self: DiscordEmbedBuilder, type: string)
	self.type = type

	return self
end

--[=[
	@method setDescription
	@within DiscordEmbedBuilder

	@param description string

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setDescription(self: DiscordEmbedBuilder, description: string)
	self.description = description

	return self
end

--[=[
	@method setUrl
	@within DiscordEmbedBuilder

	@param url string

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setUrl(self: DiscordEmbedBuilder, url: string)
	self.url = url

	return self
end

--[=[
	@method setTimestamp
	@within DiscordEmbedBuilder

	@param epoch number

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setTimestamp(self: DiscordEmbedBuilder, epoch: number)
	self.timestamp = datetime.fromUniversalTime(epoch :: any):toIsoDate()

	return self
end

--[=[
	@method setColor
	@within DiscordEmbedBuilder

	@param colorHex number

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setColor(self: DiscordEmbedBuilder, colorHex: number)
	self.color = colorHex

	return self
end

--[=[
	@method setFooter
	@within DiscordEmbedBuilder

	@param footerSettings { text: string, icon: string }

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setFooter(self: DiscordEmbedBuilder, footerSettings: {
	text: string,
	icon: string
})
	self.footer = footerSettings

	return self
end

--[=[
	@method setFooter
	@within DiscordEmbedBuilder

	@param imageSettings { imageUrl: string, height: number, width: number }

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setImage(self: DiscordEmbedBuilder, imageSettings: {
	imageUrl: string,
	height: number,
	width: number
})
	self.image = imageSettings

	return self
end

--[=[
	@method setThumbnail
	@within DiscordEmbedBuilder

	@param thumbnailSettings { thumbnailUrl: string, height: number, width: number }

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setThumbnail(self: DiscordEmbedBuilder, thumbnailSettings: {
	thumbnailUrl: string,
	height: number,
	width: number
})
	self.thumbnail = thumbnailSettings

	return self
end

--[=[
	@method setVideo
	@within DiscordEmbedBuilder

	@param videoSettings { videoUrl: string, height: number, width: number }

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setVideo(self: DiscordEmbedBuilder, videoSettings: {
	videoUrl: string,
	height: number,
	width: number
})
	self.video = videoSettings

	return self
end

--[=[
	@method setProvider
	@within DiscordEmbedBuilder

	@param providerSettings { name: string, url: string }

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setProvider(self: DiscordEmbedBuilder, providerSettings: {
	name: string,
	url: string
})
	self.provider = providerSettings

	return self
end

--[=[
	@method setAuthor
	@within DiscordEmbedBuilder

	@param authorSettings { name: string, url: string, iconUrl: string }

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.setAuthor(self: DiscordEmbedBuilder, authorSettings: {
	iconUrl: string,
	name: string,
	url: string,
})
	self.author = authorSettings

	return self
end

--[=[
	@method addField
	@within DiscordEmbedBuilder

	@param fieldSettings { name: string, value: string, footer: string, author: string }

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.addField(self: DiscordEmbedBuilder, fieldSettings: {
	name: string,
	value: string,
	inline: boolean?
})
	table.insert(self.fields, fieldSettings)

	return self
end

--[=[
	@method toJSONObject
	@within DiscordEmbedBuilder

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Prototype.toJSONObject(self: DiscordEmbedBuilder)
	local fields = {}

	for _, fieldObject in self.fields do
		table.insert(fields, {
			name = fieldObject.name,
			value = fieldObject.value,
			inline = fieldObject.inline
		})
	end

	return {
		fields = #fields ~= 0 and fields or nil,

		title = self.title,
		type = self.type,
		description = self.description,
		url = self.url,
		timestamp = self.timestamp,
		color = self.color,

		footer = self.footer and {
			text = self.footer.text,
			icon_url = self.footer.icon
		} or nil,
		image = self.image and {
			url = self.image.imageUrl,
			height = self.image.height,
			width = self.image.width
		} or nil,
		thumbnail = self.thumbnail and {
			url = self.thumbnail.thumbnailUrl,
			height = self.thumbnail.height,
			width = self.thumbnail.width,
		} or nil,
		video = self.video and {
			url = self.video.videoUrl,
			height = self.video.height,
			width = self.video.width,
		} or nil,
		provider = self.provider and {
			name = self.provider.name,
			url = self.provider.url,
		} or nil,
		author = self.author and {
			name = self.author.name,
			url = self.author.url,
			icon_url = self.author.iconUrl
		} or nil
	}
end

--[=[
	@function new
	@within DiscordEmbedBuilder

	@return DiscordEmbedBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbedBuilder.Interface.new()
	return Construct({
		fields = {}
	}, DiscordEmbedBuilder.Prototype)
end

export type DiscordEmbedBuilder = typeof(DiscordEmbedBuilder.Prototype) & {
	fields: {
		{
			name: string,
			value: string,
			inline: boolean?
		}
	},
	title: string?,
	type: string?,
	description: string?,
	url: string?,
	timestamp: string?,
	color: number?,
	footer: {
		text: string,
		icon: string
	}?,
	image: {
		imageUrl: string,
		height: number,
		width: number
	}?,
	thumbnail: {
		thumbnailUrl: string,
		height: number,
		width: number
	}?,
	video: {
		videoUrl: string,
		height: number,
		width: number
	}?,
	provider: {
		name: string,
		url: string
	}?,
	author: {
		iconUrl: string,
		name: string,
		url: string,
	}?
}

return DiscordEmbedBuilder.Interface