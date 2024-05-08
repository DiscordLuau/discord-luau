local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class Interface.TextInputComponent

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local TextInputComponent = {}

TextInputComponent.Interface = {}
TextInputComponent.Prototype = {}

TextInputComponent.Prototype.type = "TextInputComponent"

TextInputComponent.Interface.Style = Enumerate.new({
	Short = 1,
	Paragraph = 2
})

function TextInputComponent.Prototype.setStyle(self: TextInputComponent, inputStyle: number): TextInputComponent
	self.textInputStyle = inputStyle

	return self
end

function TextInputComponent.Prototype.setLabel(self: TextInputComponent, label: string): TextInputComponent
	self.textInputLabel = label

	return self
end

function TextInputComponent.Prototype.setMinLength(self: TextInputComponent, length: number): TextInputComponent
	self.textInputMinLength = length

	return self
end

function TextInputComponent.Prototype.setMaxLength(self: TextInputComponent, length: number): TextInputComponent
	self.textInputMaxLength = length

	return self
end

function TextInputComponent.Prototype.setRequired(self: TextInputComponent, isRequired: boolean): TextInputComponent
	self.textInputRequired = isRequired

	return self
end

function TextInputComponent.Prototype.setDefaultValue(self: TextInputComponent, value: string): TextInputComponent
	self.textInputDefaultValue = value

	return self
end

function TextInputComponent.Prototype.setPlaceholder(self: TextInputComponent, value: string): TextInputComponent
	self.textInputPlaceholderValue = value

	return self
end

function TextInputComponent.Prototype.toJSONObject(self: TextInputComponent)
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

function TextInputComponent.Interface.new(textInputId: string)
	return Construct({
		textInputId = textInputId
	}, TextInputComponent.Prototype)
end

export type TextInputComponent = typeof(TextInputComponent.Prototype) & {
	textInputStyle: number?,
	textInputId: string?,
	textInputLabel: string?,
	textInputMinLength: number?,
	textInputMaxLength: number?,
	textInputRequired: boolean?,
	textInputDefaultValue: any?,
	textInputPlaceholderValue: any?
}

return TextInputComponent.Interface