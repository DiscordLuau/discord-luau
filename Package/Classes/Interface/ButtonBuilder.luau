local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class Interface.ButtonBuilder

	ButtonBuilder is used to construct a button component for a Discord message.
]=]
local ButtonBuilder = {}

ButtonBuilder.Interface = {}
ButtonBuilder.Prototype = {}

ButtonBuilder.Prototype.type = "ButtonBuilder"

--[=[
	@prop Style table
	@within Interface.ButtonBuilder

	An enumeration of button styles.

	- Blurple: 1
	- Grey: 2
	- Green: 3
	- Red: 4
	- Link: 5
]=]
ButtonBuilder.Interface.Style = Enumerate.new({
	Blurple = 1,
	Grey = 2,
	Green = 3,
	Red = 4,
	Link = 5,
})

--[=[
	Sets the style of the button.
	
	@private
	@method setStyle
	@param buttonStyle number -- The style of the button.
	@within Interface.ButtonBuilder
	@return ButtonBuilder -- Returns the ButtonBuilder instance for method chaining.
]=]
function ButtonBuilder.Prototype.setStyle(self: ButtonBuilder, buttonStyle: number)
	self.buttonStyle = buttonStyle

	return self
end

--[=[
	Sets the label of the button.
	
	@private
	@method setLabel
	@param buttonLabel string -- The label of the button.
	@within Interface.ButtonBuilder
	@return ButtonBuilder -- Returns the ButtonBuilder instance for method chaining.
]=]
function ButtonBuilder.Prototype.setLabel(self: ButtonBuilder, buttonLabel: string)
	self.buttonLabel = buttonLabel

	return self
end

--[=[
	Sets the emoji for the button.
	
	@private
	@method setEmoji
	@param emojiId string -- The ID of the emoji.
	@param emojiName string -- The name of the emoji.
	@within Interface.ButtonBuilder
	@return ButtonBuilder -- Returns the ButtonBuilder instance for method chaining.
]=]
function ButtonBuilder.Prototype.setEmoji(self: ButtonBuilder, emojiId: string, emojiName: string)
	self.buttonEmoji = {
		id = emojiId,
		name = emojiName
	}

	return self
end

--[=[
	Sets the URL for the button. This should only be used if the button style is set to `Link`.
	
	@private
	@method setLinkUrl
	@param url string -- The URL to set.
	@within Interface.ButtonBuilder
	@return ButtonBuilder -- Returns the ButtonBuilder instance for method chaining.
]=]
function ButtonBuilder.Prototype.setLinkUrl(self: ButtonBuilder, url: string)
	self.buttonUrl = url

	return self
end

--[=[
	Sets whether the button is disabled.
	
	@private
	@method setDisabled
	@param isDisabled boolean -- Whether the button is disabled.
	@within Interface.ButtonBuilder
	@return ButtonBuilder -- Returns the ButtonBuilder instance for method chaining.
]=]
function ButtonBuilder.Prototype.setDisabled(self: ButtonBuilder, isDisabled: boolean)
	self.buttonDisabled = isDisabled

	return self
end

--[=[
	Converts the button to a JSON object that can be sent to the Discord API.
	
	@private
	@method toJSONObject
	@within Interface.ButtonBuilder
	@return table -- The JSON representation of the button.
]=]
function ButtonBuilder.Prototype.toJSONObject(self: ButtonBuilder)
	return {
		["type"] = 2,
		style = self.buttonStyle,
		label = self.buttonLabel,
		custom_id = (self.buttonStyle ~= ButtonBuilder.Interface.Style.Link and self.buttonId) or nil,
		url = (self.buttonStyle == ButtonBuilder.Interface.Style.Link and self.buttonUrl) or nil,
		disabled = self.buttonDisabled,
		emoji = (self.buttonEmoji and {
			id = self.buttonEmoji.id,
			name = self.buttonEmoji.name 
		}) or nil,
	}
end

--[=[
	
	Creates a new instance of ButtonBuilder.
	
	@private
	@function new
	@param buttonId string -- The ID of the button.
	@within Interface.ButtonBuilder
	@return ButtonBuilder -- A new instance of ButtonBuilder.
]=]
function ButtonBuilder.Interface.new(buttonId: string): ButtonBuilder
	return Construct({
		buttonId = buttonId
	}, ButtonBuilder.Prototype) :: any
end

export type ButtonBuilder = typeof(ButtonBuilder.Prototype) & {
	buttonStyle: number?,
	buttonLabel: string?,
	buttonId: string?,
	buttonUrl: string?,
	buttonDisabled: boolean?,
	buttonEmoji: {
		id: string,
		name: string,
	}?
}

return ButtonBuilder.Interface
