local Enumeration = require("../Dependencies/Enumeration")

local DiscordEmbed = {}

DiscordEmbed.Type = "DiscordEmbed"

DiscordEmbed.Internal = {}
DiscordEmbed.Interface = {}
DiscordEmbed.Prototype = {
	Internal = DiscordEmbed.Internal,
}

DiscordEmbed.Interface.Type = Enumeration.new({
	Rich = "rich",
	Image = "image",
	Video = "video",
	GifVideo = "gifv",
	Article = "article",
	Link = "link"
})

function DiscordEmbed.Prototype:SetTitle(titleMessage)
	self.EmbedTitle = titleMessage

	return self
end

function DiscordEmbed.Prototype:SetType(embedType)
	assert(DiscordEmbed.Interface.Type:Is(embedType), `Expected 'embedType' to of class 'EmbedType'`)

	self.EmbedType = embedType

	return self
end

function DiscordEmbed.Prototype:SetDescription(description)
	self.EmbedDescription = description

	return self
end

function DiscordEmbed.Prototype:SetUrl(url)
	self.EmbedUrl = url

	return self
end

function DiscordEmbed.Prototype:SetTimestamp(isoTimestamp)
	self.ISOTimestamp = isoTimestamp

	return self
end

function DiscordEmbed.Prototype:SetColor(colorCode)
	self.EmbedColor = colorCode

	return self
end

function DiscordEmbed.Prototype:SetFooterText(footerText)
	self.EmbedFooterText = footerText

	return self
end

function DiscordEmbed.Prototype:SetFooterIcon(imageUrl, proxyImageUrl)
	self.EmbedFooterIcon = imageUrl
	self.EmbedProxyFooterIcon = proxyImageUrl

	return self
end

function DiscordEmbed.Prototype:SetImage(imageUrl, proxyImageUrl)
	self.EmbedImage = imageUrl
	self.EmbedProxyImage = proxyImageUrl

	return self
end

function DiscordEmbed.Prototype:SetImageSize(sizeX, sizeY)
	self.EmbedImageSize = { X = sizeX, Y = sizeY }

	return self
end

function DiscordEmbed.Prototype:SetThumbnailImage(imageUrl, proxyImageUrl)
	self.EmbedThumbnailImage = imageUrl
	self.EmbedThumbnailProxyImage = proxyImageUrl

	return self
end

function DiscordEmbed.Prototype:SetThumbnailImageSize(sizeX, sizeY)
	self.EmbedThumbnailImageSize = { X = sizeX, Y = sizeY }

	return self
end

function DiscordEmbed.Prototype:SetVideo(videoUrl, proxyVideoUrl)
	self.EmbedVideo = videoUrl
	self.EmbedProxyVideo = proxyVideoUrl

	return self
end

function DiscordEmbed.Prototype:SetVideoSize(sizeX, sizeY)
	self.EmbedVideoSize = { X = sizeX, Y = sizeY }

	return self
end

function DiscordEmbed.Prototype:SetProvider(name, url)
	self.EmbedProviderName = name
	self.EmbedProviderUrl = url

	return self
end

function DiscordEmbed.Prototype:SetAuthorName(authorName, authorUrl)
	self.EmbedAuthorName = authorName
	self.EmbedAuthorUrl = authorUrl

	return self
end

function DiscordEmbed.Prototype:SetAuthorImage(imageUrl, proxyImageUrl)
	self.EmbedAuthorImage = imageUrl
	self.EmbedAuthorProxyImage = proxyImageUrl

	return self
end

function DiscordEmbed.Prototype:CreateEmbedField(fieldName, fieldValue, isInline)
	self.EmbedFields[fieldName] = {
		value = fieldValue,
		inline = isInline
	}

	return self
end

function DiscordEmbed.Prototype:RemoveEmbedField(fieldName)
	self.EmbedFields[fieldName] = nil

	return self
end

function DiscordEmbed.Prototype:ToJSONObject()
	local embedFields = {}

	for fieldName, fieldData in self.EmbedFields do
		table.insert(embedFields, {
			name = fieldName,
			value = fieldData.value,
			inline = fieldData.inline
		})
	end

	return {
		fields = embedFields,

		title = self.EmbedTitle,
		type = self.EmbedType or "rich",
		description = self.EmbedDescription,
		url = self.EmbedUrl,
		timestamp = self.ISOTimestamp,
		color = self.EmbedColor,

		footer = {
			text = self.EmbedFooterText,
			icon_url = self.EmbedFooterIcon,
			proxy_icon_url = self.EmbedProxyFooterIcon
		},
		image = {
			url = self.EmbedImage,
			proxy_url = self.EmbedProxyImage,
			height = (self.EmbedImageSize and self.EmbedImageSize.Y) or nil,
			width = (self.EmbedImageSize and self.EmbedImageSize.X) or nil
		},
		thumbnail = {
			url = self.EmbedThumbnailImage,
			proxy_url = self.EmbedThumbnailProxyImage,
			height = (self.EmbedThumbnailImageSize and self.EmbedThumbnailImageSize.Y) or nil,
			width = (self.EmbedThumbnailImageSize and self.EmbedThumbnailImageSize.X) or nil
		},
		video = {
			url = self.EmbedVideo,
			proxy_url = self.EmbedProxyVideo,
			height = (self.EmbedVideoSize and self.EmbedVideoSize.Y) or nil,
			width = (self.EmbedVideoSize and self.EmbedVideoSize.X) or nil
		},
		provider = {
			name = self.EmbedProviderName,
			url = self.EmbedProviderUrl
		},
		author = {
			name = self.EmbedAuthorName,
			url = self.EmbedAuthorUrl,
			icon_url = self.EmbedAuthorImage,
			proxy_icon_url = self.EmbedAuthorProxyImage
		}
	}
end

function DiscordEmbed.Prototype:ToString()
	local safeDiscordToken = self.DiscordToken

	safeDiscordToken = string.sub(safeDiscordToken, 1, 40)
	safeDiscordToken ..= ` ...`

	return `{DiscordEmbed.Type}<"{safeDiscordToken}">`
end

function DiscordEmbed.Interface.new()
	return setmetatable({
		EmbedFields = {}
	}, {
		__index = DiscordEmbed.Prototype,
		__type = DiscordEmbed.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordEmbed.Interface
