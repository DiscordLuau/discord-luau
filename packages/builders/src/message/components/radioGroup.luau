--[=[
	@class Builders.Message.RadioGroup
	@__index Prototype

	Implementation of Discord's Radio Group component as a Luau builder.
	Single-choice set of options. Modal-only when using the required field.

	https://docs.discord.com/developers/components/reference#radio-group
]=]

--[=[
	@prop customId string?
	@within Builders.Message.RadioGroup
	Developer-defined identifier; 1-100 characters.
]=]

--[=[
	@prop options { apiTypes.RadioGroupOptionObject }
	@within Builders.Message.RadioGroup
	Array of radio options; max 10.
]=]

--[=[
	@prop required boolean?
	@within Builders.Message.RadioGroup
	Whether required in modal (defaults to true).
]=]

local apiTypes = require("../../../luau_packages/api_types")

local RadioGroup = {}

RadioGroup.Prototype = {}
RadioGroup.Interface = {}

--[=[
	@within Builders.Message.RadioGroup

	Sets the developer-defined identifier. 1-100 characters.
]=]
function RadioGroup.Prototype.setCustomId(self: RadioGroup, customId: string): RadioGroup
	assert(#customId >= 1, "customId must be at least 1 character")
	assert(#customId <= 100, "customId must be at most 100 characters")

	self.customId = customId

	return self
end

--[=[
	@within Builders.Message.RadioGroup

	Adds a radio option. Max 10 options.
]=]
function RadioGroup.Prototype.addOption(
	self: RadioGroup,
	label: string,
	value: string,
	description: string?,
	emoji: apiTypes.EmojiObject?,
	default: boolean?
): RadioGroup
	assert(#self.options < 10, "radio groups cannot have more than 10 options")

	table.insert(self.options, {
		label = label,
		value = value,
		description = description,
		emoji = emoji,
		default = default,
	})

	return self
end

--[=[
	@within Builders.Message.RadioGroup

	Sets whether this component is required in a modal.
]=]
function RadioGroup.Prototype.setRequired(self: RadioGroup, required: boolean): RadioGroup
	self.required = required

	return self
end

--[=[
	@within Builders.Message.RadioGroup

	Responsible for building the RadioGroup JSON that can be parsed by the Discord API.
]=]
function RadioGroup.Prototype.build(self: RadioGroup): JSON
	assert(self.customId, "RadioGroup.customId is required")
	assert(#self.options >= 1, "radio groups must have at least 1 option")

	return {
		type = 21,
		custom_id = self.customId,
		options = self.options,
		required = self.required,
	}
end

--[=[
	@within Builders.Message.RadioGroup

	Responsible for creating a new RadioGroup.
]=]
function RadioGroup.Interface.new(): RadioGroup
	local self = setmetatable(
		{
			options = {},
		} :: RadioGroup,
		{
			__index = RadioGroup.Prototype,
		}
	)

	return self
end

export type RadioGroup = typeof(RadioGroup.Prototype) & {
	customId: string?,
	options: { apiTypes.RadioGroupOptionObject },
	required: boolean?,
}

export type JSON = apiTypes.RadioGroupComponentObject

return RadioGroup.Interface
