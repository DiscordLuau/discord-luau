--[[
	Implementation of discords Button object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#buttons
]]

local apiTypes = require("../../../lune_packages/api_types")

local emoji = require("../../emoji")

local Button = {}

Button.Prototype = {}
Button.Interface = {}

--[[
	
]]
function Button.Prototype.setStyle(self: Button, buttonStyle: apiTypes.ButtonStyle): Button
	self.style = buttonStyle

	return self
end

--[[
	
]]
function Button.Prototype.setLabel(self: Button, label: string): Button
	assert(#label <= 80, `Label must be less than 80 characters.`)
	assert(#label > 0, `Label must be more than 0 characters.`)

	self.label = label

	return self
end

--[[
	
]]
function Button.Prototype.setEmoji(self: Button, emoji: emoji.JSON): Button
	self.emoji = emoji

	return self
end

--[[
	
]]
function Button.Prototype.setCustomId(self: Button, customId: string): Button
	self.customId = customId

	return self
end

--[[
	
]]
function Button.Prototype.setSkuId(self: Button, skuId: string): Button
	self.skuId = skuId

	return self
end

--[[
	
]]
function Button.Prototype.setUrl(self: Button, url: string): Button
	self.url = url

	return self
end

--[[
	
]]
function Button.Prototype.setDisabled(self: Button, disabled: boolean): Button
	self.disabled = disabled

	return self
end

--[[
	Responsible for building the Button JSON that can be parsed by the Discord API.
]]
function Button.Prototype.build(self: Button): JSON
	assert(self.style, `Button style is required.`)

	return {
		type = 2,
		style = apiTypes.channel.ButtonStyle[self.style],
		label = self.label,
		emoji = self.emoji,
		custom_id = self.customId,
		sku_id = self.skuId,
		url = self.url,
		disabled = self.disabled,
	}
end

--[[
	Responsible for creating a new Button.

	```lua
	
	```
]]
function Button.Interface.new(resource: {
	style: apiTypes.ButtonStyle,
	label: string?,
	emoji: emoji.JSON?,
	customId: string?,
	skuId: string?,
	url: string?,
	disabled: boolean?,
}?): Button
	local self = setmetatable({} :: Button, {
		__index = Button.Prototype,
	})

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
