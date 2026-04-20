--[=[
	@class Classes.Attachment
	@__index Prototype

	Implementation of the Discord Attachment class in Luau

	https://discord.com/developers/docs/resources/message#attachment-object
]=]

--[=[
	@prop id string
	@within Classes.Attachment

	The unique identifier for this attachment
]=]

--[=[
	@prop filename string
	@within Classes.Attachment

	Name of the attached file
]=]

--[=[
	@prop title string?
	@within Classes.Attachment

	Title of the attached file (if provided)
]=]

--[=[
	@prop description string?
	@within Classes.Attachment

	Description of the attached file (if provided)
]=]

--[=[
	@prop contentType string?
	@within Classes.Attachment

	The media type/MIME type of the file
]=]

--[=[
	@prop size number
	@within Classes.Attachment

	Size of the file in bytes
]=]

--[=[
	@prop url string
	@within Classes.Attachment

	Source URL of the file
]=]

--[=[
	@prop proxyUrl string
	@within Classes.Attachment

	A proxied URL of the file
]=]

--[=[
	@prop height number?
	@within Classes.Attachment

	Height of the file if it is an image
]=]

--[=[
	@prop width number?
	@within Classes.Attachment

	Width of the file if it is an image
]=]

--[=[
	@prop ephemeral boolean?
	@within Classes.Attachment

	Whether this attachment is ephemeral
]=]

--[=[
	@prop durationSeconds number?
	@within Classes.Attachment

	Duration of the audio file in seconds
]=]

--[=[
	@prop waveform string?
	@within Classes.Attachment

	Base64 encoded waveform data for audio files
]=]

--[=[
	@prop flags Classes.AttachmentBitflag?
	@within Classes.Attachment

	Attachment flags that describe extra features or properties
]=]

local apiTypes = require("../luau_packages/api_types")

local attachmentBitflag = require("./bitflags/attachment")

local Attachment = {}

Attachment.Interface = {}
Attachment.Prototype = {}

--[=[
	@within Classes.Attachment
	@private

	Responsible for syncing data to this attachment object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.Attachment
	@private

	Responsible for constructing this class.
]=]
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
