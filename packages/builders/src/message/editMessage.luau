--[=[
	@class Builders.EditMessage
	@__index Prototype

	Implementation of Discord's Edit Message params as a Luau builder.

	https://discord.com/developers/docs/resources/message#edit-message-jsonform-params
]=]

local embed = require("../embed/embed")
local allowedMention = require("./allowedMention")

local EditMessage = {}

EditMessage.Prototype = {}
EditMessage.Interface = {}

function EditMessage.Prototype.setContent(self: EditMessage, content: string?): EditMessage
	if content ~= nil then
		assert(#content <= 2000, "Content must be at most 2000 characters")
	end
	self.content = content
	return self
end

function EditMessage.Prototype.addEmbed(self: EditMessage, embedData: embed.JSON): EditMessage
	local embeds = self.embeds or {}
	assert(#embeds < 10, "Messages cannot have more than 10 embeds")
	table.insert(embeds, embedData)
	self.embeds = embeds
	return self
end

function EditMessage.Prototype.setEmbeds(self: EditMessage, embeds: { embed.JSON }?): EditMessage
	self.embeds = embeds
	return self
end

function EditMessage.Prototype.setFlags(self: EditMessage, flags: number): EditMessage
	self.flags = flags
	return self
end

function EditMessage.Prototype.setAllowedMentions(self: EditMessage, mentions: allowedMention.JSON): EditMessage
	self.allowedMentions = mentions
	return self
end

function EditMessage.Prototype.addComponent(self: EditMessage, component: { [string]: any }): EditMessage
	local components = self.components or {}
	table.insert(components, component)
	self.components = components
	return self
end

function EditMessage.Prototype.setComponents(self: EditMessage, components: { { [string]: any } }?): EditMessage
	self.components = components
	return self
end

function EditMessage.Prototype.addAttachment(
	self: EditMessage,
	id: number,
	filename: string,
	description: string?
): EditMessage
	local attachments = self.attachments or {}
	table.insert(attachments, { id = id, filename = filename, description = description })
	self.attachments = attachments
	return self
end

function EditMessage.Prototype.build(self: EditMessage): JSON
	return {
		content = self.content,
		embeds = self.embeds,
		flags = self.flags,
		allowed_mentions = self.allowedMentions,
		components = self.components,
		attachments = self.attachments,
	}
end

function EditMessage.Interface.new(resource: {
	content: string?,
	embeds: { embed.JSON }?,
	flags: number?,
	allowedMentions: allowedMention.JSON?,
	components: { { [string]: any } }?,
	attachments: { { id: number, filename: string, description: string? } }?,
}?): EditMessage
	local self = setmetatable({} :: EditMessage, { __index = EditMessage.Prototype })

	if resource then
		if resource.content ~= nil then
			self:setContent(resource.content)
		end
		if resource.embeds then
			for _, e in resource.embeds do
				self:addEmbed(e)
			end
		end
		if resource.flags then
			self:setFlags(resource.flags)
		end
		if resource.allowedMentions then
			self:setAllowedMentions(resource.allowedMentions)
		end
		if resource.components then
			self:setComponents(resource.components)
		end
		if resource.attachments then
			for _, a in resource.attachments do
				self:addAttachment(a.id, a.filename, a.description)
			end
		end
	end

	return self
end

export type EditMessage = typeof(EditMessage.Prototype) & {
	content: string?,
	embeds: { embed.JSON }?,
	flags: number?,
	allowedMentions: allowedMention.JSON?,
	components: { { [string]: any } }?,
	attachments: { { id: number, filename: string, description: string? } }?,
}

export type JSON = typeof(EditMessage.Prototype.build(nil :: any))

return EditMessage.Interface
