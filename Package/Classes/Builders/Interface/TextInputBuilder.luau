local Enumerate = require("@Utils/Enumerate")
local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Builders.Interface.TextInputBuilder

	TextInputBuilder is used to construct a text input component for a Discord message.
]=]
local TextInputBuilder = {}

TextInputBuilder.Interface = {}
TextInputBuilder.Prototype = {}

TextInputBuilder.Prototype.type = "TextInputBuilder"

--[=[
	@prop Style table
	@within Builders.Interface.TextInputBuilder

	An enumeration of text input styles.

	- Short: 1
	- Paragraph: 2
]=]
TextInputBuilder.Interface.Style = Enumerate.new({
	Short = 1,
	Paragraph = 2,
})

--[=[
	
	Sets the style of the text input.
	
	@method setStyle
	@param inputStyle number -- The style of the text input.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- Returns the TextInputBuilder instance for method chaining.
]=]
function TextInputBuilder.Prototype.setStyle(self: TextInputBuilder, inputStyle: number): TextInputBuilder
	self.textInputStyle = inputStyle

	return self
end

--[=[
	Sets the label of the text input.
	
	@method setLabel
	@param label string -- The label of the text input.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- Returns the TextInputBuilder instance for method chaining.
]=]
function TextInputBuilder.Prototype.setLabel(self: TextInputBuilder, label: string): TextInputBuilder
	self.textInputLabel = label

	return self
end

--[=[
	Sets the minimum length of the text input.
	
	@method setMinLength
	@param length number -- The minimum length of the text input.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- Returns the TextInputBuilder instance for method chaining.
]=]
function TextInputBuilder.Prototype.setMinLength(self: TextInputBuilder, length: number): TextInputBuilder
	self.textInputMinLength = length

	return self
end

--[=[
	Sets the maximum length of the text input.
	
	@method setMaxLength
	@param length number -- The maximum length of the text input.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- Returns the TextInputBuilder instance for method chaining.
]=]
function TextInputBuilder.Prototype.setMaxLength(self: TextInputBuilder, length: number): TextInputBuilder
	self.textInputMaxLength = length

	return self
end

--[=[
	Sets whether the text input is required.
	
	@method setRequired
	@param isRequired boolean -- Whether the text input is required.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- Returns the TextInputBuilder instance for method chaining.
]=]
function TextInputBuilder.Prototype.setRequired(self: TextInputBuilder, isRequired: boolean): TextInputBuilder
	self.textInputRequired = isRequired

	return self
end

--[=[
	Sets the default value of the text input.
	
	@method setDefaultValue
	@param value string -- The default value of the text input.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- Returns the TextInputBuilder instance for method chaining.
]=]
function TextInputBuilder.Prototype.setDefaultValue(self: TextInputBuilder, value: string): TextInputBuilder
	self.textInputDefaultValue = value

	return self
end

--[=[
	Sets the placeholder value of the text input.
	
	@method setPlaceholder
	@param value string -- The placeholder value of the text input.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- Returns the TextInputBuilder instance for method chaining.
]=]
function TextInputBuilder.Prototype.setPlaceholder(self: TextInputBuilder, value: string): TextInputBuilder
	self.textInputPlaceholderValue = value

	return self
end

--[=[
	Converts the text input to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.Interface.TextInputBuilder
	@return Network.Resolvable
]=]
function TextInputBuilder.Prototype.toPayloadObject(self: TextInputBuilder)
	return Resolvable.new(ResolvableType.JSON, {
		type = 4,
		custom_id = self.textInputId,

		style = self.textInputStyle,
		label = self.textInputLabel,

		min_length = self.textInputMinLength,
		max_length = self.textInputMaxLength,

		required = self.textInputRequired,

		value = self.textInputDefaultValue,
		placeholder = self.textInputPlaceholderValue,
	})
end

--[=[
	
	Creates a new instance of TextInputBuilder.
	
	@function new
	@param textInputId string -- The ID of the text input.
	@within Builders.Interface.TextInputBuilder
	@return Builders.Interface.TextInputBuilder -- A new instance of TextInputBuilder.
]=]
function TextInputBuilder.Interface.new(textInputId: string): TextInputBuilder
	return Construct({
		textInputId = textInputId,
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
	textInputPlaceholderValue: any?,
}

return TextInputBuilder.Interface
