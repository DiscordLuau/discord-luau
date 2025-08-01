--[=[
	@class Classes.SelectMenuOption
	@__index Prototype

	Implementation of the Discord Option class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-menu-structure
]=]

local apiTypes = require("../../../../lune_packages/api_types")

local emoji = require("../../../emoji")

local Option = {}

Option.Interface = {}
Option.Prototype = {}

--[=[
	@within Classes.SelectMenuOption
	@private

	Responsible for syncing data to this option object. This is typically called by the API when this object is
	created or updated.
]=]
function Option.Prototype.sync(self: Option, optionData: apiTypes.SelectOptionObject)
	--[=[
		@prop label string
		@within Classes.SelectMenuOption
		The text that appears on the select menu option
	]=]
	self.label = optionData.label

	--[=[
		@prop value string
		@within Classes.SelectMenuOption
		The value that will be sent when this option is selected
	]=]
	self.value = optionData.value

	--[=[
		@prop description string?
		@within Classes.SelectMenuOption
		Additional descriptive text that appears below the label
	]=]
	self.description = optionData.description

	--[=[
		@prop emoji Classes.Emoji?
		@within Classes.SelectMenuOption
		The emoji that appears next to the option label
	]=]
	self.emoji = optionData.emoji and emoji.new(optionData.emoji)

	--[=[
		@prop default boolean?
		@within Classes.SelectMenuOption
		Whether this option is selected by default
	]=]
	self.default = optionData.default
end

--[=[
	@within Classes.SelectMenuOption
	@private

	Responsible for constructing this class.
]=]
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
