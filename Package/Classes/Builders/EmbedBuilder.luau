local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local ResolvableType = require("../../Enums/ResolveableType")
local Resolvable = require("../Network/Resolvable")

local Datetime = require("../../Std/Datetime")

--[=[
	@class Builders.EmbedBuilder

	EmbedBuilder is used to construct an embed object for a Discord message.

	Usage:
	```lua
	local embed = EmbedBuilder.new()
		:setTitle("Embed Title")
		:setDescription("This is an embed description.")
		:setColor(0x00FF00)
		:addField({name = "Field 1", value = "Value 1", inline = true})
	```
]=]
local EmbedBuilder = {}

EmbedBuilder.Interface = {}
EmbedBuilder.Prototype = {}

EmbedBuilder.Prototype.type = "EmbedBuilder"

--[=[
	@prop Type table
	@within Builders.EmbedBuilder

	An enumeration of embed types.

	- Rich: "rich"
	- Image: "image"
	- Video: "video"
	- Gif: "gifv"
	- Article: "article"
	- Link: "link"
]=]
EmbedBuilder.Interface.Type = Enumerate.new({
	Rich = "rich",
	Image = "image",
	Video = "video",
	Gif = "gifv",
	Article = "article",
	Link = "link",
})

--[=[
	Sets the title of the embed.
	
	@method setTitle
	@param title string -- The title of the embed.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setTitle(self: EmbedBuilder, title: string)
	self.title = title

	return self
end

--[=[
	Sets the type of the embed.
	
	@method setType
	@param type string -- The type of the embed.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setType(self: EmbedBuilder, type: string)
	self.type = type

	return self
end

--[=[
	Sets the description of the embed.
	
	@method setDescription
	@param description string -- The description of the embed.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setDescription(self: EmbedBuilder, description: string)
	self.description = description

	return self
end

--[=[
	Sets the URL of the embed.
	
	@method setUrl
	@param url string -- The URL of the embed.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setUrl(self: EmbedBuilder, url: string)
	self.url = url

	return self
end

--[=[
	Sets the timestamp of the embed.
	
	@method setTimestamp
	@param epoch number -- The timestamp of the embed in epoch time.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setTimestamp(self: EmbedBuilder, epoch: number)
	self.timestamp = Datetime.fromUniversalTime(epoch :: any):toIsoDate()

	return self
end

type HexLike = string | number
type RGB = { number } | { r: number, g: number, b: number }
--[=[
	Sets the color of the embed.
	
	@method setColor
	@param colorHex HexLike | RGB -- The color of the embed in as a hex or a RGB.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setColor(self: EmbedBuilder, color: HexLike | RGB)
	local colorHex: number

	if typeof(color) == "number" then
		colorHex = color
	end

	if typeof(color) == "string" then
		local HEX_PAT = "#(.%x*)"
		colorHex = tonumber(string.match(color, HEX_PAT), 16) or error("Invalid hex string provided")
	end

	if typeof(color) == "table" then
		-- FIXME: Maybe don't use any here
		local anyColor = color :: any
		local rgbColor = {
			r = anyColor.r or anyColor[1],
			g = anyColor.g or anyColor[2],
			b = anyColor.b or anyColor[3],
		}

		if rgbColor.r and rgbColor.g and rgbColor.b then
			local function toHex(num: number): string
				local hex = string.format("%x", num)
				if #hex == 1 then
					hex = "0" .. hex
				end

				return hex
			end

			return EmbedBuilder.Prototype.setColor(
				self,
				"#" .. toHex(rgbColor.r) .. toHex(rgbColor.g) .. toHex(rgbColor.b)
			)
		else
			error("Not all required RGB color components provided")
		end
	end

	self.color = colorHex

	return self
end

--[=[
	Sets the footer of the embed.
	
	@method setFooter
	@param footerSettings { text: string, icon: string } -- The settings for the footer.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setFooter(
	self: EmbedBuilder,
	footerSettings: {
		text: string,
		icon: string,
	}
)
	self.footer = footerSettings

	return self
end

--[=[
	Sets the image of the embed.
	
	@method setImage
	@param imageSettings { imageUrl: string, height: number, width: number } -- The settings for the image.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setImage(
	self: EmbedBuilder,
	imageSettings: {
		imageUrl: string,
		height: number,
		width: number,
	}
)
	self.image = imageSettings

	return self
end

--[=[
	Sets the thumbnail of the embed.
	
	@method setThumbnail
	@param thumbnailSettings { thumbnailUrl: string, height: number, width: number } -- The settings for the thumbnail.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setThumbnail(
	self: EmbedBuilder,
	thumbnailSettings: {
		thumbnailUrl: string,
		height: number,
		width: number,
	}
)
	self.thumbnail = thumbnailSettings

	return self
end

--[=[
	Sets the video of the embed.
	
	@method setVideo
	@param videoSettings { videoUrl: string, height: number, width: number } -- The settings for the video.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setVideo(
	self: EmbedBuilder,
	videoSettings: {
		videoUrl: string,
		height: number,
		width: number,
	}
)
	self.video = videoSettings

	return self
end

--[=[
	Sets the provider of the embed.
	
	@method setProvider
	@param providerSettings { name: string, url: string } -- The settings for the provider.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setProvider(
	self: EmbedBuilder,
	providerSettings: {
		name: string,
		url: string,
	}
)
	self.provider = providerSettings

	return self
end

--[=[
	Sets the author of the embed.
	
	@method setAuthor
	@param authorSettings { name: string, url: string, iconUrl: string } -- The settings for the author.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.setAuthor(
	self: EmbedBuilder,
	authorSettings: {
		iconUrl: string,
		name: string,
		url: string,
	}
)
	self.author = authorSettings

	return self
end

--[=[
	Adds a field to the embed.
	
	@method addField
	@param fieldSettings { name: string, value: string, inline: boolean? } -- The settings for the field.
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- Returns the EmbedBuilder instance for method chaining.
]=]
function EmbedBuilder.Prototype.addField(
	self: EmbedBuilder,
	fieldSettings: {
		name: string,
		value: string,
		inline: boolean?,
	}
)
	table.insert(self.fields, fieldSettings)

	return self
end

--[=[
	Converts the embed to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.EmbedBuilder
	@return Network.Resolvable
]=]
function EmbedBuilder.Prototype.toPayloadObject(self: EmbedBuilder)
	local fields = {}

	for _, fieldObject in self.fields do
		table.insert(fields, {
			name = fieldObject.name,
			value = fieldObject.value,
			inline = fieldObject.inline,
		})
	end

	return Resolvable.new(ResolvableType.JSON, {
		fields = #fields ~= 0 and fields or nil,

		title = self.title,
		type = self.type,
		description = self.description,
		url = self.url,
		timestamp = self.timestamp,
		color = self.color,

		footer = self.footer and {
			text = self.footer.text,
			icon_url = self.footer.icon,
		} or nil,
		image = self.image and {
			url = self.image.imageUrl,
			height = self.image.height,
			width = self.image.width,
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
			icon_url = self.author.iconUrl,
		} or nil,
	})
end

--[=[
	Creates a new instance of EmbedBuilder.
	
	@function new
	@within Builders.EmbedBuilder
	@return Builders.EmbedBuilder -- A new instance of EmbedBuilder.
]=]
function EmbedBuilder.Interface.new()
	return Construct({
		fields = {},
	}, EmbedBuilder.Prototype)
end

export type EmbedBuilder = typeof(EmbedBuilder.Prototype) & {
	fields: {
		{
			name: string,
			value: string,
			inline: boolean?,
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
		icon: string,
	}?,
	image: {
		imageUrl: string,
		height: number,
		width: number,
	}?,
	thumbnail: {
		thumbnailUrl: string,
		height: number,
		width: number,
	}?,
	video: {
		videoUrl: string,
		height: number,
		width: number,
	}?,
	provider: {
		name: string,
		url: string,
	}?,
	author: {
		iconUrl: string,
		name: string,
		url: string,
	}?,
}

return EmbedBuilder.Interface
