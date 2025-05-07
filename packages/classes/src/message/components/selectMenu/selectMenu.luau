--[=[
	@class Classes.SelectMenu
	@__index Prototype

	Implementation of the Discord SelectMenu class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-menu-structure
]=]

local apiTypes = require("../../../../lune_packages/api_types")

local option = require("./option")
local defaultValue = require("./defaultValue")

local SelectMenu = {}

SelectMenu.Interface = {}
SelectMenu.Prototype = {}

--[=[
	@within Classes.SelectMenu
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

	--[=[
		@prop type number
		@within Classes.SelectMenu

		The type of select menu component. This will be a number that represents the type of select menu.
	]=]
	self.type = selectMenuData.type

	--[=[
		@prop customId string
		@within Classes.SelectMenu

		A developer-defined identifier for the select menu, max 100 characters.
	]=]
	self.customId = selectMenuData.custom_id

	--[=[
		@prop options {Classes.Option}?
		@within Classes.SelectMenu

		Array of select menu options that users can choose from. Maximum of 25 items.
	]=]
	self.options = optionArray

	--[=[
		@prop apiTypes {api_types.ChannelType}?
		@within Classes.SelectMenu

		List of channel types to include in the select menu. Only applicable for channel select menus.
	]=]
	self.apiTypes = apiTypesArray

	--[=[
		@prop placeholder string?
		@within Classes.SelectMenu

		Custom placeholder text shown when no option is selected, max 150 characters.
	]=]
	self.placeholder = selectMenuData.placeholder

	--[=[
		@prop defaultValues {Classes.DefaultValue}?
		@within Classes.SelectMenu

		Array of default values for auto-populated select menus.
	]=]
	self.defaultValues = defaultValues

	--[=[
		@prop minValues number?
		@within Classes.SelectMenu

		The minimum number of items that must be chosen. Default 1, min 0, max 25.
	]=]
	self.minValues = selectMenuData.min_values

	--[=[
		@prop maxValues number?
		@within Classes.SelectMenu

		The maximum number of items that can be chosen. Default 1, max 25.
	]=]
	self.maxValues = selectMenuData.max_values

	--[=[
		@prop disabled boolean?
		@within Classes.SelectMenu

		Whether this select menu is disabled. Defaults to false if not set.
	]=]
	self.disabled = selectMenuData.disabled
end

--[=[
	@within Classes.SelectMenu
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
