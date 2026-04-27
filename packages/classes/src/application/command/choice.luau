--[=[
	@class Classes.Application.CommandChoice
	@__index Prototype

	Implementation of the Discord Choice class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure
]=]

--[=[
	@prop name string
	@within Classes.Application.CommandChoice

	The name of the choice that will be displayed to users when selecting this option.
]=]

--[=[
	@prop nameLocalizations { [apiTypes.LanguageLocales]: string }?
	@within Classes.Application.CommandChoice

	Dictionary of localization overrides for the choice name. Keys are valid locale identifiers, values are localized names.
]=]

--[=[
	@prop value string | number
	@within Classes.Application.CommandChoice

	The value that will be sent to your application when this choice is selected by a user.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local Choice = {}

Choice.Interface = {}
Choice.Prototype = {}

--[=[
	@within Classes.Application.CommandChoice
	@private

	Responsible for syncing data to this choice object. This is typically called by the API when this object is
	created or updated.
]=]
function Choice.Prototype.sync(self: Choice, choiceData: apiTypes.ApplicationCommandOptionChoiceObject)
	self.name = choiceData.name

	self.nameLocalizations = choiceData.name_localizations

	self.value = choiceData.value
end

--[=[
	@within Classes.Application.CommandChoice
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
