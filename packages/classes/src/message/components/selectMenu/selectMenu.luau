--[[
	Implementation of the Discord SelectMenu class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-menu-structure
]]

local apiTypes = require("../../../../lune_packages/api_types")

local option = require("./option")
local defaultValue = require("./defaultValue")

local SelectMenu = {}

SelectMenu.Interface = {}
SelectMenu.Prototype = {}

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
