--[=[
	@class Builders.Interaction.Option
	@__index Prototype

	Implementation of the Application Command Option Structure in Luau.

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure
]=]

local apiTypes = require("../../lune_packages/api_types")
local interactionChoice = require("./choice")
local util = require("../../lune_packages/util")

local Option = {}

Option.Prototype = {}
Option.Interface = {}

--[=[
	@within Builders.Interaction.Option

	Set the Type of option that will be built.
]=]
function Option.Prototype.setType(self: Option, type: apiTypes.ApplicationCommandOptionType): Option
	self.type = type
	return self
end

--[=[
	@within Builders.Interaction.Option

	Set the name of this option, option name needs to be kebab case.
]=]
function Option.Prototype.setName(self: Option, name: string): Option
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")
	assert(util.validateKebabCase(name), `name must be kebab case`)
	self.name = name
	return self
end

--[=[
	@within Builders.Interaction.Option

	Add a name localization for this option.
]=]
function Option.Prototype.setNameLocalization(
	self: Option,
	localization: apiTypes.LanguageLocales,
	name: string
): Option
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")
	assert(util.validateKebabCase(name), `name must be kebab case`)
	self.nameLocalizations[localization] = name
	return self
end

--[=[
	@within Builders.Interaction.Option

	Set the description of this option.
]=]
function Option.Prototype.setDescription(self: Option, description: string): Option
	assert(#description <= 100, "description must be less than 100 characters")
	assert(#description >= 1, "description must be at least 1 character")
	self.description = description
	return self
end

--[=[
	@within Builders.Interaction.Option

	Add a description localization for this option.
]=]
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

--[=[
	@within Builders.Interaction.Option

	Set if the option is required, will not work on SubCommand or SubCommandGroup options.
]=]
function Option.Prototype.setRequired(self: Option, isRequired: boolean): Option
	assert(
		self.type == "SubCommand" or self.type == "SubCommandGroup",
		`Required cannot be set on SubCommands, or SubCommandGroups`
	)
	self.required = isRequired
	return self
end

--[=[
	@within Builders.Interaction.Option

	Add a choice to the option, will only work on String, Integer, or Number options.
]=]
function Option.Prototype.addChoice(self: Option, choice: interactionChoice.JSON): Option
	assert(
		self.type == "String" or self.type == "Integer" or self.type == "Number",
		"Choices can only be added to String, Integer, or Number options"
	)
	table.insert(self.choices, choice)
	return self
end

--[=[
	@within Builders.Interaction.Option

	Add an option to the option, will only work on SubCommand or SubCommandGroup options.
]=]
function Option.Prototype.addOption(self: Option, option: JSON): Option
	assert(
		self.type == "SubCommand" or self.type == "SubCommandGroup",
		`Options can only be added to SubCommands, or SubCommandGroups`
	)
	table.insert(self.options, option)
	return self
end

--[=[
	@within Builders.Interaction.Option

	Add supported channel types, will only work on Channel options.
]=]
function Option.Prototype.addChannelType(self: Option, channelType: apiTypes.ChannelType): Option
	assert(self.type == "Channel", `Channel types can only be added to Channel options`)
	table.insert(self.apiTypes, channelType)
	return self
end

--[=[
	@within Builders.Interaction.Option

	Set the min value of this option, will only work on Integer or Number options.
]=]
function Option.Prototype.setMinValue(self: Option, value: number): Option
	assert(self.type == "Integer" or self.type == "Number", "Min values can only be set on Integer or Number options")
	self.minValue = value
	return self
end

--[=[
	@within Builders.Interaction.Option

	Set the max value of this option, will only work on Integer or Number options.
]=]
function Option.Prototype.setMaxValue(self: Option, value: number): Option
	assert(self.type == "Integer" or self.type == "Number", "Min values can only be set on Integer or Number options")
	self.maxValue = value
	return self
end

--[=[
	@within Builders.Interaction.Option

	Set the min length of this option, will only work on String options.
]=]
function Option.Prototype.setMinLength(self: Option, value: number): Option
	assert(self.type == "String", "Min values can only be set on String options")
	self.minLength = value
	return self
end

--[=[
	@within Builders.Interaction.Option

	Set the max length of this option, will only work on String options.
]=]
function Option.Prototype.setMaxLength(self: Option, value: number): Option
	assert(self.type == "String", "Max values can only be set on String options")
	self.maxLength = value
	return self
end

--[=[
	@within Builders.Interaction.Option

	If autocomplete interactions are enabled for this option, will only work on String, Integer, or Number options.
]=]
function Option.Prototype.setAutocompleteEnabled(self: Option, autocompleteEnabled: boolean): Option
	assert(
		self.type == "String" or self.type == "Integer" or self.type == "Number",
		`Autocomplete can only be set on String, Integer, or Number options`
	)
	self.autocomplete = autocompleteEnabled
	return self
end

--[=[
	@within Builders.Interaction.Option

	Responsible for building the option object that the Discord API can understand.
]=]
function Option.Prototype.build(self: Option): JSON
	local channelTypeArray = {}
	for _, channelType in self.apiTypes do
		table.insert(channelTypeArray, apiTypes.channel.ChannelTypes[channelType])
	end

	assert(self.name, `Missing name for option: {self.name}`)
	assert(self.description, `Missing description for option: {self.name}`)

	return {
		type = apiTypes.interaction.InteractionType[self.type],
		channel_types = channelTypeArray,
		name = self.name,
		name_localizations = self.nameLocalizations,
		description = self.description,
		description_localizations = self.descriptionLocalizations,
		required = self.required,
		choices = self.choices,
		options = self.options,
		min_value = self.minValue,
		max_value = self.maxValue,
		min_length = self.minLength,
		max_length = self.maxLength,
		autocomplete = self.autocomplete,
	}
end

--[=[
	@within Builders.Interaction.Option

	Constructor for the Discord Default Reaction Builder.
]=]
function Option.Interface.new(resource: {
	type: apiTypes.ApplicationCommandOptionType?,
	name: string?,
	nameLocalizations: { [apiTypes.LanguageLocales]: string }?,
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string }?,
	required: boolean?,
	choices: { apiTypes.ApplicationCommandOptionChoiceObject }?,
	options: { JSON }?,
	apiTypes: { apiTypes.ChannelType }?,
	minValue: number?,
	maxValue: number?,
	minLength: number?,
	maxLength: number?,
	autocomplete: boolean?,
}?): Option
	--[=[
		@prop type apiTypes.ApplicationCommandOptionType?
		@within Builders.Interaction.Option
		The type of option (e.g., String, Integer, SubCommand).
	]=]
	--[=[
		@prop name string?
		@within Builders.Interaction.Option
		The name of the option.
	]=]
	--[=[
		@prop nameLocalizations { [apiTypes.LanguageLocales]: string }
		@within Builders.Interaction.Option
		Name localizations for different language locales.
	]=]
	--[=[
		@prop description string?
		@within Builders.Interaction.Option
		The description of the option.
	]=]
	--[=[
		@prop descriptionLocalizations { [apiTypes.LanguageLocales]: string }
		@within Builders.Interaction.Option
		Description localizations for different language locales.
	]=]
	--[=[
		@prop required boolean?
		@within Builders.Interaction.Option
		Whether this option is required to be set by the user.
	]=]
	--[=[
		@prop choices { Builders.Choice.JSON }
		@within Builders.Interaction.Option
		Possible choices for this option (String, Integer, or Number types only).
	]=]
	--[=[
		@prop options { Builders.Interaction.Option.JSON }
		@within Builders.Interaction.Option
		Sub-options for this option (SubCommand or SubCommandGroup only).
	]=]
	--[=[
		@prop apiTypes { apiTypes.ChannelType }
		@within Builders.Interaction.Option
		Supported channel types for Channel option type.
	]=]
	--[=[
		@prop minValue number?
		@within Builders.Interaction.Option
		Minimum value allowed for the option (Integer/Number only).
	]=]
	--[=[
		@prop maxValue number?
		@within Builders.Interaction.Option
		Maximum value allowed for the option (Integer/Number only).
	]=]
	--[=[
		@prop minLength number?
		@within Builders.Interaction.Option
		Minimum string length for the option (String only).
	]=]
	--[=[
		@prop maxLength number?
		@within Builders.Interaction.Option
		Maximum string length for the option (String only).
	]=]
	--[=[
		@prop autocomplete boolean?
		@within Builders.Interaction.Option
		Whether autocomplete is enabled (String, Integer, or Number types only).
	]=]

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
			apiTypes = resource and resource.apiTypes or {},
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
	type: apiTypes.ApplicationCommandOptionType?,
	name: string?,
	nameLocalizations: { [apiTypes.LanguageLocales]: string },
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string },
	required: boolean?,
	choices: { interactionChoice.JSON },
	options: { JSON },
	apiTypes: { apiTypes.ChannelType },
	minValue: number?,
	maxValue: number?,
	minLength: number?,
	maxLength: number?,
	autocomplete: boolean?,
}

export type JSON = typeof(Option.Prototype.build(nil :: any))

return Option.Interface
