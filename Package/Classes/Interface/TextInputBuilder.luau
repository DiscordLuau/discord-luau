local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class Interface.TextInputBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local TextInputBuilder = {}

TextInputBuilder.Interface = {}
TextInputBuilder.Prototype = {}

TextInputBuilder.Prototype.type = "TextInputBuilder"

TextInputBuilder.Interface.Style = Enumerate.new({
	Short = 1,
	Paragraph = 2
})

function TextInputBuilder.Prototype.setStyle(self: TextInputBuilder, inputStyle: number): TextInputBuilder
	self.textInputStyle = inputStyle

	return self
end

function TextInputBuilder.Prototype.setLabel(self: TextInputBuilder, label: string): TextInputBuilder
	self.textInputLabel = label

	return self
end

function TextInputBuilder.Prototype.setMinLength(self: TextInputBuilder, length: number): TextInputBuilder
	self.textInputMinLength = length

	return self
end

function TextInputBuilder.Prototype.setMaxLength(self: TextInputBuilder, length: number): TextInputBuilder
	self.textInputMaxLength = length

	return self
end

function TextInputBuilder.Prototype.setRequired(self: TextInputBuilder, isRequired: boolean): TextInputBuilder
	self.textInputRequired = isRequired

	return self
end

function TextInputBuilder.Prototype.setDefaultValue(self: TextInputBuilder, value: string): TextInputBuilder
	self.textInputDefaultValue = value

	return self
end

function TextInputBuilder.Prototype.setPlaceholder(self: TextInputBuilder, value: string): TextInputBuilder
	self.textInputPlaceholderValue = value

	return self
end

function TextInputBuilder.Prototype.toJSONObject(self: TextInputBuilder)
	return {
		type = 4,
		custom_id = self.textInputId,

		style = self.textInputStyle,
		label = self.textInputLabel,

		min_length = self.textInputMinLength,
		max_length = self.textInputMaxLength,

		required = self.textInputRequired,

		value = self.textInputDefaultValue,
		placeholder = self.textInputPlaceholderValue
	}
end

function TextInputBuilder.Interface.new(textInputId: string): TextInputBuilder
	return Construct({
		textInputId = textInputId
	}, TextInputBuilder.Prototype) :: any
end

export type TextInputBuilder = typeof(TextInputBuilder.Prototype) & {
	textInputStyle: number?,
	textInputId: string?,
	textInputLabel: string?,
	textInputMinLength: number?,
	textInputMaxLength: number?,
	textInputRequired: boolean?,
	textInputDefaultValue: any?,
	textInputPlaceholderValue: any?
}

return TextInputBuilder.Interface