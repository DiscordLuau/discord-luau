--[=[
	@class Builders.Option
	@__index Prototype

	Implementation of discords Option object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#Options
]=]

local emoji = require("../../../emoji")

local Option = {}

Option.Prototype = {}
Option.Interface = {}

--[=[
	@within Builders.Option

	Sets the user-facing name of the option.
]=]
function Option.Prototype.setLabel(self: Option, label: string): Option
	assert(#label <= 100, `Label must be less than 80 characters.`)
	assert(#label > 0, `Label must be more than 0 characters.`)

	self.label = label

	return self
end

--[=[
	@within Builders.Option

	Sets the dev-defined value of the option.
]=]
function Option.Prototype.setValue(self: Option, value: string): Option
	assert(#value <= 100, `Value must be less than 80 characters.`)
	assert(#value > 0, `Value must be more than 0 characters.`)

	self.value = value

	return self
end

--[=[
	@within Builders.Option

	Sets an additional description of the option.
]=]
function Option.Prototype.setDescription(self: Option, description: string): Option
	assert(#description <= 100, `Description( must be less than 80 characters.`)
	assert(#description > 0, `Description( must be more than 0 characters.`)

	self.description = description

	return self
end

--[=[
	@within Builders.Option

	Sets an emoji to display alongside the option.
]=]
function Option.Prototype.setEmoji(self: Option, emoji: emoji.JSON): Option
	self.emoji = emoji

	return self
end

--[=[
	@within Builders.Option

	Sets whether this option is selected by default.
]=]
function Option.Prototype.setDefault(self: Option, default: boolean): Option
	self.default = default

	return self
end

--[=[
	@within Builders.Option

	Responsible for building the Option JSON that can be parsed by the Discord API.
]=]
function Option.Prototype.build(self: Option): JSON
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

--[=[
	@within Builders.Option

	Responsible for creating a new Option.

	```luau
	local option = Option.new({
		label = "My Option",
		value = "option_value",
		description = "A description",
		default = false
	})
	```
]=]
function Option.Interface.new(resource: {
	label: string?,
	value: string?,
	description: string?,
	emoji: emoji.JSON?,
	default: boolean?,
}): Option
	local self = setmetatable(
		{
			--[=[
				@prop label string?
				@within Builders.Option
				The user-facing name of the option.
			]=]
			label = nil,

			--[=[
				@prop value string?
				@within Builders.Option
				The dev-defined value of the option.
			]=]
			value = nil,

			--[=[
				@prop description string?
				@within Builders.Option
				An additional description of the option.
			]=]
			description = nil,

			--[=[
				@prop emoji Builders.Emoji?
				@within Builders.Option
				The emoji to display alongside the option.
			]=]
			emoji = nil,

			--[=[
				@prop default boolean?
				@within Builders.Option
				Whether this option is selected by default.
			]=]
			default = nil,
		} :: Option,
		{
			__index = Option.Prototype,
		}
	)

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

export type Option = typeof(Option.Prototype) & {
	label: string?,
	value: string?,
	description: string?,
	emoji: emoji.JSON?,
	default: boolean?,
}

export type JSON = typeof(Option.Prototype.build(nil :: any))

return Option.Interface
