--[=[
	@class Builders.TextInput
	@__index Prototype

	Implementation of discords TextInput object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local TextInput = {}

TextInput.Prototype = {}
TextInput.Interface = {}

--[=[
	@within Builders.TextInput

	Sets the custom identifier for this text input component.
]=]
function TextInput.Prototype.setCustomId(self: TextInput, customId: string): TextInput
	self.customId = customId

	return self
end

--[=[
	@within Builders.TextInput

	Sets the style of the text input component.
]=]
function TextInput.Prototype.setStyle(self: TextInput, style: apiTypes.TextInputStyle): TextInput
	self.style = style

	return self
end

--[=[
	@within Builders.TextInput

	Sets the label text that appears above the text input field.
]=]
function TextInput.Prototype.setLabel(self: TextInput, label: string): TextInput
	self.label = label

	return self
end

--[=[
	@within Builders.TextInput

	Sets the minimum length of text that can be entered.
]=]
function TextInput.Prototype.setMinLength(self: TextInput, minLength: number): TextInput
	self.minLength = minLength

	return self
end

--[=[
	@within Builders.TextInput

	Sets the maximum length of text that can be entered.
]=]
function TextInput.Prototype.setMaxLength(self: TextInput, maxLength: number): TextInput
	self.maxLength = maxLength

	return self
end

--[=[
	@within Builders.TextInput

	Sets whether this text input field is required to be filled.
]=]
function TextInput.Prototype.setIsRequired(self: TextInput, isRequired: boolean): TextInput
	self.required = isRequired

	return self
end

--[=[
	@within Builders.TextInput

	Sets the pre-filled value for the text input field.
]=]
function TextInput.Prototype.setValue(self: TextInput, value: string): TextInput
	self.value = value

	return self
end

--[=[
	@within Builders.TextInput

	Sets the placeholder text that appears when no text is entered.
]=]
function TextInput.Prototype.setPlaceholder(self: TextInput, placeholder: string): TextInput
	self.placeholder = placeholder

	return self
end

--[=[
	@within Builders.TextInput

	Responsible for building the TextInput JSON that can be parsed by the Discord API.
]=]
function TextInput.Prototype.build(self: TextInput): JSON
	assert(self.customId, `TextInput.customId is required.`)
	assert(self.style, `TextInput.style is required.`)
	assert(self.label, `TextInput.label is required.`)

	return {
		type = 4,
		custom_id = self.customId,
		style = apiTypes.message.MessageType[self.style],
		label = self.label,
		min_length = self.minLength,
		max_length = self.maxLength,
		required = self.required,
		value = self.value,
		placeholder = self.placeholder,
	}
end

--[=[
	@within Builders.TextInput

	Responsible for creating a new TextInput.

	```luau
	local textInput = TextInput.new({
		customId = "my_text_input",
		style = TextInputStyle.Short,
		label = "Enter your name"
	})
	```
]=]
function TextInput.Interface.new(resource: {
	customId: string?,
	style: apiTypes.TextInputStyle?,
	label: string?,
	minLength: number?,
	maxLength: number?,
	required: boolean?,
	value: string?,
	placeholder: string?,
}?): TextInput
	local self = setmetatable(
		{
			--[=[
				@prop customId string?
				@within Builders.TextInput
				The custom identifier for the text input component.
			]=]
			customId = nil,

			--[=[
				@prop style apiTypes.TextInputStyle?
				@within Builders.TextInput
				The style of the text input component.
			]=]
			style = nil,

			--[=[
				@prop label string?
				@within Builders.TextInput
				The label text that appears above the text input field.
			]=]
			label = nil,

			--[=[
				@prop minLength number?
				@within Builders.TextInput
				The minimum length of text that can be entered.
			]=]
			minLength = nil,

			--[=[
				@prop maxLength number?
				@within Builders.TextInput
				The maximum length of text that can be entered.
			]=]
			maxLength = nil,

			--[=[
				@prop required boolean?
				@within Builders.TextInput
				Whether this text input field is required to be filled.
			]=]
			required = nil,

			--[=[
				@prop value string?
				@within Builders.TextInput
				The pre-filled value for the text input field.
			]=]
			value = nil,

			--[=[
				@prop placeholder string?
				@within Builders.TextInput
				The placeholder text that appears when no text is entered.
			]=]
			placeholder = nil,
		} :: TextInput,
		{
			__index = TextInput.Prototype,
		}
	)

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

		if resource.required then
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
	style: apiTypes.TextInputStyle?,
	label: string?,
	minLength: number?,
	maxLength: number?,
	required: boolean?,
	value: string?,
	placeholder: string?,
}

export type JSON = apiTypes.TextInputComponentObject

return TextInput.Interface
