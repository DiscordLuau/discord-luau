local Enumeration = require("../../Dependencies/Enumeration")

local ButtonComponent = {}

ButtonComponent.Type = "ButtonComponent"

ButtonComponent.Internal = {}
ButtonComponent.Interface = {}
ButtonComponent.Prototype = {
	Internal = ButtonComponent.Internal,
}

ButtonComponent.Interface.Style = Enumeration.new({
	Blurple = 1,
	Grey = 2,
	Green = 3,
	Red = 4,
	Link = 5,
})

function ButtonComponent.Prototype:SetStyle(buttonStyle)
	self.ButtonStyle = buttonStyle

	return self
end

function ButtonComponent.Prototype:SetLabel(buttonLabel)
	self.ButtonLabel = buttonLabel

	return self
end

function ButtonComponent.Prototype:SetEmoji(emojiId, emojiName)
	self.ButtonEmoji = {
		Id = emojiId,
		Name = emojiName
	}

	return self
end

function ButtonComponent.Prototype:SetLinkUrl(url)
	self.ButtonUrl = url

	return self
end

function ButtonComponent.Prototype:SetDisabled(isDisabled)
	self.ButtonDisabled = isDisabled

	return self
end

function ButtonComponent.Prototype:ToJSONObject()
	return {
		type = 2,
		style = self.ButtonStyle,
		label = self.ButtonLabel,
		custom_id = (self.ButtonStyle ~= ButtonComponent.Interface.Style.Link and self.ButtonId) or nil,
		url = (self.ButtonStyle == ButtonComponent.Interface.Style.Link and self.ButtonUrl) or nil,
		disabled = self.ButtonDisabled,
		emoji = (self.ButtonEmoji and {
			id = self.ButtonEmoji.Id,
			name = self.ButtonEmoji.Name 
		}) or nil,
	}
end

function ButtonComponent.Prototype:ToString()
	return `{ButtonComponent.Type}<{self.ButtonId}>`
end

function ButtonComponent.Interface.new(buttonId)
	return setmetatable({
		ButtonId = buttonId
	}, {
		__index = ButtonComponent.Prototype,
		__type = ButtonComponent.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return ButtonComponent.Interface
