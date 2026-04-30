--[=[
	@class Builders.Message.Button
	@__index Prototype

	Implementation of discords Button object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#buttons
]=]

--[=[
	@prop style apiTypes.ButtonStyle
	@within Builders.Message.Button
	The style of the button that determines its appearance and behavior.
]=]

--[=[
	@prop label string?
	@within Builders.Message.Button
	The text that appears on the button.
]=]

--[=[
	@prop emoji Builders.Emoji?
	@within Builders.Message.Button
	The emoji that appears on the button.
]=]

--[=[
	@prop customId string?
	@within Builders.Message.Button
	A developer-defined identifier for the button.
]=]

--[=[
	@prop skuId string?
	@within Builders.Message.Button
	The SKU ID for purchase buttons.
]=]

--[=[
	@prop url string?
	@within Builders.Message.Button
	The URL that the button will navigate to when clicked.
]=]

--[=[
	@prop disabled boolean?
	@within Builders.Message.Button
	Whether the button is disabled and cannot be clicked.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local emoji = require("../../emoji")

local Button = {}

Button.Prototype = {}
Button.Interface = {}

--[=[
	@within Builders.Message.Button

	Sets the style of the button. This determines the button's appearance and behavior.
]=]
function Button.Prototype.setStyle(self: Button, buttonStyle: apiTypes.ButtonStyle): Button
	self.style = buttonStyle

	return self
end

--[=[
	@within Builders.Message.Button

	Sets the text that appears on the button. Must be between 1-80 characters.
]=]
function Button.Prototype.setLabel(self: Button, label: string): Button
	assert(#label <= 80, `Label must be less than 80 characters.`)
	assert(#label > 0, `Label must be more than 0 characters.`)

	self.label = label

	return self
end

--[=[
	@within Builders.Message.Button

	Sets the emoji that appears on the button.
]=]
function Button.Prototype.setEmoji(self: Button, emoji: emoji.JSON): Button
	self.emoji = emoji

	return self
end

--[=[
	@within Builders.Message.Button

	Sets a developer-defined identifier for the button that will be sent when the button is clicked.
]=]
function Button.Prototype.setCustomId(self: Button, customId: string): Button
	assert(#customId >= 1, "customId must be at least 1 character")
	assert(#customId <= 100, "customId must be at most 100 characters")

	self.customId = customId

	return self
end

--[=[
	@within Builders.Message.Button

	Sets the SKU ID for the button, used for purchase buttons.
]=]
function Button.Prototype.setSkuId(self: Button, skuId: string): Button
	self.skuId = skuId

	return self
end

--[=[
	@within Builders.Message.Button

	Sets the URL that the button will navigate to when clicked.
]=]
function Button.Prototype.setUrl(self: Button, url: string): Button
	self.url = url

	return self
end

--[=[
	@within Builders.Message.Button

	Sets whether the button is disabled and cannot be clicked.
]=]
function Button.Prototype.setDisabled(self: Button, disabled: boolean): Button
	self.disabled = disabled

	return self
end

--[=[
	@within Builders.Message.Button

	Responsible for building the Button JSON that can be parsed by the Discord API.
]=]
function Button.Prototype.build(self: Button): JSON
	assert(self.style, `Button style is required.`)

	if self.style ~= "Link" and self.style ~= "Premium" then
		assert(self.customId, "non-link buttons require a customId")
		assert(not self.url, "non-link buttons must not have a url")
	end
	if self.style == "Link" then
		assert(self.url, "link buttons require a url")
		assert(not self.customId, "link buttons must not have a customId")
	end
	if self.style == "Premium" then
		assert(self.skuId, "premium buttons require a skuId")
		assert(not self.customId, "premium buttons must not have a customId")
		assert(not self.label, "premium buttons must not have a label")
		assert(not self.emoji, "premium buttons must not have an emoji")
	end

	return {
		type = 2,
		style = apiTypes.message.ButtonStyle[self.style],
		label = self.label,
		emoji = self.emoji,
		custom_id = self.customId,
		sku_id = self.skuId,
		url = self.url,
		disabled = self.disabled,
	}
end

--[=[
	@within Builders.Message.Button

	Responsible for creating a new Button.

	```luau
	local button = Button.new({
		style = "Primary",
		label = "Click me!",
		customId = "my_button"
	})
	```
]=]
function Button.Interface.new(resource: {
	style: apiTypes.ButtonStyle,
	label: string?,
	emoji: emoji.JSON?,
	customId: string?,
	skuId: string?,
	url: string?,
	disabled: boolean?,
}?): Button
	local self = setmetatable(
		{
			style = nil,

			label = nil,

			emoji = nil,

			customId = nil,

			skuId = nil,

			url = nil,

			disabled = nil,
		} :: Button,
		{
			__index = Button.Prototype,
		}
	)

	if resource then
		if resource.style then
			self:setStyle(resource.style)
		end

		if resource.label then
			self:setLabel(resource.label)
		end

		if resource.emoji then
			self:setEmoji(resource.emoji)
		end

		if resource.customId then
			self:setCustomId(resource.customId)
		end

		if resource.skuId then
			self:setSkuId(resource.skuId)
		end

		if resource.url then
			self:setUrl(resource.url)
		end

		if resource.disabled ~= nil then
			self:setDisabled(resource.disabled)
		end
	end

	return self
end

export type Button = typeof(Button.Prototype) & {
	style: apiTypes.ButtonStyle,
	label: string?,
	emoji: emoji.JSON?,
	customId: string?,
	skuId: string?,
	url: string?,
	disabled: boolean?,
}

export type JSON = apiTypes.ButtonComponentObject

return Button.Interface
