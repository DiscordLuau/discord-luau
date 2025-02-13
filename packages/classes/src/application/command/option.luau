--[[
	Implementation of the Discord Option class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local choice = require("./choice")

local Option = {}

Option.Interface = {}
Option.Prototype = {}

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
