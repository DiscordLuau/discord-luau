--[[
	Implementation of the Discord TextInput class in Luau

	https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local TextInput = {}

TextInput.Interface = {}
TextInput.Prototype = {}

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
