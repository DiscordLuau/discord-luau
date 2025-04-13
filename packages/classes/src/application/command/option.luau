--[=[
	@class Classes.CommandOption
	@__index Prototype

	Implementation of the Discord Option class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local choice = require("./choice")

local Option = {}

Option.Interface = {}
Option.Prototype = {}

--[=[
	@within Classes.CommandOption
	@private

	Responsible for syncing data to this option object. This is typically called by the API when this object is
	created or updated.
]=]
function Option.Prototype.sync(self: Option, optionData: apiTypes.ApplicationCommandOptionObject)
	local choiceArray = {}
	local optionArray = {}

	local channelTypeArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, choiceData in next, optionData.choices or {} do
		table.insert(choiceArray, choice.new(choiceData))
	end

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, optionData in next, optionData.options or {} do
		table.insert(optionArray, Option.Interface.new(optionData))
	end

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, channelType in next, optionData.channel_types or {} do
		table.insert(channelTypeArray, apiTypes.channel.ChannelTypes[channelType])
	end

	--[=[
		@prop type ApplicationCommandOptionType
		@within Classes.CommandOption
		The type of the option. This represents what kind of option it is, such as a string, number, or user input.
	]=]
	self.type = apiTypes.interaction.ApplicationCommandOptionType[optionData.type]

	--[=[
		@prop name string
		@within Classes.CommandOption
		The name of the command option. This is what users will see when using the command.
	]=]
	self.name = optionData.name

	--[=[
		@prop nameLocalizations { [LanguageLocales]: string }?
		@within Classes.CommandOption
		Localization dictionary for the name field. Values follow the same restrictions as name.
	]=]
	self.nameLocalizations = optionData.name_localizations

	--[=[
		@prop description string?
		@within Classes.CommandOption
		The description of the command option. Provides additional information about what the option does.
	]=]
	self.description = optionData.description

	--[=[
		@prop descriptionLocalizations { [LanguageLocales]: string }?
		@within Classes.CommandOption
		Localization dictionary for the description field. Values follow the same restrictions as description.
	]=]
	self.descriptionLocalizations = optionData.description_localizations

	--[=[
		@prop required boolean?
		@within Classes.CommandOption
		If the parameter is required or optional. Default false.
	]=]
	self.required = optionData.required

	--[=[
		@prop choices { Classes.Choice }?
		@within Classes.CommandOption
		Choices for the user to pick from. Only available for string and number option types.
	]=]
	self.choices = choiceArray

	--[=[
		@prop options { Classes.CommandOption }?
		@within Classes.CommandOption
		Sub-options if this option is a subcommand or subcommand group type.
	]=]
	self.options = optionArray

	--[=[
		@prop apiTypes { ChannelType }
		@within Classes.CommandOption
		If the option is a channel type, these are the allowed channel types that can be selected.
	]=]
	self.apiTypes = channelTypeArray

	--[=[
		@prop minValue number?
		@within Classes.CommandOption
		For integer or number options, the minimum value permitted.
	]=]
	self.minValue = optionData.min_value

	--[=[
		@prop maxValue number?
		@within Classes.CommandOption
		For integer or number options, the maximum value permitted.
	]=]
	self.maxValue = optionData.max_value

	--[=[
		@prop minLength number?
		@within Classes.CommandOption
		For string options, the minimum allowed length.
	]=]
	self.minLength = optionData.min_length

	--[=[
		@prop maxLength number?
		@within Classes.CommandOption
		For string options, the maximum allowed length.
	]=]
	self.maxLength = optionData.max_length

	--[=[
		@prop autocomplete boolean?
		@within Classes.CommandOption
		Enable autocomplete interactions for this option.
	]=]
	self.autocomplete = optionData.autocomplete
end

--[=[
	@within Classes.CommandOption
	@private

	Responsible for constructing this class.
]=]
function Option.Interface.new(optionData: apiTypes.ApplicationCommandOptionObject): Option
	local self = setmetatable({} :: Option, { __index = Option.Prototype })

	self:sync(optionData)

	return self
end

export type Option = typeof(Option.Prototype) & {
	type: apiTypes.ApplicationCommandOptionType,
	name: string,
	nameLocalizations: { [apiTypes.LanguageLocales]: string }?,
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string }?,
	required: boolean?,
	choices: { choice.Choice }?,
	options: { Option }?,
	apiTypes: { apiTypes.ChannelType },
	minValue: number?,
	maxValue: number?,
	minLength: number?,
	maxLength: number?,
	autocomplete: boolean?,
}

return Option.Interface
