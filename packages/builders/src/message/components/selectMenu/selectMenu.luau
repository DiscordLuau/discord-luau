--[=[
	@class Builders.Message.SelectMenu
	@__index Prototype

	Implementation of discords SelectMenu object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#SelectMenus
]=]

--[=[
	@prop defaultValues {Builders.Message.SelectMenuDefaultValue}
	@within Builders.Message.SelectMenu
	Array of default values for auto-populated select menu components
]=]

--[=[
	@prop options {Builders.Message.SelectMenuOption}
	@within Builders.Message.SelectMenu
	Array of select menu options
]=]

--[=[
	@prop apiTypes {api_types.ChannelType}
	@within Builders.Message.SelectMenu
	Array of channel types that can be selected
]=]

local apiTypes = require("../../../../luau_packages/api_types")

local defaultValue = require("./defaultValue")
local option = require("./option")

local SelectMenu = {}

SelectMenu.Prototype = {}
SelectMenu.Interface = {}

--[=[
	@within Builders.Message.SelectMenu

	Sets the type of select menu component to be created.
]=]
function SelectMenu.Prototype.setType(self: SelectMenu, selectMenuType: apiTypes.SelectMenuType): SelectMenu
	self.type = selectMenuType

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Sets a developer-defined identifier for the select menu.
]=]
function SelectMenu.Prototype.setCustomId(self: SelectMenu, customId: string): SelectMenu
	assert(#customId >= 1, "customId must be at least 1 character")
	assert(#customId <= 100, "customId must be at most 100 characters")

	self.customId = customId

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Sets custom placeholder text shown when no option is selected.
]=]
function SelectMenu.Prototype.setPlaceholder(self: SelectMenu, placeholder: string): SelectMenu
	assert(#placeholder <= 150, "placeholder must be at most 150 characters")

	self.placeholder = placeholder

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Sets the minimum number of items that must be selected.
]=]
function SelectMenu.Prototype.setMinValues(self: SelectMenu, minValueCount: number): SelectMenu
	assert(minValueCount >= 0 and minValueCount <= 25, "minValues must be between 0 and 25")

	self.minValues = minValueCount

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Sets the maximum number of items that can be selected.
]=]
function SelectMenu.Prototype.setMaxValues(self: SelectMenu, maxValueCount: number): SelectMenu
	assert(maxValueCount >= 1 and maxValueCount <= 25, "maxValues must be between 1 and 25")

	self.maxValues = maxValueCount

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Sets whether the select menu is disabled or not.
]=]
function SelectMenu.Prototype.setDisabled(self: SelectMenu, disabled: boolean): SelectMenu
	self.disabled = disabled

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Adds a default value to the select menu.
]=]
function SelectMenu.Prototype.addDefaultValue(self: SelectMenu, defaultValue: defaultValue.JSON): SelectMenu
	table.insert(self.defaultValues, defaultValue)

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Adds a channel type that can be selected in the menu.
]=]
function SelectMenu.Prototype.addChannelType(self: SelectMenu, channelType: apiTypes.ChannelType): SelectMenu
	table.insert(self.apiTypes, channelType)

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Adds an option to the select menu.
]=]
function SelectMenu.Prototype.addOption(self: SelectMenu, option: option.JSON): SelectMenu
	table.insert(self.options, option)

	return self
end

--[=[
	@within Builders.Message.SelectMenu

	Responsible for building the SelectMenu JSON that can be parsed by the Discord API.
]=]
function SelectMenu.Prototype.build(self: SelectMenu): JSON
	assert(self.type, "SelectMenu type is required")
	assert(self.customId, "SelectMenu customId is required")

	if self.minValues and self.maxValues then
		assert(self.maxValues >= self.minValues, "maxValues must be >= minValues")
	end

	return {
		type = apiTypes.channel.SelectMenuType[self.type],
		custom_id = self.customId,
		options = #self.options > 0 and self.options or nil,
		channel_types = #self.apiTypes > 0 and self.apiTypes or nil,
		placeholder = self.placeholder,
		default_values = #self.defaultValues > 0 and self.defaultValues or nil,
		min_values = self.minValues,
		max_values = self.maxValues,
		disabled = self.disabled,
	}
end

--[=[
	@within Builders.Message.SelectMenu

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
			defaultValues = {},

			options = {},

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
