--[=[
	@class Classes.Message.SelectMenu
	@__index Prototype

	Implementation of the Discord SelectMenu class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-menu-structure
]=]

--[=[
	@prop type number
	@within Classes.Message.SelectMenu

	The type of select menu component. This will be a number that represents the type of select menu.
]=]

--[=[
	@prop customId string
	@within Classes.Message.SelectMenu

	A developer-defined identifier for the select menu, max 100 characters.
]=]

--[=[
	@prop options {Classes.Option}?
	@within Classes.Message.SelectMenu

	Array of select menu options that users can choose from. Maximum of 25 items.
]=]

--[=[
	@prop apiTypes {api_types.ChannelType}?
	@within Classes.Message.SelectMenu

	List of channel types to include in the select menu. Only applicable for channel select menus.
]=]

--[=[
	@prop placeholder string?
	@within Classes.Message.SelectMenu

	Custom placeholder text shown when no option is selected, max 150 characters.
]=]

--[=[
	@prop defaultValues {Classes.Message.SelectMenuDefaultValue}?
	@within Classes.Message.SelectMenu

	Array of default values for auto-populated select menus.
]=]

--[=[
	@prop minValues number?
	@within Classes.Message.SelectMenu

	The minimum number of items that must be chosen. Default 1, min 0, max 25.
]=]

--[=[
	@prop maxValues number?
	@within Classes.Message.SelectMenu

	The maximum number of items that can be chosen. Default 1, max 25.
]=]

--[=[
	@prop disabled boolean?
	@within Classes.Message.SelectMenu

	Whether this select menu is disabled. Defaults to false if not set.
]=]

local apiTypes = require("../../../../luau_packages/api_types")

local option = require("./option")
local defaultValue = require("./defaultValue")

local SelectMenu = {}

SelectMenu.Interface = {}
SelectMenu.Prototype = {}

--[=[
	@within Classes.Message.SelectMenu
	@private

	Responsible for syncing data to this select menu object. This is typically called by the API when this object is
	created or updated.
]=]
function SelectMenu.Prototype.sync(self: SelectMenu, selectMenuData: apiTypes.SelectMenuComponentObject)
	local optionArray = {}
	local defaultValues = {}
	local apiTypesArray: { apiTypes.ChannelType } = {}

	for _, optionData in next, selectMenuData.options or {} do
		table.insert(optionArray, option.new(optionData))
	end

	for _, defaultValueData in next, selectMenuData.default_values or {} do
		table.insert(defaultValues, defaultValue.new(defaultValueData))
	end

	for _, channelType in next, selectMenuData.channel_types or {} do
		table.insert(apiTypesArray, apiTypes.channel.ApiTypes[channelType])
	end

	self.type = selectMenuData.type

	self.customId = selectMenuData.custom_id

	self.options = optionArray

	self.apiTypes = apiTypesArray

	self.placeholder = selectMenuData.placeholder

	self.defaultValues = defaultValues

	self.minValues = selectMenuData.min_values

	self.maxValues = selectMenuData.max_values

	self.disabled = selectMenuData.disabled
end

--[=[
	@within Classes.Message.SelectMenu
	@private

	Responsible for constructing this class.
]=]
function SelectMenu.Interface.new(selectMenuData: apiTypes.SelectMenuComponentObject): SelectMenu
	local self = setmetatable({} :: SelectMenu, { __index = SelectMenu.Prototype })

	self:sync(selectMenuData)

	return self
end

export type SelectMenu = typeof(SelectMenu.Prototype) & {
	type: number,
	customId: string,
	options: { option.Option }?,
	apiTypes: { apiTypes.ChannelType }?,
	placeholder: string?,
	defaultValues: { defaultValue.DefaultValue }?,
	minValues: number?,
	maxValues: number?,
	disabled: boolean?,
}

return SelectMenu.Interface
