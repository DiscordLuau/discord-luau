local Enumeration = require("../../Dependencies/Enumeration")

local TextInputComponent = {}

TextInputComponent.Type = "TextInputComponent"

TextInputComponent.Internal = {}
TextInputComponent.Interface = {}
TextInputComponent.Prototype = {
	Internal = TextInputComponent.Internal,
}

TextInputComponent.Interface.Style = Enumeration.new({
	Short = 1,
	Paragraph = 2
})

function TextInputComponent.Prototype:SetStyle(inputStyle)
	self.TextInputStyle = inputStyle

	return self
end

function TextInputComponent.Prototype:SetLabel(labelString)
	self.TextInputLabel = labelString

	return self
end

function TextInputComponent.Prototype:SetMinLength(lengthInt)
	self.TextInputMinLength = lengthInt

	return self
end

function TextInputComponent.Prototype:SetMaxLength(lengthInt)
	self.TextInputMaxLength = lengthInt

	return self
end

function TextInputComponent.Prototype:SetRequired(isRequired)
	self.TextInputRequired = isRequired

	return self
end

function TextInputComponent.Prototype:SetDefaultValue(value)
	self.TextInputDefaultValue = value

	return self
end

function TextInputComponent.Prototype:SetPlaceholder(value)
	self.TextInputPlaceholderValue = value

	return self
end

function TextInputComponent.Prototype:ToJSONObject()
	return {
		type = 4,
		custom_id = self.TextInputId,

		style = self.TextInputStyle,
		label = self.TextInputLabel,

		min_length = self.TextInputMinLength,
		max_length = self.TextInputMaxLength,

		required = self.TextInputRequired,

		value = self.TextInputDefaultValue,
		placeholder = self.TextInputPlaceholderValue
	}
end

function TextInputComponent.Prototype:ToString()
	return `{TextInputComponent.Type}`
end

function TextInputComponent.Interface.new(textInputId)
	return setmetatable({
		TextInputId = textInputId
	}, {
		__index = TextInputComponent.Prototype,
		__type = TextInputComponent.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return TextInputComponent.Interface
