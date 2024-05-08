local Construct = require("../Utils/Construct")
local Enumerate = require("../Utils/Enumerate")

local datetime = require("@lune/datetime")

--[=[
	@class DiscordEmbed

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordEmbed = {}

DiscordEmbed.Interface = {}
DiscordEmbed.Prototype = {}

DiscordEmbed.Prototype.type = "DiscordEmbed"

--[=[
	@prop Type { ... }
	@within DiscordEmbed 
]=]
DiscordEmbed.Interface.Type = Enumerate.new({
	Rich = "rich",
	Image = "image",
	Video = "video",
	Gif = "gifv",
	Article = "article",
	Link = "link"
})

--[=[
	@method setTitle
	@within DiscordEmbed

	@param title string

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setTitle(self: DiscordEmbed, title: string)
	self.title = title

	return self
end

--[=[
	@method setType
	@within DiscordEmbed

	@param type string

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setType(self: DiscordEmbed, type: string)
	self.type = type

	return self
end

--[=[
	@method setDescription
	@within DiscordEmbed

	@param description string

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setDescription(self: DiscordEmbed, description: string)
	self.description = description

	return self
end

--[=[
	@method setUrl
	@within DiscordEmbed

	@param url string

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setUrl(self: DiscordEmbed, url: string)
	self.url = url

	return self
end

--[=[
	@method setTimestamp
	@within DiscordEmbed

	@param epoch number

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setTimestamp(self: DiscordEmbed, epoch: number)
	self.timestamp = datetime.fromUniversalTime(epoch :: any):toIsoDate()

	return self
end

--[=[
	@method setColor
	@within DiscordEmbed

	@param colorHex number

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setColor(self: DiscordEmbed, colorHex: number)
	self.color = colorHex

	return self
end

--[=[
	@method setFooter
	@within DiscordEmbed

	@param footerSettings { text: string, icon: string }

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setFooter(self: DiscordEmbed, footerSettings: {
	text: string,
	icon: string
})
	self.footer = footerSettings

	return self
end

--[=[
	@method setFooter
	@within DiscordEmbed

	@param imageSettings { imageUrl: string, height: number, width: number }

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setImage(self: DiscordEmbed, imageSettings: {
	imageUrl: string,
	height: number,
	width: number
})
	self.image = imageSettings

	return self
end

--[=[
	@method setThumbnail
	@within DiscordEmbed

	@param thumbnailSettings { thumbnailUrl: string, height: number, width: number }

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setThumbnail(self: DiscordEmbed, thumbnailSettings: {
	thumbnailUrl: string,
	height: number,
	width: number
})
	self.thumbnail = thumbnailSettings

	return self
end

--[=[
	@method setVideo
	@within DiscordEmbed

	@param videoSettings { videoUrl: string, height: number, width: number }

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setVideo(self: DiscordEmbed, videoSettings: {
	videoUrl: string,
	height: number,
	width: number
})
	self.video = videoSettings

	return self
end

--[=[
	@method setProvider
	@within DiscordEmbed

	@param providerSettings { name: string, url: string }

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setProvider(self: DiscordEmbed, providerSettings: {
	name: string,
	url: string
})
	self.provider = providerSettings

	return self
end

--[=[
	@method setAuthor
	@within DiscordEmbed

	@param authorSettings { name: string, url: string, iconUrl: string }

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.setAuthor(self: DiscordEmbed, authorSettings: {
	iconUrl: string,
	name: string,
	url: string,
})
	self.author = authorSettings

	return self
end

--[=[
	@method addField
	@within DiscordEmbed

	@param fieldSettings { name: string, value: string, footer: string, author: string }

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.addField(self: DiscordEmbed, fieldSettings: {
	name: string,
	value: string,
	footer: string,
	author: string
})
	table.insert(self.fields, fieldSettings)

	return self
end

--[=[
	@method toJSONObject
	@within DiscordEmbed

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Prototype.toJSONObject(self: DiscordEmbed)
	local fields = {}

	for _, fieldObject in self.fields do
		table.insert(fields, {
			name = fieldObject.name,
			value = fieldObject.value,
			footer = fieldObject.footer,
			author = fieldObject.author
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
	@within DiscordEmbed

	@return DiscordEmbed

	(yet-to-do!)

	```lua

	```
]=]
function DiscordEmbed.Interface.new()
	return Construct({
		fields = {}
	}, DiscordEmbed.Prototype)
end

export type DiscordEmbed = typeof(DiscordEmbed.Prototype) & {
	fields: {
		{
			name: string,
			value: string,
			footer: string,
			author: string
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

return DiscordEmbed.Interface