
local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class Interface.ButtonComponent

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ButtonComponent = {}

ButtonComponent.Interface = {}
ButtonComponent.Prototype = {}

ButtonComponent.Prototype.type = "ButtonComponent"

ButtonComponent.Interface.Style = Enumerate.new({
	Blurple = 1,
	Grey = 2,
	Green = 3,
	Red = 4,
	Link = 5,
})

function ButtonComponent.Prototype.setStyle(self: ButtonComponent, buttonStyle: string)
	self.buttonStyle = buttonStyle

	return self
end

function ButtonComponent.Prototype.setLabel(self: ButtonComponent, buttonLabel: string)
	self.buttonLabel = buttonLabel

	return self
end

function ButtonComponent.Prototype.setEmoji(self: ButtonComponent, emojiId: string, emojiName: string)
	self.buttonEmoji = {
		id = emojiId,
		name = emojiName
	}

	return self
end

function ButtonComponent.Prototype.setLinkUrl(self: ButtonComponent, url: string)
	self.buttonUrl = url

	return self
end

function ButtonComponent.Prototype.setDisabled(self: ButtonComponent, isDisabled: boolean)
	self.buttonDisabled = isDisabled

	return self
end

function ButtonComponent.Prototype.toJSONObject(self: ButtonComponent)
	return {
		["type"] = 2,
		style = self.buttonStyle,
		label = self.buttonLabel,
		custom_id = (self.buttonStyle ~= ButtonComponent.Interface.Style.Link and self.buttonId) or nil,
		url = (self.buttonStyle == ButtonComponent.Interface.Style.Link and self.buttonUrl) or nil,
		disabled = self.buttonDisabled,
		emoji = (self.buttonEmoji and {
			id = self.buttonEmoji.id,
			name = self.buttonEmoji.name 
		}) or nil,
	}
end

function ButtonComponent.Interface.new(buttonId: string)
	return Construct({
		buttonId = buttonId
	}, ButtonComponent.Prototype)
end

export type ButtonComponent = typeof(ButtonComponent.Prototype) & {

}

return ButtonComponent.Interface
