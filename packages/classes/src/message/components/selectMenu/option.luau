--[[
	Implementation of the Discord Option class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-menu-structure
]]

local apiTypes = require("../../../../lune_packages/api_types")

local emoji = require("../../../emoji")

local Option = {}

Option.Interface = {}
Option.Prototype = {}

function Option.Prototype.sync(self: Option, optionData: apiTypes.SelectOptionObject)
	self.label = optionData.label
	self.value = optionData.value
	self.description = optionData.description
	self.emoji = optionData.emoji and emoji.new(optionData.emoji)
	self.default = optionData.default
end

function Option.Interface.new(optionData: apiTypes.SelectOptionObject): Option
	local self = setmetatable({} :: Option, { __index = Option.Prototype })

	self:sync(optionData)

	return self
end

export type Option = typeof(Option.Prototype) & {
	label: string,
	value: string,
	description: string?,
	emoji: emoji.Emoji?,
	default: boolean?,
}

return Option.Interface
