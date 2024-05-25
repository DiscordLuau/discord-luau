local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local EmbedBuilder = require("EmbedBuilder")

local ActionRowBuilder = require("../Builders/Interface/ActionRowBuilder")
local ButtonBuilder = require("../Builders/Interface/ButtonBuilder")
local SelectionBuilder = require("../Builders/Interface/SelectionBuilder")
local TextInputBuilder = require("../Builders/Interface/TextInputBuilder")

--[=[
	@class Builders.MessageBuilder

	MessageBuilder is used to construct a message that can be sent to a Discord channel, including content, embeds, components, and stickers.

	Usage:
	```lua
	local message = MessageBuilder.new()
		:setContent("Hello, world!")
		:addEmbed(EmbedBuilder.new():setTitle("Embed Title"))
		:addComponent(ButtonBuilder.new("button_id"))
		:addStickerId("sticker_id")
		:setTTSEnabled(true)
	```
]=]
local MessageBuilder = {}

MessageBuilder.Interface = {}
MessageBuilder.Prototype = {}

MessageBuilder.Prototype.type = "MessageBuilder"

--[=[
	Sets the content of the message.
	
	@method setContent
	@param content string -- The content of the message.
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- Returns the MessageBuilder instance for method chaining.
]=]
function MessageBuilder.Prototype.setContent(self: MessageBuilder, content: string)
	self.content = content

	return self
end

--[=[
	Sets the nonce of the message.
	
	@method setNonce
	@param nonce string -- The nonce of the message.
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- Returns the MessageBuilder instance for method chaining.
]=]
function MessageBuilder.Prototype.setNonce(self: MessageBuilder, nonce: string)
	self.nonce = nonce
	self.nonceEnforced = true

	return self
end

--[=[
	Sets whether text-to-speech (TTS) is enabled for the message.
	
	@method setTTSEnabled
	@param ttsEnabled boolean -- Whether TTS is enabled.
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- Returns the MessageBuilder instance for method chaining.
]=]
function MessageBuilder.Prototype.setTTSEnabled(self: MessageBuilder, ttsEnabled: boolean)
	self.ttsEnabled = ttsEnabled

	return self
end

--[=[
	Adds an embed to the message.
	
	@method addEmbed
	@param embedBuilder EmbedBuilder -- The embed to add.
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- Returns the MessageBuilder instance for method chaining.
]=]
function MessageBuilder.Prototype.addEmbed(self: MessageBuilder, embedBuilder: EmbedBuilder.EmbedBuilder)
	table.insert(self.embeds, embedBuilder)

	return self
end

--[=[
	Adds a component to the message.
	
	@method addComponent
	@param discordComponent InterfaceBuilder -- The component to add.
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- Returns the MessageBuilder instance for method chaining.
]=]
function MessageBuilder.Prototype.addComponent(self: MessageBuilder, discordComponent: InterfaceBuidler)
	table.insert(self.components, discordComponent)

	return self
end

--[=[
	Adds a sticker ID to the message.
	
	@method addStickerId
	@param stickerId string -- The sticker ID to add.
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- Returns the MessageBuilder instance for method chaining.
]=]
function MessageBuilder.Prototype.addStickerId(self: MessageBuilder, stickerId: string)
	table.insert(self.stickers, stickerId)

	return self
end

--[=[
	Sets the flags for the message.
	
	@method setFlags
	@param flags number -- The flags for the message.
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- Returns the MessageBuilder instance for method chaining.
]=]
function MessageBuilder.Prototype.setFlags(self: MessageBuilder, flags: number)
	self.flags = flags

	return self
end

--[=[
	Converts the message to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within Builders.MessageBuilder
	@return table -- The JSON representation of the message.
]=]
function MessageBuilder.Prototype.toJSONObject(self: MessageBuilder)
	local components = {}
	local embeds = {}

	for _, component in self.components do
		table.insert(components, (component :: any):toJSONObject())
	end

	for _, embed in self.embeds do
		table.insert(embeds, embed:toJSONObject())
	end

	return {
		content = self.content or nil,
		nonce = self.nonce or nil,
		tts = self.ttsEnabled or false,
		sticker_ids = self.stickers,
		flags = self.flags or nil, --fixme: should use a bitfield.
		enforce_nonce = self.nonceEnforced or false,

		embeds = embeds,
		components = components,
	}
end

--[=[
	Creates a new instance of MessageBuilder.
	
	@function new
	@within Builders.MessageBuilder
	@return Builders.MessageBuilder -- A new instance of MessageBuilder.
]=]
function MessageBuilder.Interface.new(): MessageBuilder
	return Construct({
		embeds = {},
		components = {},
		stickers = {},
	}, MessageBuilder.Prototype) :: any
end

type InterfaceBuidler =
	ActionRowBuilder.ActionRowBuilder
	| ButtonBuilder.ButtonBuilder
	| SelectionBuilder.SelectionBuilder
	| TextInputBuilder.TextInputBuilder

export type MessageBuilder = typeof(MessageBuilder.Prototype) & {
	content: string,

	nonce: string,
	nonceEnforced: boolean,

	ttsEnabled: boolean,

	embeds: { EmbedBuilder.EmbedBuilder },
	components: { InterfaceBuidler },

	stickers: { string },

	flags: number,
}

return MessageBuilder.Interface
