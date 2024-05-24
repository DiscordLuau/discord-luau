local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local datetime = require("@lune/datetime")

--[=[
	@class DiscordEmbedBuilder

	DiscordEmbedBuilder is used to construct an embed object for a Discord message.

	Usage:
	```lua
	local embed = DiscordEmbedBuilder.new()
		:setTitle("Embed Title")
		:setDescription("This is an embed description.")
		:setColor(0x00FF00)
		:addField({name = "Field 1", value = "Value 1", inline = true})
	```
]=]
local DiscordEmbedBuilder = {}

DiscordEmbedBuilder.Interface = {}
DiscordEmbedBuilder.Prototype = {}

DiscordEmbedBuilder.Prototype.type = "DiscordEmbedBuilder"

--[=[
	@prop Type table
	@within DiscordEmbedBuilder

	An enumeration of embed types.

	- Rich: "rich"
	- Image: "image"
	- Video: "video"
	- Gif: "gifv"
	- Article: "article"
	- Link: "link"
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
	Sets the title of the embed.
	
	@method setTitle
	@param title string -- The title of the embed.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setTitle(self: DiscordEmbedBuilder, title: string)
	self.title = title

	return self
end

--[=[
	Sets the type of the embed.
	
	@method setType
	@param type string -- The type of the embed.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setType(self: DiscordEmbedBuilder, type: string)
	self.type = type

	return self
end

--[=[
	Sets the description of the embed.
	
	@method setDescription
	@param description string -- The description of the embed.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setDescription(self: DiscordEmbedBuilder, description: string)
	self.description = description

	return self
end

--[=[
	Sets the URL of the embed.
	
	@method setUrl
	@param url string -- The URL of the embed.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setUrl(self: DiscordEmbedBuilder, url: string)
	self.url = url

	return self
end

--[=[
	Sets the timestamp of the embed.
	
	@method setTimestamp
	@param epoch number -- The timestamp of the embed in epoch time.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setTimestamp(self: DiscordEmbedBuilder, epoch: number)
	self.timestamp = datetime.fromUniversalTime(epoch :: any):toIsoDate()

	return self
end

--[=[
	Sets the color of the embed.
	
	@method setColor
	@param colorHex number -- The color of the embed in hexadecimal.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setColor(self: DiscordEmbedBuilder, colorHex: number)
	self.color = colorHex

	return self
end

--[=[
	Sets the footer of the embed.
	
	@method setFooter
	@param footerSettings { text: string, icon: string } -- The settings for the footer.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setFooter(self: DiscordEmbedBuilder, footerSettings: {
	text: string,
	icon: string
})
	self.footer = footerSettings

	return self
end

--[=[
	Sets the image of the embed.
	
	@method setImage
	@param imageSettings { imageUrl: string, height: number, width: number } -- The settings for the image.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
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
	Sets the thumbnail of the embed.
	
	@method setThumbnail
	@param thumbnailSettings { thumbnailUrl: string, height: number, width: number } -- The settings for the thumbnail.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
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
	Sets the video of the embed.
	
	@method setVideo
	@param videoSettings { videoUrl: string, height: number, width: number } -- The settings for the video.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
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
	Sets the provider of the embed.
	
	@method setProvider
	@param providerSettings { name: string, url: string } -- The settings for the provider.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
]=]
function DiscordEmbedBuilder.Prototype.setProvider(self: DiscordEmbedBuilder, providerSettings: {
	name: string,
	url: string
})
	self.provider = providerSettings

	return self
end

--[=[
	Sets the author of the embed.
	
	@method setAuthor
	@param authorSettings { name: string, url: string, iconUrl: string } -- The settings for the author.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
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
	Adds a field to the embed.
	
	@method addField
	@param fieldSettings { name: string, value: string, inline: boolean? } -- The settings for the field.
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- Returns the DiscordEmbedBuilder instance for method chaining.
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
	Converts the embed to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within DiscordEmbedBuilder
	@return table -- The JSON representation of the embed.
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
	Creates a new instance of DiscordEmbedBuilder.
	
	@function new
	@within DiscordEmbedBuilder
	@return DiscordEmbedBuilder -- A new instance of DiscordEmbedBuilder.
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
