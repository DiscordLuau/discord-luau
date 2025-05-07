--[=[
	@class Builders.Attachment
	@__index Prototype
	Implementation of discords Attachment object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#attachment-object
]=]

local Attachment = {}

Attachment.Prototype = {}
Attachment.Interface = {}

--[=[
	@within Builders.Attachment

	The ID of the attachment to use.
]=]
function Attachment.Prototype.setId(self: Attachment, attachmentId: string): Attachment
	self.attachmentId = attachmentId

	return self
end

--[=[
	@within Builders.Attachment

	Responsible for building the Attachment JSON that can be parsed by the Discord API.
]=]
function Attachment.Prototype.build(self: Attachment): JSON
	return {
		id = self.attachmentId,
	}
end

--[=[
	@within Builders.Attachment
	Responsible for creating a new Attachment.
]=]
function Attachment.Interface.new(resource: {
	attachmentId: string,
}?): Attachment
	local self = setmetatable(
		{
			--[=[
				@within Builders.Attachment
				@prop attachmentId string?
				The ID of the attachment
			]=]
		} :: Attachment,
		{
			__index = Attachment.Prototype,
		}
	)

	if resource then
		if resource.attachmentId then
			self:setId(resource.attachmentId)
		end
	end

	return self
end

export type Attachment = typeof(Attachment.Prototype) & {
	attachmentId: string?,
}

export type JSON = typeof(Attachment.Prototype.build(nil :: any))

return Attachment.Interface
