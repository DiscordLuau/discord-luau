--[=[
	@class Classes.Button
	@__index Prototype

	Implementation of the Discord Button class in Luau

	https://discord.com/developers/docs/interactions/message-components#buttons
]=]

--[=[
	@prop style apiTypes.ButtonStyle
	@within Classes.Button

	The style of the button. This determines the button's appearance and behavior.
]=]

--[=[
	@prop type number
	@within Classes.Button

	The type of component. For buttons, this is always 2.
]=]

--[=[
	@prop label string?
	@within Classes.Button

	The text that appears on the button. Optional if an emoji is provided.
]=]

--[=[
	@prop emoji Classes.Emoji?
	@within Classes.Button

	The emoji displayed on the button. Can be used alongside or instead of a label.
]=]

--[=[
	@prop customId string?
	@within Classes.Button

	A developer-defined identifier for the button. Required for all button styles except LINK.
]=]

--[=[
	@prop skuId string?
	@within Classes.Button

	The unique identifier of a SKU. Used for purchase buttons.
]=]

--[=[
	@prop url string?
	@within Classes.Button

	The URL that the button leads to. Only valid for buttons with LINK style.
]=]

--[=[
	@prop disabled boolean?
	@within Classes.Button

	Whether the button is disabled. When true, the button cannot be interacted with.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local emoji = require("../../emoji")

local Button = {}

Button.Interface = {}
Button.Prototype = {}

--[=[
	@within Classes.Button
	@private

	Responsible for syncing data to this button object. This is typically called by the API when this object is
	created or updated.
]=]
function Button.Prototype.sync(self: Button, buttonData: apiTypes.ButtonComponentObject)
	self.style = apiTypes.message.ButtonStyle[buttonData.style]

	self.type = 2

	self.label = buttonData.label

	self.emoji = buttonData.emoji and emoji.new(buttonData.emoji)

	self.customId = buttonData.custom_id

	self.skuId = buttonData.sku_id

	self.url = buttonData.url

	self.disabled = buttonData.disabled
end

--[=[
	@within Classes.Button
	@private

	Responsible for constructing this class.
]=]
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
