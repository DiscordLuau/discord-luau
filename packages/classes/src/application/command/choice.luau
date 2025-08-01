--[=[
	@class Classes.Choice
	@__index Prototype

	Implementation of the Discord Choice class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local Choice = {}

Choice.Interface = {}
Choice.Prototype = {}

--[=[
	@within Classes.Choice
	@private

	Responsible for syncing data to this choice object. This is typically called by the API when this object is
	created or updated.
]=]
function Choice.Prototype.sync(self: Choice, choiceData: apiTypes.ApplicationCommandOptionChoiceObject)
	--[=[
		@prop name string
		@within Classes.Choice

		The name of the choice that will be displayed to users when selecting this option.
	]=]
	self.name = choiceData.name

	--[=[
		@prop nameLocalizations { [apiTypes.LanguageLocales]: string }?
		@within Classes.Choice

		Dictionary of localization overrides for the choice name. Keys are valid locale identifiers, values are localized names.
	]=]
	self.nameLocalizations = choiceData.name_localizations

	--[=[
		@prop value string | number
		@within Classes.Choice

		The value that will be sent to your application when this choice is selected by a user.
	]=]
	self.value = choiceData.value
end

--[=[
	@within Classes.Choice
	@private

	Responsible for constructing this class.
]=]
function Choice.Interface.new(choiceData: apiTypes.ApplicationCommandOptionChoiceObject): Choice
	local self = setmetatable({} :: Choice, { __index = Choice.Prototype })

	self:sync(choiceData)

	return self
end

export type Choice = typeof(Choice.Prototype) & {
	name: string,
	nameLocalizations: { [apiTypes.LanguageLocales]: string }?,
	value: string | number,
}

return Choice.Interface
