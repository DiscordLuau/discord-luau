--[=[
	@class Classes.Button
	@__index Prototype

	Implementation of the Discord Button class in Luau

	https://discord.com/developers/docs/interactions/message-components#buttons
]=]

local apiTypes = require("../../../lune_packages/api_types")

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
	--[=[
		@prop style apiTypes.ButtonStyle
		@within Classes.Button

		The style of the button. This determines the button's appearance and behavior.
	]=]
	self.style = apiTypes.message.ButtonStyle[buttonData.style]

	--[=[
		@prop type number
		@within Classes.Button

		The type of component. For buttons, this is always 2.
	]=]
	self.type = 2

	--[=[
		@prop label string?
		@within Classes.Button

		The text that appears on the button. Optional if an emoji is provided.
	]=]
	self.label = buttonData.label

	--[=[
		@prop emoji Classes.Emoji?
		@within Classes.Button

		The emoji displayed on the button. Can be used alongside or instead of a label.
	]=]
	self.emoji = buttonData.emoji and emoji.new(buttonData.emoji)

	--[=[
		@prop customId string?
		@within Classes.Button

		A developer-defined identifier for the button. Required for all button styles except LINK.
	]=]
	self.customId = buttonData.custom_id

	--[=[
		@prop skuId string?
		@within Classes.Button

		The unique identifier of a SKU. Used for purchase buttons.
	]=]
	self.skuId = buttonData.sku_id

	--[=[
		@prop url string?
		@within Classes.Button

		The URL that the button leads to. Only valid for buttons with LINK style.
	]=]
	self.url = buttonData.url

	--[=[
		@prop disabled boolean?
		@within Classes.Button

		Whether the button is disabled. When true, the button cannot be interacted with.
	]=]
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
