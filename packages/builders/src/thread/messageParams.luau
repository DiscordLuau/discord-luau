--[[
	Implementation of discords MessageParams object as a Luau builder.	

	https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel-forum-and-media-thread-message-params-object
]]

local embed = require("../embed/embed")
local allowedMention = require("../message/allowedMention")

local button = require("../message/components/button")
local textInput = require("../message/components/textInput")
local selectMenu = require("../message/components/selectMenu/selectMenu")
local actionRow = require("../message/components/actionRow")

local attachment = require("../attachment")

local MessageParams = {}

MessageParams.Prototype = {}
MessageParams.Interface = {}

--[[
	Sets the content of the message.
]]
function MessageParams.Prototype.setContent(self: MessageParams, content: string): MessageParams
	assert(#content < 2000, `MessageParams content must be less than 2000 characters.`)

	self.content = content

	return self
end

--[[
	Adds an embed to the message.
]]
function MessageParams.Prototype.addEmbed(self: MessageParams, embedData: embed.JSON): MessageParams
	local embeds = self.embeds or {}

	table.insert(embeds, embedData)

	self.embeds = embeds

	return self
end

--[[
	Sets the allowed mentions for the message.
]]
function MessageParams.Prototype.setAllowedMentions(self: MessageParams, mentions: allowedMention.JSON): MessageParams
	self.allowedMentions = mentions

	return self
end

--[[
	Adds a component to the message.
]]
function MessageParams.Prototype.addComponent(
	self: MessageParams,
	component: button.JSON | textInput.JSON | selectMenu.JSON | actionRow.JSON
): MessageParams
	local components = self.components or {}

	table.insert(components, component)

	self.components = components

	return self
end

--[[
	Adds a sticker ID to the message.
]]
function MessageParams.Prototype.addStickerId(self: MessageParams, stickerId: string): MessageParams
	local stickerIds = self.stickerIds or {}

	table.insert(stickerIds, stickerId)

	self.stickerIds = stickerIds

	return self
end

--[[
	Adds an attachment to the message.
]]
function MessageParams.Prototype.addAttachment(self: MessageParams, attachmentData: attachment.JSON): MessageParams
	local attachments = (self.components or {}) :: { attachment.JSON }

	table.insert(attachments, attachmentData)

	self.attachments = attachments

	return self
end

--[[
	Sets the flags for the message.
]]
function MessageParams.Prototype.setFlags(self: MessageParams, flags: number): MessageParams
	self.flags = flags

	return self
end

--[[
	Responsible for building the MessageParams JSON that can be parsed by the Discord API.
]]
function MessageParams.Prototype.build(self: MessageParams): JSON
	return {
		content = self.content,
		embeds = self.embeds :: { embed.JSON }?,
		allowed_mentions = self.allowedMentions,
		components = self.components :: { button.JSON | textInput.JSON | selectMenu.JSON | actionRow.JSON }?,
		sticker_ids = self.stickerIds :: { string }?,
		attachments = self.attachments :: { attachment.JSON }?,
		flags = self.flags,
	}
end

--[[
	Responsible for creating a new MessageParams.

	```lua

	```
]]
function MessageParams.Interface.new(resource: {
	content: string?,
	embeds: { embed.JSON }?,
	allowedMentions: allowedMention.JSON?,
	components: { button.JSON | textInput.JSON | selectMenu.JSON | actionRow.JSON }?,
	stickerIds: { string }?,
	attachments: { attachment.JSON }?,
	flags: number?,
}?): MessageParams
	local self = setmetatable(
		{
			embeds = {},
			components = {},
			stickerIds = {},
			attachments = {},
		} :: MessageParams,
		{
			__index = MessageParams.Prototype,
		}
	)

	if resource then
		if resource.content then
			self:setContent(resource.content)
		end

		if resource.allowedMentions then
			self:setAllowedMentions(resource.allowedMentions)
		end

		if resource.flags then
			self:setFlags(resource.flags)
		end

		if resource.embeds then
			for _, embed in resource.embeds do
				self:addEmbed(embed)
			end
		end

		if resource.components then
			for _, component in resource.components do
				self:addComponent(component)
			end
		end

		if resource.stickerIds then
			for _, stickerId in resource.stickerIds do
				self:addStickerId(stickerId)
			end
		end

		if resource.attachments then
			for _, attachment in resource.attachments do
				self:addAttachment(attachment)
			end
		end
	end

	return self
end

export type MessageParams = typeof(MessageParams.Prototype) & {
	content: string?,
	embeds: { embed.JSON },
	allowedMentions: allowedMention.JSON?,
	components: { button.JSON | textInput.JSON | selectMenu.JSON | actionRow.JSON },
	stickerIds: { string },
	attachments: { attachment.JSON },
	flags: number?,
}

export type JSON = typeof(MessageParams.Prototype.build(nil :: any))

return MessageParams.Interface
