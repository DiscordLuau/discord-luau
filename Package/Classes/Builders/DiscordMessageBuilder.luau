local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local DiscordEmbedBuilder = require("DiscordEmbedBuilder")
local DiscordComponentTypes = require("../../Types/DiscordComponent")

--[=[
	@class DiscordMessageBuilder

	DiscordMessageBuilder is used to construct a message that can be sent to a Discord channel, including content, embeds, components, and stickers.

	Usage:
	```lua
	local message = DiscordMessageBuilder.new()
		:setContent("Hello, world!")
		:addEmbed(DiscordEmbedBuilder.new():setTitle("Embed Title"))
		:addComponent(ButtonBuilder.new("button_id"))
		:addStickerId("sticker_id")
		:setTTSEnabled(true)
	```
]=]
local DiscordMessageBuilder = {}

DiscordMessageBuilder.Interface = {}
DiscordMessageBuilder.Prototype = {}

DiscordMessageBuilder.Prototype.type = "DiscordMessageBuilder"

--[=[
	Sets the content of the message.
	
	@method setContent
	@param content string -- The content of the message.
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- Returns the DiscordMessageBuilder instance for method chaining.
]=]
function DiscordMessageBuilder.Prototype.setContent(self: DiscordMessageBuilder, content: string)
	self.content = content

	return self
end

--[=[
	Sets the nonce of the message.
	
	@method setNonce
	@param nonce string -- The nonce of the message.
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- Returns the DiscordMessageBuilder instance for method chaining.
]=]
function DiscordMessageBuilder.Prototype.setNonce(self: DiscordMessageBuilder, nonce: string)
	self.nonce = nonce
	self.nonceEnforced = true

	return self
end

--[=[
	Sets whether text-to-speech (TTS) is enabled for the message.
	
	@method setTTSEnabled
	@param ttsEnabled boolean -- Whether TTS is enabled.
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- Returns the DiscordMessageBuilder instance for method chaining.
]=]
function DiscordMessageBuilder.Prototype.setTTSEnabled(self: DiscordMessageBuilder, ttsEnabled: boolean)
	self.ttsEnabled = ttsEnabled

	return self
end

--[=[
	Adds an embed to the message.
	
	@method addEmbed
	@param embedBuilder DiscordEmbedBuilder -- The embed to add.
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- Returns the DiscordMessageBuilder instance for method chaining.
]=]
function DiscordMessageBuilder.Prototype.addEmbed(self: DiscordMessageBuilder, embedBuilder: DiscordEmbedBuilder.DiscordEmbedBuilder)
	table.insert(self.embeds, embedBuilder)

	return self
end

--[=[
	Adds a component to the message.
	
	@method addComponent
	@param discordComponent DiscordComponentTypes.DiscordComponent -- The component to add.
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- Returns the DiscordMessageBuilder instance for method chaining.
]=]
function DiscordMessageBuilder.Prototype.addComponent(self: DiscordMessageBuilder, discordComponent: DiscordComponentTypes.DiscordComponent)
	table.insert(self.components, discordComponent)

	return self
end

--[=[
	Adds a sticker ID to the message.
	
	@method addStickerId
	@param stickerId string -- The sticker ID to add.
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- Returns the DiscordMessageBuilder instance for method chaining.
]=]
function DiscordMessageBuilder.Prototype.addStickerId(self: DiscordMessageBuilder, stickerId: string)
	table.insert(self.stickers, stickerId)

	return self
end

--[=[
	Sets the flags for the message.
	
	@method setFlags
	@param flags number -- The flags for the message.
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- Returns the DiscordMessageBuilder instance for method chaining.
]=]
function DiscordMessageBuilder.Prototype.setFlags(self: DiscordMessageBuilder, flags: number)
	self.flags = flags

	return self
end

--[=[
	Converts the message to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within DiscordMessageBuilder
	@return table -- The JSON representation of the message.
]=]
function DiscordMessageBuilder.Prototype.toJSONObject(self: DiscordMessageBuilder)
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
	Creates a new instance of DiscordMessageBuilder.
	
	@function new
	@within DiscordMessageBuilder
	@return DiscordMessageBuilder -- A new instance of DiscordMessageBuilder.
]=]
function DiscordMessageBuilder.Interface.new(): DiscordMessageBuilder
	return Construct({
		embeds = {},
		components = {},
		stickers = {}
	}, DiscordMessageBuilder.Prototype) :: any
end

export type DiscordMessageBuilder = typeof(DiscordMessageBuilder.Prototype) & {
	content: string,

	nonce: string,
	nonceEnforced: boolean,

	ttsEnabled: boolean,

	embeds: { DiscordEmbedBuilder.DiscordEmbedBuilder },
	components: { DiscordComponentTypes.DiscordComponent },

	stickers: { string },

	flags: number
}

return DiscordMessageBuilder.Interface
