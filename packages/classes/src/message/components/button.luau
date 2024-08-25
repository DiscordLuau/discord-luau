--[[
	Implementation of the Discord Button class in Luau

	https://discord.com/developers/docs/interactions/message-components#buttons
]]

local apiTypes = require("@api-types/apiTypes")
local messageTypes = require("@api-types/message")

local emoji = require("@classes/emoji")

local Button = {}

Button.Interface = {}
Button.Prototype = {}

function Button.Prototype.sync(self: Button, buttonData: apiTypes.ButtonComponentObject)
	self.style = (
		buttonData.style == 1 and "Blurple"
		or buttonData.style == 2 and "Grey"
		or buttonData.style == 3 and "Green"
		or buttonData.style == 4 and "Red"
		or buttonData.style == 5 and "Grey"
	) :: messageTypes.ButtonStyle

	self.type = 2
	self.label = buttonData.label
	self.emoji = buttonData.emoji and emoji.new(buttonData.emoji)
	self.customId = buttonData.custom_id
	self.url = buttonData.url
	self.disabled = buttonData.disabled
end

function Button.Interface.new(buttonData: apiTypes.ButtonComponentObject): Button
	local self = setmetatable({} :: Button, { __index = Button.Prototype })

	self:sync(buttonData)

	return self
end

export type Button = typeof(Button.Prototype) & {
	type: number,
	style: messageTypes.ButtonStyle,
	label: string?,
	emoji: emoji.Emoji?,
	customId: string?,
	skuId: apiTypes.Snowflake?,
	url: string?,
	disabled: boolean?,
}

return Button.Interface
