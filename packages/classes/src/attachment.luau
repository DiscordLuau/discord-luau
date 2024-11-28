--[[
	Implementation of the Discord Attachment class in Luau

	https://discord.com/developers/docs/resources/message#attachment-object
]]

local apiTypes = require("../lune_packages/api_types")

local attachmentBitflag = require("./bitflags/attachment")

local Attachment = {}

Attachment.Interface = {}
Attachment.Prototype = {}

function Attachment.Prototype.sync(self: Attachment, attachmentData: apiTypes.AttachmentObject)
	self.id = attachmentData.id
	self.filename = attachmentData.filename
	self.title = attachmentData.title
	self.description = attachmentData.description
	self.contentType = attachmentData.content_type
	self.size = attachmentData.size
	self.url = attachmentData.url
	self.proxyUrl = attachmentData.proxy_url
	self.height = attachmentData.height
	self.width = attachmentData.width
	self.ephemeral = attachmentData.ephemeral
	self.durationSeconds = attachmentData.duration_secs
	self.waveform = attachmentData.waveform
	self.flags = attachmentData.flags and attachmentBitflag.new(attachmentData.flags)
end

function Attachment.Interface.new(attachmentData: apiTypes.AttachmentObject): Attachment
	local self = setmetatable({} :: Attachment, { __index = Attachment.Prototype })

	self:sync(attachmentData)

	return self
end

export type Attachment = typeof(Attachment.Prototype) & {
	id: apiTypes.Snowflake,
	filename: string,
	title: string?,
	description: string?,
	contentType: string?,
	size: number,
	url: string,
	proxyUrl: string,
	height: number?,
	width: number?,
	ephemeral: boolean?,
	durationSeconds: number?,
	waveform: string?,
	flags: attachmentBitflag.AttachmentBitflag?,
}

return Attachment.Interface
