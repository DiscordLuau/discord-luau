local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local DiscordEmbedBuilder = require("DiscordEmbedBuilder")
local DiscordComponentTypes: string = require("../../Types/DiscordComponent")

--[=[
	@class DiscordMessageBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordMessageBuilder = {}

DiscordMessageBuilder.Interface = {}
DiscordMessageBuilder.Prototype = {}

DiscordMessageBuilder.Prototype.type = "DiscordMessageBuilder"

function DiscordMessageBuilder.Prototype.setContent(self: DiscordMessageBuilder, content: string)
	self.content = content

	return self
end

function DiscordMessageBuilder.Prototype.setNonce(self: DiscordMessageBuilder, nonce: string)
	self.nonce = nonce
	self.nonceEnforced = true

	return self
end

function DiscordMessageBuilder.Prototype.setTTSEnabled(self: DiscordMessageBuilder, ttsEnabled: boolean)
	self.ttsEnabled = ttsEnabled

	return self
end

function DiscordMessageBuilder.Prototype.addEmbed(self: DiscordMessageBuilder, embedBuilder: DiscordEmbedBuilder.DiscordEmbedBuilder)
	table.insert(self.embeds, embedBuilder)

	return self
end

function DiscordMessageBuilder.Prototype.addComponent(self: DiscordMessageBuilder, discordComponent: DiscordComponentTypes.DiscordComponent)
	table.insert(self.components, discordComponent)

	return self
end

function DiscordMessageBuilder.Prototype.addStickerId(self: DiscordMessageBuilder, stickerId: string)
	table.insert(self.stickers, stickerId)

	return self
end

function DiscordMessageBuilder.Prototype.setFlags(self: DiscordMessageBuilder, flags: number)
	self.flags = flags

	return self
end

--[=[
	@method toJSONObject
	@within DiscordMessageBuilder

	@return { ... }

	(yet-to-do!)

	```lua

	```
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
	@function new
	@within DiscordMessageBuilder

	@return DiscordMessageBuilder

	(yet-to-do!)

	```lua

	```
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