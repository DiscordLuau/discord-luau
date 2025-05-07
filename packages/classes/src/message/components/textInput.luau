--[=[
	@class Classes.TextInput
	@__index Prototype

	Implementation of the Discord TextInput class in Luau

	https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local TextInput = {}

TextInput.Interface = {}
TextInput.Prototype = {}

--[=[
	@within Classes.TextInput
	@private

	Responsible for syncing data to this text input object. This is typically called by the API when this object is
	created or updated.
]=]
function TextInput.Prototype.sync(self: TextInput, textInputData: apiTypes.TextInputComponentObject)
	--[=[
		@prop type number
		@within Classes.TextInput

		The type of component this is - for text inputs, this is always 4
	]=]
	self.type = textInputData.type

	--[=[
		@prop customId string
		@within Classes.TextInput

		A developer-defined identifier for the text input, max 100 characters
	]=]
	self.customId = textInputData.custom_id

	--[=[
		@prop style apiTypes.TextInputStyle
		@within Classes.TextInput

		The style of the text input field - can be single-line (SHORT) or multi-line (PARAGRAPH)
	]=]
	self.style = apiTypes.message.TextInputStyle[textInputData.style]

	--[=[
		@prop label string
		@within Classes.TextInput

		The label displayed above the text input field
	]=]
	self.label = textInputData.label

	--[=[
		@prop minLength number?
		@within Classes.TextInput

		The minimum length of text the user must input (0-4000)
	]=]
	self.minLength = textInputData.min_length

	--[=[
		@prop maxLength number?
		@within Classes.TextInput

		The maximum length of text the user can input (1-4000)
	]=]
	self.maxLength = textInputData.max_length

	--[=[
		@prop required boolean?
		@within Classes.TextInput

		Whether this text input is required to be filled before the form can be submitted
	]=]
	self.required = textInputData.required

	--[=[
		@prop value string?
		@within Classes.TextInput

		Pre-filled value for the text input field
	]=]
	self.value = textInputData.value

	--[=[
		@prop placeholder string?
		@within Classes.TextInput

		Custom placeholder text shown when the text input field is empty
	]=]
	self.placeholder = textInputData.placeholder
end

--[=[
	@within Classes.TextInput
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
