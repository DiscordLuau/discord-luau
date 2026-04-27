--[=[
	@class Classes.Application.CommandOption
	@__index Prototype

	Implementation of the Discord Option class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure
]=]

--[=[
	@prop type ApplicationCommandOptionType
	@within Classes.Application.CommandOption
	The type of the option. This represents what kind of option it is, such as a string, number, or user input.
]=]

--[=[
	@prop name string
	@within Classes.Application.CommandOption
	The name of the command option. This is what users will see when using the command.
]=]

--[=[
	@prop nameLocalizations { [LanguageLocales]: string }?
	@within Classes.Application.CommandOption
	Localization dictionary for the name field. Values follow the same restrictions as name.
]=]

--[=[
	@prop description string?
	@within Classes.Application.CommandOption
	The description of the command option. Provides additional information about what the option does.
]=]

--[=[
	@prop descriptionLocalizations { [LanguageLocales]: string }?
	@within Classes.Application.CommandOption
	Localization dictionary for the description field. Values follow the same restrictions as description.
]=]

--[=[
	@prop required boolean?
	@within Classes.Application.CommandOption
	If the parameter is required or optional. Default false.
]=]

--[=[
	@prop choices { Classes.Application.CommandChoice }?
	@within Classes.Application.CommandOption
	Choices for the user to pick from. Only available for string and number option types.
]=]

--[=[
	@prop options { Classes.Application.CommandOption }?
	@within Classes.Application.CommandOption
	Sub-options if this option is a subcommand or subcommand group type.
]=]

--[=[
	@prop apiTypes { ChannelType }
	@within Classes.Application.CommandOption
	If the option is a channel type, these are the allowed channel types that can be selected.
]=]

--[=[
	@prop minValue number?
	@within Classes.Application.CommandOption
	For integer or number options, the minimum value permitted.
]=]

--[=[
	@prop maxValue number?
	@within Classes.Application.CommandOption
	For integer or number options, the maximum value permitted.
]=]

--[=[
	@prop minLength number?
	@within Classes.Application.CommandOption
	For string options, the minimum allowed length.
]=]

--[=[
	@prop maxLength number?
	@within Classes.Application.CommandOption
	For string options, the maximum allowed length.
]=]

--[=[
	@prop autocomplete boolean?
	@within Classes.Application.CommandOption
	Enable autocomplete interactions for this option.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local choice = require("./choice")

local Option = {}

Option.Interface = {}
Option.Prototype = {}

--[=[
	@within Classes.Application.CommandOption
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

	self.type = apiTypes.interaction.ApplicationCommandOptionType[optionData.type]

	self.name = optionData.name

	self.nameLocalizations = optionData.name_localizations

	self.description = optionData.description

	self.descriptionLocalizations = optionData.description_localizations

	self.required = optionData.required

	self.choices = choiceArray

	self.options = optionArray

	self.apiTypes = channelTypeArray

	self.minValue = optionData.min_value

	self.maxValue = optionData.max_value

	self.minLength = optionData.min_length

	self.maxLength = optionData.max_length

	self.autocomplete = optionData.autocomplete
end

--[=[
	@within Classes.Application.CommandOption
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
