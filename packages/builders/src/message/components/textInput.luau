--[[
	Implementation of discords TextInput object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-structure
]]

local messageTypes = require("@api-types/message")

local TextInput = {}

TextInput.Prototype = {}
TextInput.Interface = {}

--[[
	
]]
function TextInput.Prototype.setCustomId(self: TextInput, customId: string): TextInput
	self.customId = customId

	return self
end

--[[
	
]]
function TextInput.Prototype.setStyle(self: TextInput, style: messageTypes.TextInputStyle): TextInput
	self.style = style

	return self
end

--[[
	
]]
function TextInput.Prototype.setLabel(self: TextInput, label: string): TextInput
	self.label = label

	return self
end

--[[
	
]]
function TextInput.Prototype.setMinLength(self: TextInput, minLength: number): TextInput
	self.minLength = minLength

	return self
end

--[[
	
]]
function TextInput.Prototype.setMaxLength(self: TextInput, maxLength: number): TextInput
	self.maxLength = maxLength

	return self
end

--[[
	
]]
function TextInput.Prototype.setIsRequired(self: TextInput, isRequired: boolean): TextInput
	self.required = isRequired

	return self
end

--[[
	
]]
function TextInput.Prototype.setValue(self: TextInput, value: string): TextInput
	self.value = value

	return self
end

--[[
	
]]
function TextInput.Prototype.setPlaceholder(self: TextInput, placeholder: string): TextInput
	self.placeholder = placeholder

	return self
end

--[[
	Responsible for building the TextInput JSON that can be parsed by the Discord API.
]]
function TextInput.Prototype.build(self: TextInput): JSON
	return {
		type = 4,
		custom_id = self.customId,
		style = messageTypes.MessageType[self.style],
		label = self.label,
		min_length = self.minLength,
		max_length = self.maxLength,
		required = self.required,
		value = self.value,
		placeholder = self.placeholder,
	}
end

--[[
	Responsible for creating a new TextInput.

	```lua
	
	```
]]
function TextInput.Interface.new(resource: {
	customId: string?,
	style: messageTypes.TextInputStyle?,
	label: string?,
	minLength: number?,
	maxLength: number?,
	required: boolean?,
	value: string?,
	placeholder: string?,
}?): TextInput
	local self = setmetatable({} :: TextInput, {
		__index = TextInput.Prototype,
	})

	if resource then
		if resource.customId then
			self:setCustomId(resource.customId)
		end

		if resource.style then
			self:setStyle(resource.style)
		end

		if resource.label then
			self:setLabel(resource.label)
		end

		if resource.minLength then
			self:setMinLength(resource.minLength)
		end

		if resource.maxLength then
			self:setMaxLength(resource.maxLength)
		end

		if resource.required ~= nil then
			self:setIsRequired(resource.required)
		end

		if resource.value then
			self:setValue(resource.value)
		end

		if resource.placeholder then
			self:setPlaceholder(resource.placeholder)
		end
	end

	return self
end

export type TextInput = typeof(TextInput.Prototype) & {
	customId: string?,
	style: messageTypes.TextInputStyle?,
	label: string?,
	minLength: number?,
	maxLength: number?,
	required: boolean?,
	value: string?,
	placeholder: string?,
}

export type JSON = typeof(TextInput.Prototype.build(nil :: any))

return TextInput.Interface
