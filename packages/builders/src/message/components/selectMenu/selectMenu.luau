--[[
	Implementation of discords SelectMenu object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#SelectMenus
]]

local channelTypes = require("@api-types/channel")

local defaultValue = require("@builders/message/components/selectMenu/defaultValue")
local option = require("@builders/message/components/selectMenu/option")

local SelectMenu = {}

SelectMenu.Prototype = {}
SelectMenu.Interface = {}

--[[
	
]]
function SelectMenu.Prototype.setCustomId(self: SelectMenu, customId: string): SelectMenu
	self.customId = customId

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setPlaceholder(self: SelectMenu, placeholder: string): SelectMenu
	self.placeholder = placeholder

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setMinValues(self: SelectMenu, minValueCount: number): SelectMenu
	self.minValues = minValueCount

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setMaxValues(self: SelectMenu, maxValueCount: number): SelectMenu
	self.maxValues = maxValueCount

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setDisabled(self: SelectMenu, disabled: boolean): SelectMenu
	self.disabled = disabled

	return self
end

--[[
	
]]
function SelectMenu.Prototype.addDefaultValue(self: SelectMenu, defaultValue: defaultValue.JSON): SelectMenu
	table.insert(self.defaultValues, defaultValue)

	return self
end

--[[
	
]]
function SelectMenu.Prototype.addChannelType(self: SelectMenu, channelType: channelTypes.ChannelType): SelectMenu
	table.insert(self.channelTypes, channelType)

	return self
end

--[[
	
]]
function SelectMenu.Prototype.addOption(self: SelectMenu, option: option.JSON): SelectMenu
	table.insert(self.options, option)

	return self
end

--[[
	Responsible for building the SelectMenu JSON that can be parsed by the Discord API.
]]
function SelectMenu.Prototype.build(self: SelectMenu): JSON
	return {
		custom_id = self.customId,
		options = self.options,
		channel_types = self.channelTypes,
		placeholder = self.placeholder,
		default_values = self.defaultValues,
		min_values = self.minValues,
		max_values = self.maxValues,
		disabled = self.disabled,
	}
end

--[[
	Responsible for creating a new SelectMenu.

	```lua
	
	```
]]
function SelectMenu.Interface.new(resource: {
	customId: string?,
	options: { option.JSON },
	channelTypes: { channelTypes.ChannelType },
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
			channelTypes = {},
		} :: SelectMenu,
		{
			__index = SelectMenu.Prototype,
		}
	)

	if resource then
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

		if resource.channelTypes then
			for _, channelType: channelTypes.ChannelType in resource.channelTypes do
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
	customId: string?,
	options: { option.JSON },
	channelTypes: { channelTypes.ChannelType },
	placeholder: string?,
	defaultValues: { defaultValue.JSON },
	minValues: number?,
	maxValues: number?,
	disabled: boolean?,
}

export type JSON = typeof(SelectMenu.Prototype.build(nil :: any))

return SelectMenu.Interface
