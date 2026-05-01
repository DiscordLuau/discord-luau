--[=[
	@class Builders.Message.File
	@__index Prototype

	Implementation of Discord's File component as a Luau builder.
	The URL must be an attachment:// reference pointing to an uploaded file.

	https://discord.com/developers/docs/components/reference#file
]=]

--[=[
	@prop url string?
	@within Builders.Message.File
	The attachment URL (must use attachment://filename format).
]=]

--[=[
	@prop spoiler boolean?
	@within Builders.Message.File
	Whether the file is blurred as a spoiler.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local File = {}

File.Prototype = {}
File.Interface = {}

--[=[
	@within Builders.Message.File

	Sets the attachment URL. Must use the attachment://filename format.
]=]
function File.Prototype.setFile(self: File, url: string): File
	assert(url:sub(1, 13) == "attachment://", "file URL must use the attachment:// scheme")

	self.url = url

	return self
end

--[=[
	@within Builders.Message.File

	Sets whether the file is blurred as a spoiler.
]=]
function File.Prototype.setSpoiler(self: File, spoiler: boolean): File
	self.spoiler = spoiler

	return self
end

--[=[
	@within Builders.Message.File

	Responsible for building the File JSON that can be parsed by the Discord API.
]=]
function File.Prototype.build(self: File): JSON
	assert(self.url, "File.url is required")

	return {
		type = 13,
		file = { url = self.url },
		spoiler = self.spoiler,
	}
end

--[=[
	@within Builders.Message.File

	Responsible for creating a new File.
]=]
function File.Interface.new(resource: {
	url: string?,
	spoiler: boolean?,
}?): File
	local self = setmetatable(
		{
			url = nil,
			spoiler = nil,
		} :: File,
		{
			__index = File.Prototype,
		}
	)

	if resource then
		if resource.url then
			self:setFile(resource.url)
		end

		if resource.spoiler ~= nil then
			self:setSpoiler(resource.spoiler)
		end
	end

	return self
end

export type File = typeof(File.Prototype) & {
	url: string?,
	spoiler: boolean?,
}

export type JSON = apiTypes.FileComponentObject

return File.Interface
