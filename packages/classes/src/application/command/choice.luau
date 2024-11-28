--[[
	Implementation of the Discord Choice class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local Choice = {}

Choice.Interface = {}
Choice.Prototype = {}

function Choice.Prototype.sync(self: Choice, choiceData: apiTypes.ApplicationCommandOptionChoiceObject)
	self.name = choiceData.name
	self.nameLocalizations = choiceData.name_localizations
	self.value = choiceData.value
end

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
