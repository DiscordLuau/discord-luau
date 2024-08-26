--[[
	Implementation of the Application Command Option Structure in Luau.	

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure
]]

local apiTypes = require("@api-types/apiTypes")
local interactionTypes = require("@api-types/interaction")
local channelTypes = require("@api-types/channel")

local validateKebabCase = require("@utils/validateKebabCase")

local Option = {}

Option.Prototype = {}
Option.Interface = {}

--[[
	Set the Type of option that will be built.
]]
function Option.Prototype.setType(self: Option, type: interactionTypes.ApplicationCommandOptionType): Option
	self.type = type

	return self
end

--[[
	Set the name of this option, option name needs to be kebab case.
]]
function Option.Prototype.setName(self: Option, name: string): Option
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")

	validateKebabCase(name)

	self.name = name

	return self
end

--[[
	add a name localization for this option.
]]
function Option.Prototype.setNameLocalization(
	self: Option,
	localization: apiTypes.LanguageLocales,
	name: string
): Option
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")

	validateKebabCase(name)

	self.nameLocalizations[localization] = name

	return self
end

--[[
	set the description of this option.
]]
function Option.Prototype.setDescription(self: Option, description: string): Option
	assert(#description <= 100, "description must be less than 100 characters")
	assert(#description >= 1, "description must be at least 1 character")

	self.description = description

	return self
end

--[[
	add a description localization for this option.
]]
function Option.Prototype.setDescriptionLocalization(
	self: Option,
	localization: apiTypes.LanguageLocales,
	description: string
): Option
	assert(#description <= 100, "description must be less than 100 characters")
	assert(#description >= 1, "description must be at least 1 character")

	self.descriptionLocalizations[localization] = description

	return self
end

--[[
	set if the option is required, will not work on SubCommand or SubCommandGroup options.
]]
function Option.Prototype.setRequired(self: Option, isRequired: boolean): Option
	assert(
		self.type == "SubCommand" or self.type == "SubCommandGroup",
		`Required cannot be set on SubCommands, or SubCommandGroups`
	)

	self.required = isRequired

	return self
end

--[[
	add a choice to the option, will only work on String, Integer, or Number options.
]]
function Option.Prototype.addChoice(self: Option, choice: apiTypes.ApplicationCommandOptionChoiceObject): Option
	assert(
		self.type == "String" or self.type == "Integer" or self.type == "Number",
		"Choices can only be added to String, Integer, or Number options"
	)

	table.insert(self.choices, choice)

	return self
end

--[[
	add an option to the option, will only work on SubCommand or SubCommandGroup options.
]]
function Option.Prototype.addOption(self: Option, option: apiTypes.ApplicationCommandOptionObject): Option
	assert(
		self.type == "SubCommand" or self.type == "SubCommandGroup",
		`Options can only be added to SubCommands, or SubCommandGroups`
	)

	table.insert(self.options, option)

	return self
end

--[[
	add supported channel types, will only work on Channel options.
]]
function Option.Prototype.addChannelType(self: Option, channelType: channelTypes.ChannelType): Option
	assert(self.type == "Channel", `Channel types can only be added to Channel options`)

	table.insert(self.channelTypes, channelType)

	return self
end

--[[
	set the min value of this option, will only work on Integer or Number options.
]]
function Option.Prototype.setMinValue(self: Option, value: number): Option
	assert(self.type == "Integer" or self.type == "Number", "Min values can only be set on Integer or Number options")

	self.minValue = value

	return self
end

--[[
	set the max value of this option, will only work on Integer or Number options.
]]
function Option.Prototype.setMaxValue(self: Option, value: number): Option
	assert(self.type == "Integer" or self.type == "Number", "Min values can only be set on Integer or Number options")

	self.maxValue = value

	return self
end

--[[
	set the min length of this option, will only work on String options.
]]
function Option.Prototype.setMinLength(self: Option, value: number): Option
	assert(self.type == "String", "Min values can only be set on String options")

	self.minLength = value

	return self
end

--[[
	set the max length of this option, will only work on String options.
]]
function Option.Prototype.setMaxLength(self: Option, value: number): Option
	assert(self.type == "String", "Max values can only be set on String options")

	self.maxLength = value

	return self
end

--[[
	If autocomplete interactions are enabled for this option, will only work on String, Integer, or Number options.
]]
function Option.Prototype.setAutocompleteEnabled(self: Option, autocompleteEnabled: boolean): Option
	assert(
		self.type == "String" or self.type == "Integer" or self.type == "Number",
		`Autocomplete can only be set on String, Integer, or Number options`
	)

	self.autocomplete = autocompleteEnabled

	return self
end

--[[
	Responsible for buillding the default reaction object that the Discord API can understand.
]]
function Option.Prototype.build(self: Option): apiTypes.ApplicationCommandOptionObject
	local channelTypeArray = {}

	for _, channelType in self.channelTypes do
		table.insert(channelTypeArray, channelTypes.ChannelTypes[channelType])
	end

	assert(self.name, `Missing name for option: {self.name}`)
	assert(self.description, `Missing description for option: {self.name}`)

	return {
		type = interactionTypes.InteractionType[self.type],
		channelTypes = channelTypeArray,

		name = self.name,
		nameLocalizations = self.nameLocalizations,
		description = self.description,
		descriptionLocalizations = self.descriptionLocalizations,
		required = self.required,
		choices = self.choices,
		options = self.options,
		minValue = self.minValue,
		maxValue = self.maxValue,
		minLength = self.minLength,
		maxLength = self.maxLength,
		autocomplete = self.autocomplete,
	}
end

--[[
	Constructor for the Discord Default Reaction Builder.

	```lua
	local defaultReaction = Option.new("000000000000000000", "secret-emoji"):build()
	```
]]
function Option.Interface.new(resource: {
	type: interactionTypes.ApplicationCommandOptionType?,
	name: string?,
	nameLocalizations: { [apiTypes.LanguageLocales]: string }?,
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string }?,
	required: boolean?,
	choices: { apiTypes.ApplicationCommandOptionChoiceObject }?,
	options: { apiTypes.ApplicationCommandOptionObject }?,
	channelTypes: { apiTypes.ChannelType }?,
	minValue: number?,
	maxValue: number?,
	minLength: number?,
	maxLength: number?,
	autocomplete: boolean?,
}?): Option
	local self = setmetatable(
		{
			type = resource and resource.type,
			name = resource and resource.name,
			nameLocalizations = resource and resource.nameLocalizations or {},
			description = resource and resource.description,
			descriptionLocalizations = resource and resource.descriptionLocalizations or {},
			required = resource and resource.required,
			choices = resource and resource.choices or {},
			options = resource and resource.options or {},
			channelTypes = resource and resource.channelTypes or {},
			minValue = resource and resource.minValue,
			maxValue = resource and resource.maxValue,
			minLength = resource and resource.minLength,
			maxLength = resource and resource.maxLength,
			autocomplete = resource and resource.autocomplete,
		} :: Option,
		{ __index = Option.Prototype }
	)

	return self
end

export type Option = typeof(Option.Prototype) & {
	type: interactionTypes.ApplicationCommandOptionType?,
	name: string?,
	nameLocalizations: { [apiTypes.LanguageLocales]: string },
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string },
	required: boolean?,
	choices: { apiTypes.ApplicationCommandOptionChoiceObject },
	options: { apiTypes.ApplicationCommandOptionObject },
	channelTypes: { channelTypes.ChannelType },
	minValue: number?,
	maxValue: number?,
	minLength: number?,
	maxLength: number?,
	autocomplete: boolean?,
}

return Option.Interface
