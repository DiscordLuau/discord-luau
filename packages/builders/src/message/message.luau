--[[
	Implementation of discords Message object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#message-object
]]

local embed = require("../embed/embed")
local allowedMention = require("./allowedMention")
local reference = require("./reference")

local poll = require("./poll/poll")

local button = require("./components/button")
local textInput = require("./components/textInput")
local selectMenu = require("./components/selectMenu/selectMenu")
local actionRow = require("./components/actionRow")

local attachment = require("../attachment")

local Message = {}

Message.Prototype = {}
Message.Interface = {}

--[[
	Sets the content of the message.
]]
function Message.Prototype.setContent(self: Message, content: string): Message
	assert(#content < 2000, `Message content must be less than 2000 characters.`)

	self.content = content

	return self
end

--[[
	Sets the nonce of the message.
]]
function Message.Prototype.setNonce(self: Message, nonce: string): Message
	assert(#nonce < 25, `Message nonse must be less than 25 characters.`)

	self.nonce = nonce

	return self
end

--[[
	Sets whether the message is text-to-speech.
]]
function Message.Prototype.setTTS(self: Message, tts: boolean): Message
	self.tts = tts

	return self
end

--[[
	Adds an embed to the message.
]]
function Message.Prototype.addEmbed(self: Message, embedData: embed.JSON): Message
	local embeds = self.embeds or {}

	table.insert(embeds, embedData)

	self.embeds = embeds

	return self
end

--[[
	Sets the allowed mentions for the message.
]]
function Message.Prototype.setAllowedMentions(self: Message, mentions: allowedMention.JSON): Message
	self.allowedMentions = mentions

	return self
end

--[[
	Sets the message reference.
]]
function Message.Prototype.setMessageReference(self: Message, ref: reference.JSON): Message
	self.messageReference = ref

	return self
end

--[[
	Adds a component to the message.
]]
function Message.Prototype.addComponent(
	self: Message,
	component: button.JSON | textInput.JSON | selectMenu.JSON | actionRow.JSON
): Message
	local components = self.components or {}

	table.insert(components, component)

	self.components = components

	return self
end

--[[
	Adds a sticker ID to the message.
]]
function Message.Prototype.addStickerId(self: Message, stickerId: string): Message
	local stickerIds = self.stickerIds or {}

	table.insert(stickerIds, stickerId)

	self.stickerIds = stickerIds

	return self
end

--[[
	Adds an attachment to the message.
]]
function Message.Prototype.addAttachment(self: Message, attachmentData: attachment.JSON): Message
	local attachments = (self.components or {}) :: { attachment.JSON }

	table.insert(attachments, attachmentData)

	self.attachments = attachments

	return self
end

--[[
	Sets the flags for the message.
]]
function Message.Prototype.setFlags(self: Message, flags: number): Message
	self.flags = flags

	return self
end

--[[
	If true and nonce is present, it will be checked for uniqueness in the past few minutes. If another message
	was created by the same author with the same nonce, that message will be returned and no new message will 
	be created.
]]
function Message.Prototype.setEnforceNonce(self: Message, enforceNonce: boolean): Message
	self.enforceNonce = enforceNonce

	return self
end

--[[
	Sets the poll for the message.
]]
function Message.Prototype.setPoll(self: Message, poll: poll.JSON): Message
	self.poll = poll

	return self
end

--[[
	Responsible for building the Message JSON that can be parsed by the Discord API.
]]
function Message.Prototype.build(self: Message): JSON
	return {
		content = self.content,
		nonce = self.nonce,
		tts = self.tts,
		embeds = #self.embeds > 0 and self.embeds or nil,
		allowed_mentions = self.allowedMentions,
		message_reference = self.messageReference,
		components = #self.components > 0 and self.components or nil,
		sticker_ids = #self.stickerIds > 0 and self.stickerIds or nil,
		attachments = #self.attachments > 0 and self.attachments or nil,
		flags = self.flags,
		enforce_nonce = self.enforceNonce,
		poll = self.poll,
	}
end

--[[
	Responsible for creating a new Message.

	```lua

	```
]]
function Message.Interface.new(resource: {
	content: string?,
	nonce: string?,
	tts: boolean?,
	embeds: { embed.JSON }?,
	allowedMentions: allowedMention.JSON?,
	messageReference: reference.JSON?,
	components: { button.JSON | textInput.JSON | selectMenu.JSON | actionRow.JSON }?,
	stickerIds: { string }?,
	attachments: { attachment.JSON }?,
	flags: number?,
	enforceNonce: boolean?,
	poll: poll.JSON?,
}?): Message
	local self = setmetatable(
		{
			embeds = {},
			components = {},
			stickerIds = {},
			attachments = {},
		} :: Message,
		{
			__index = Message.Prototype,
		}
	)

	if resource then
		if resource.content then
			self:setContent(resource.content)
		end

		if resource.nonce then
			self:setNonce(resource.nonce)
		end

		if resource.tts then
			self:setTTS(resource.tts)
		end

		if resource.allowedMentions then
			self:setAllowedMentions(resource.allowedMentions)
		end

		if resource.messageReference then
			self:setMessageReference(resource.messageReference)
		end

		if resource.flags then
			self:setFlags(resource.flags)
		end

		if resource.enforceNonce then
			self:setEnforceNonce(resource.enforceNonce)
		end

		if resource.poll then
			self:setPoll(resource.poll)
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

export type Message = typeof(Message.Prototype) & {
	content: string?,
	nonce: string?,
	tts: boolean?,
	embeds: { embed.JSON },
	allowedMentions: allowedMention.JSON?,
	messageReference: reference.JSON?,
	components: { button.JSON | textInput.JSON | selectMenu.JSON | actionRow.JSON },
	stickerIds: { string },
	-- files[n]
	-- payloadJson
	attachments: { attachment.JSON },
	flags: number?,
	enforceNonce: boolean?,
	poll: poll.JSON?,
}

export type JSON = typeof(Message.Prototype.build(nil :: any))

return Message.Interface
