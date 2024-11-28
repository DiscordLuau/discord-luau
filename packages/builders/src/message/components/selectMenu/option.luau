--[[
	Implementation of discords SelectMenu object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#SelectMenus
]]

local emoji = require("../../../emoji")

local SelectMenu = {}

SelectMenu.Prototype = {}
SelectMenu.Interface = {}

--[[
	
]]
function SelectMenu.Prototype.setLabel(self: SelectMenu, label: string): SelectMenu
	assert(#label <= 100, `Label must be less than 80 characters.`)
	assert(#label > 0, `Label must be more than 0 characters.`)

	self.label = label

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setValue(self: SelectMenu, value: string): SelectMenu
	assert(#value <= 100, `Value must be less than 80 characters.`)
	assert(#value > 0, `Value must be more than 0 characters.`)

	self.value = value

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setDescription(self: SelectMenu, description: string): SelectMenu
	assert(#description <= 100, `Description( must be less than 80 characters.`)
	assert(#description > 0, `Description( must be more than 0 characters.`)

	self.description = description

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setEmoji(self: SelectMenu, emoji: emoji.JSON): SelectMenu
	self.emoji = emoji

	return self
end

--[[
	
]]
function SelectMenu.Prototype.setDefault(self: SelectMenu, default: boolean): SelectMenu
	self.default = default

	return self
end

--[[
	Responsible for building the SelectMenu JSON that can be parsed by the Discord API.
]]
function SelectMenu.Prototype.build(self: SelectMenu): JSON
	assert(self.label, `Label is required`)
	assert(self.value, `Value is required`)
	assert(self.default ~= nil, `Default is required`)

	return {
		label = self.label,
		value = self.value,
		description = self.description,
		emoji = self.emoji,
		default = self.default,
	}
end

--[[
	Responsible for creating a new SelectMenu.

	```lua
	
	```
]]
function SelectMenu.Interface.new(resource: {
	label: string?,
	value: string?,
	description: string?,
	emoji: emoji.JSON?,
	default: boolean?,
}): SelectMenu
	local self = setmetatable({} :: SelectMenu, {
		__index = SelectMenu.Prototype,
	})

	if resource then
		if resource.label then
			self:setLabel(resource.label)
		end

		if resource.value then
			self:setValue(resource.value)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.emoji then
			self:setEmoji(resource.emoji)
		end

		if resource.default ~= nil then
			self:setDefault(resource.default)
		end
	end

	return self
end

export type SelectMenu = typeof(SelectMenu.Prototype) & {
	label: string?,
	value: string?,
	description: string?,
	emoji: emoji.JSON?,
	default: boolean?,
}

export type JSON = typeof(SelectMenu.Prototype.build(nil :: any))

return SelectMenu.Interface
