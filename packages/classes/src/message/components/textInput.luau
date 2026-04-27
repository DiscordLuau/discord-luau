--[=[
	@class Classes.Message.TextInput
	@__index Prototype

	Implementation of the Discord TextInput class in Luau

	https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-structure
]=]

--[=[
	@prop type number
	@within Classes.Message.TextInput

	The type of component this is - for text inputs, this is always 4
]=]

--[=[
	@prop customId string
	@within Classes.Message.TextInput

	A developer-defined identifier for the text input, max 100 characters
]=]

--[=[
	@prop style apiTypes.TextInputStyle
	@within Classes.Message.TextInput

	The style of the text input field - can be single-line (SHORT) or multi-line (PARAGRAPH)
]=]

--[=[
	@prop label string
	@within Classes.Message.TextInput

	The label displayed above the text input field
]=]

--[=[
	@prop minLength number?
	@within Classes.Message.TextInput

	The minimum length of text the user must input (0-4000)
]=]

--[=[
	@prop maxLength number?
	@within Classes.Message.TextInput

	The maximum length of text the user can input (1-4000)
]=]

--[=[
	@prop required boolean?
	@within Classes.Message.TextInput

	Whether this text input is required to be filled before the form can be submitted
]=]

--[=[
	@prop value string?
	@within Classes.Message.TextInput

	Pre-filled value for the text input field
]=]

--[=[
	@prop placeholder string?
	@within Classes.Message.TextInput

	Custom placeholder text shown when the text input field is empty
]=]

local apiTypes = require("../../../luau_packages/api_types")

local TextInput = {}

TextInput.Interface = {}
TextInput.Prototype = {}

--[=[
	@within Classes.Message.TextInput
	@private

	Responsible for syncing data to this text input object. This is typically called by the API when this object is
	created or updated.
]=]
function TextInput.Prototype.sync(self: TextInput, textInputData: apiTypes.TextInputComponentObject)
	self.type = textInputData.type

	self.customId = textInputData.custom_id

	self.style = apiTypes.message.TextInputStyle[textInputData.style]

	self.label = textInputData.label

	self.minLength = textInputData.min_length

	self.maxLength = textInputData.max_length

	self.required = textInputData.required

	self.value = textInputData.value

	self.placeholder = textInputData.placeholder
end

--[=[
	@within Classes.Message.TextInput
	@private

	Responsible for constructing this class.
]=]
function TextInput.Interface.new(textInputData: apiTypes.TextInputComponentObject): TextInput
	local self = setmetatable({} :: TextInput, { __index = TextInput.Prototype })

	self:sync(textInputData)

	return self
end

export type TextInput = typeof(TextInput.Prototype) & {
	type: number,
	customId: string,
	style: apiTypes.TextInputStyle,
	label: string,
	minLength: number?,
	maxLength: number?,
	required: boolean?,
	value: string?,
	placeholder: string?,
}

return TextInput.Interface
