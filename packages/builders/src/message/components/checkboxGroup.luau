--[=[
	@class Builders.Message.CheckboxGroup
	@__index Prototype

	Implementation of Discord's Checkbox Group component as a Luau builder.
	Multi-selectable group of checkboxes. Modal-only when using the required field.

	https://docs.discord.com/developers/components/reference#checkbox-group
]=]

--[=[
	@prop customId string?
	@within Builders.Message.CheckboxGroup
	Developer-defined identifier; 1-100 characters.
]=]

--[=[
	@prop options { apiTypes.RadioGroupOptionObject }
	@within Builders.Message.CheckboxGroup
	Array of checkbox options; max 10.
]=]

--[=[
	@prop required boolean?
	@within Builders.Message.CheckboxGroup
	Whether required in modal (defaults to true).
]=]

local apiTypes = require("../../../luau_packages/api_types")

local CheckboxGroup = {}

CheckboxGroup.Prototype = {}
CheckboxGroup.Interface = {}

--[=[
	@within Builders.Message.CheckboxGroup

	Sets the developer-defined identifier. 1-100 characters.
]=]
function CheckboxGroup.Prototype.setCustomId(self: CheckboxGroup, customId: string): CheckboxGroup
	assert(#customId >= 1, "customId must be at least 1 character")
	assert(#customId <= 100, "customId must be at most 100 characters")

	self.customId = customId

	return self
end

--[=[
	@within Builders.Message.CheckboxGroup

	Adds a checkbox option. Max 10 options.
]=]
function CheckboxGroup.Prototype.addOption(
	self: CheckboxGroup,
	label: string,
	value: string,
	description: string?,
	emoji: apiTypes.EmojiObject?,
	default: boolean?
): CheckboxGroup
	assert(#self.options < 10, "checkbox groups cannot have more than 10 options")

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
	@within Builders.Message.CheckboxGroup

	Sets whether this component is required in a modal.
]=]
function CheckboxGroup.Prototype.setRequired(self: CheckboxGroup, required: boolean): CheckboxGroup
	self.required = required

	return self
end

--[=[
	@within Builders.Message.CheckboxGroup

	Responsible for building the CheckboxGroup JSON that can be parsed by the Discord API.
]=]
function CheckboxGroup.Prototype.build(self: CheckboxGroup): JSON
	assert(self.customId, "CheckboxGroup.customId is required")
	assert(#self.options >= 1, "checkbox groups must have at least 1 option")

	return {
		type = 22,
		custom_id = self.customId,
		options = self.options,
		required = self.required,
	}
end

--[=[
	@within Builders.Message.CheckboxGroup

	Responsible for creating a new CheckboxGroup.
]=]
function CheckboxGroup.Interface.new(): CheckboxGroup
	local self = setmetatable(
		{
			options = {},
		} :: CheckboxGroup,
		{
			__index = CheckboxGroup.Prototype,
		}
	)

	return self
end

export type CheckboxGroup = typeof(CheckboxGroup.Prototype) & {
	customId: string?,
	options: { apiTypes.RadioGroupOptionObject },
	required: boolean?,
}

export type JSON = apiTypes.CheckboxGroupComponentObject

return CheckboxGroup.Interface
