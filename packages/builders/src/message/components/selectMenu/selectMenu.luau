--[=[
	@class Builders.SelectMenu
	@__index Prototype

	Implementation of discords SelectMenu object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#SelectMenus
]=]

local apiTypes = require("../../../../lune_packages/api_types")

local defaultValue = require("./defaultValue")
local option = require("./option")

local SelectMenu = {}

SelectMenu.Prototype = {}
SelectMenu.Interface = {}

--[=[
	@within Builders.SelectMenu

	Sets the type of select menu component to be created.
]=]
function SelectMenu.Prototype.setType(self: SelectMenu, selectMenuType: apiTypes.SelectMenuType): SelectMenu
	self.type = selectMenuType

	return self
end

--[=[
	@within Builders.SelectMenu

	Sets a developer-defined identifier for the select menu.
]=]
function SelectMenu.Prototype.setCustomId(self: SelectMenu, customId: string): SelectMenu
	self.customId = customId

	return self
end

--[=[
	@within Builders.SelectMenu

	Sets custom placeholder text shown when no option is selected.
]=]
function SelectMenu.Prototype.setPlaceholder(self: SelectMenu, placeholder: string): SelectMenu
	self.placeholder = placeholder

	return self
end

--[=[
	@within Builders.SelectMenu

	Sets the minimum number of items that must be selected.
]=]
function SelectMenu.Prototype.setMinValues(self: SelectMenu, minValueCount: number): SelectMenu
	self.minValues = minValueCount

	return self
end

--[=[
	@within Builders.SelectMenu

	Sets the maximum number of items that can be selected.
]=]
function SelectMenu.Prototype.setMaxValues(self: SelectMenu, maxValueCount: number): SelectMenu
	self.maxValues = maxValueCount

	return self
end

--[=[
	@within Builders.SelectMenu

	Sets whether the select menu is disabled or not.
]=]
function SelectMenu.Prototype.setDisabled(self: SelectMenu, disabled: boolean): SelectMenu
	self.disabled = disabled

	return self
end

--[=[
	@within Builders.SelectMenu

	Adds a default value to the select menu.
]=]
function SelectMenu.Prototype.addDefaultValue(self: SelectMenu, defaultValue: defaultValue.JSON): SelectMenu
	table.insert(self.defaultValues, defaultValue)

	return self
end

--[=[
	@within Builders.SelectMenu

	Adds a channel type that can be selected in the menu.
]=]
function SelectMenu.Prototype.addChannelType(self: SelectMenu, channelType: apiTypes.ChannelType): SelectMenu
	table.insert(self.apiTypes, channelType)

	return self
end

--[=[
	@within Builders.SelectMenu

	Adds an option to the select menu.
]=]
function SelectMenu.Prototype.addOption(self: SelectMenu, option: option.JSON): SelectMenu
	table.insert(self.options, option)

	return self
end

--[=[
	@within Builders.SelectMenu

	Responsible for building the SelectMenu JSON that can be parsed by the Discord API.
]=]
function SelectMenu.Prototype.build(self: SelectMenu): JSON
	assert(self.type, "SelectMenu type is required")
	assert(self.customId, "SelectMenu customId is required")

	return {
		type = apiTypes.channel.SelectMenuType[self.type],
		custom_id = self.customId,
		options = self.options,
		channel_types = self.apiTypes,
		placeholder = self.placeholder,
		default_values = self.defaultValues,
		min_values = self.minValues,
		max_values = self.maxValues,
		disabled = self.disabled,
	}
end

--[=[
	@within Builders.SelectMenu

	Responsible for creating a new SelectMenu.
]=]
function SelectMenu.Interface.new(resource: {
	type: apiTypes.SelectMenuType?,
	customId: string?,
	options: { option.JSON },
	apiTypes: { apiTypes.ChannelType },
	placeholder: string?,
	defaultValues: { defaultValue.JSON },
	minValues: number?,
	maxValues: number?,
	disabled: boolean?,
}?): SelectMenu
	local self = setmetatable(
		{
			--[=[
				@prop defaultValues {Builders.DefaultValue}
				@within Builders.SelectMenu
				Array of default values for auto-populated select menu components
			]=]
			defaultValues = {},

			--[=[
				@prop options {Builders.Option}
				@within Builders.SelectMenu
				Array of select menu options
			]=]
			options = {},

			--[=[
				@prop apiTypes {api_types.ChannelType}
				@within Builders.SelectMenu
				Array of channel types that can be selected
			]=]
			apiTypes = {},
		} :: SelectMenu,
		{
			__index = SelectMenu.Prototype,
		}
	)

	if resource then
		if resource.type then
			self:setType(resource.type)
		end

		if resource.customId then
			self:setCustomId(resource.customId)
		end

		if resource.placeholder then
			self:setPlaceholder(resource.placeholder)
		end

		if resource.minValues then
			self:setMinValues(resource.minValues)
		end

		if resource.maxValues then
			self:setMaxValues(resource.maxValues)
		end

		if resource.disabled ~= nil then
			self:setDisabled(resource.disabled)
		end

		if resource.options then
			for _, option in resource.options do
				self:addOption(option)
			end
		end

		if resource.apiTypes then
			for _, channelType: apiTypes.ChannelType in resource.apiTypes do
				self:addChannelType(channelType)
			end
		end

		if resource.defaultValues then
			for _, defaultValue in resource.defaultValues do
				self:addDefaultValue(defaultValue)
			end
		end
	end

	return self
end

export type SelectMenu = typeof(SelectMenu.Prototype) & {
	type: apiTypes.SelectMenuType?,
	customId: string?,
	options: { option.JSON },
	apiTypes: { apiTypes.ChannelType },
	placeholder: string?,
	defaultValues: { defaultValue.JSON },
	minValues: number?,
	maxValues: number?,
	disabled: boolean?,
}

export type JSON = typeof(SelectMenu.Prototype.build(nil :: any))

return SelectMenu.Interface
