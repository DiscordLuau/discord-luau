--[=[
	@class Builders.Message.FileUpload
	@__index Prototype

	Implementation of Discord's File Upload component as a Luau builder.
	Modal-only component for uploading files.

	https://docs.discord.com/developers/components/reference#file-upload
]=]

--[=[
	@prop customId string?
	@within Builders.Message.FileUpload
	Developer-defined identifier; 1-100 characters.
]=]

--[=[
	@prop accept string?
	@within Builders.Message.FileUpload
	Allowed file types; max 200 characters.
]=]

--[=[
	@prop maxSize number?
	@within Builders.Message.FileUpload
	Maximum file size in bytes; max 512 MB.
]=]

--[=[
	@prop required boolean?
	@within Builders.Message.FileUpload
	Whether required to answer in modal (defaults to true).
]=]

local apiTypes = require("../../../luau_packages/api_types")

local FileUpload = {}

FileUpload.Prototype = {}
FileUpload.Interface = {}

--[=[
	@within Builders.Message.FileUpload

	Sets the developer-defined identifier. 1-100 characters.
]=]
function FileUpload.Prototype.setCustomId(self: FileUpload, customId: string): FileUpload
	assert(#customId >= 1, "customId must be at least 1 character")
	assert(#customId <= 100, "customId must be at most 100 characters")

	self.customId = customId

	return self
end

--[=[
	@within Builders.Message.FileUpload

	Sets the allowed file types. Max 200 characters.
]=]
function FileUpload.Prototype.setAccept(self: FileUpload, accept: string): FileUpload
	assert(#accept <= 200, "accept must be at most 200 characters")

	self.accept = accept

	return self
end

--[=[
	@within Builders.Message.FileUpload

	Sets the maximum file size in bytes.
]=]
function FileUpload.Prototype.setMaxSize(self: FileUpload, maxSize: number): FileUpload
	self.maxSize = maxSize

	return self
end

--[=[
	@within Builders.Message.FileUpload

	Sets whether this component is required in a modal.
]=]
function FileUpload.Prototype.setRequired(self: FileUpload, required: boolean): FileUpload
	self.required = required

	return self
end

--[=[
	@within Builders.Message.FileUpload

	Responsible for building the FileUpload JSON that can be parsed by the Discord API.
]=]
function FileUpload.Prototype.build(self: FileUpload): JSON
	assert(self.customId, "FileUpload.customId is required")

	return {
		type = 19,
		custom_id = self.customId,
		accept = self.accept,
		max_size = self.maxSize,
		required = self.required,
	}
end

--[=[
	@within Builders.Message.FileUpload

	Responsible for creating a new FileUpload.
]=]
function FileUpload.Interface.new(resource: {
	customId: string?,
	accept: string?,
	maxSize: number?,
	required: boolean?,
}?): FileUpload
	local self = setmetatable(
		{
			customId = nil,
			accept = nil,
			maxSize = nil,
			required = nil,
		} :: FileUpload,
		{
			__index = FileUpload.Prototype,
		}
	)

	if resource then
		if resource.customId then
			self:setCustomId(resource.customId)
		end

		if resource.accept then
			self:setAccept(resource.accept)
		end

		if resource.maxSize then
			self:setMaxSize(resource.maxSize)
		end

		if resource.required ~= nil then
			self:setRequired(resource.required)
		end
	end

	return self
end

export type FileUpload = typeof(FileUpload.Prototype) & {
	customId: string?,
	accept: string?,
	maxSize: number?,
	required: boolean?,
}

export type JSON = apiTypes.FileUploadComponentObject

return FileUpload.Interface
