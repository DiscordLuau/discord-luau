--[[
	Implementation of the Discord Button class in Luau

	https://discord.com/developers/docs/interactions/message-components#buttons
]]

local apiTypes = require("../../../lune_packages/api_types")

local emoji = require("../../emoji")

local Button = {}

Button.Interface = {}
Button.Prototype = {}

function Button.Prototype.sync(self: Button, buttonData: apiTypes.ButtonComponentObject)
	self.style = apiTypes.message.ButtonStyle[buttonData.style]

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
	style: apiTypes.ButtonStyle,
	label: string?,
	emoji: emoji.Emoji?,
	customId: string?,
	skuId: apiTypes.Snowflake?,
	url: string?,
	disabled: boolean?,
}

return Button.Interface
