local construct = require("@util/construct")

local Resolvable = require("@network/resolvable")

local ResolvableType = require("@enums/resolvableType")

--[=[
	@class Builders.AttachmentBuilder

	AttachmentBuilder allows you to build attachments that you can send files through to the discord API.

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local AttachmentBuilder = DiscordLuau.AttachmentBuilder.new()
		:setName("Example.txt")
		:setData("My Text Document!")
	```
]=]
local AttachmentBuilder = {}

AttachmentBuilder.Interface = {}
AttachmentBuilder.Prototype = {}

AttachmentBuilder.Prototype.type = "AttachmentBuilder"

--[=[
	Set the name for this Attachment
	
	@method setName
	@param name string
	@within Builders.AttachmentBuilder
	@return Builders.AttachmentBuilder
]=]
function AttachmentBuilder.Prototype.setName(self: AttachmentBuilder, name: string)
	self.fileName = name

	return self
end

--[=[
	Set the description for this Attachment
	
	@method setDescription
	@param description string
	@within Builders.AttachmentBuilder
	@return Builders.AttachmentBuilder
]=]
function AttachmentBuilder.Prototype.setDescription(self: AttachmentBuilder, description: string)
	self.fileDescription = description

	return self
end

--[=[
	Set the data for this Attachment
	
	@method setData
	@param data string
	@within Builders.AttachmentBuilder
	@return Builders.AttachmentBuilder
]=]
function AttachmentBuilder.Prototype.setData(self: AttachmentBuilder, data: string)
	self.fileData = data

	return self
end

--[=[
	Converts the message to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.MessageBuilder
	@return Network.Resolvable
]=]
function AttachmentBuilder.Prototype.toPayloadObject(self: AttachmentBuilder): Resolvable.Resolvable
	return Resolvable.new(ResolvableType.FORMDATA, {
		fileName = self.fileName,
		fileDescription = self.fileDescription,
		fileData = self.fileDescription,
	})
end

--[=[
	
	Creates a new instance of AttachmentBuilder with the specified intents.
	
	@function new
	@param intentList { string } -- A list of intents to include.
	@within Builders.AttachmentBuilder
	@return Builders.AttachmentBuilder -- A new instance of AttachmentBuilder.
]=]
function AttachmentBuilder.Interface.new()
	return (construct({}, AttachmentBuilder.Prototype) :: unknown) :: AttachmentBuilder
end

export type AttachmentBuilder = typeof(AttachmentBuilder.Prototype) & {
	fileName: string?,
	fileDescription: string?,
	fileData: string?,
}

return AttachmentBuilder.Interface
