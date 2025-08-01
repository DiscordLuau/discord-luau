--[=[
	@class Builders.Interaction
	@__index Prototype

	Implementation of a discord Interaction object as a luau builder.

	https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command-json-params
]=]

local apiTypes = require("../../lune_packages/api_types")
local interactionOption = require("./option")
local util = require("../../lune_packages/util")

local Interaction = {}

Interaction.Prototype = {}
Interaction.Interface = {}

--[=[
	@within Builders.Interaction

	Name of command, 1-32 characters
]=]
function Interaction.Prototype.setName(self: Interaction, name: string): Interaction
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")

	self.name = name

	return self
end

--[=[
	@within Builders.Interaction

	Set the Type of command
]=]
function Interaction.Prototype.setType(self: Interaction, commandType: apiTypes.ApplicationCommandType): Interaction
	self.type = commandType

	return self
end

--[=[
	@within Builders.Interaction

	Localization dictionary for the name field. Values follow the same restrictions as name
]=]
function Interaction.Prototype.setNameLocalization(
	self: Interaction,
	localization: apiTypes.LanguageLocales,
	name: string
): Interaction
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")

	assert(util.validateKebabCase(name), `name must be kebab case`)

	self.nameLocalizations[localization] = name

	return self
end

--[=[
	@within Builders.Interaction

	1-100 character description
]=]
function Interaction.Prototype.setDescription(self: Interaction, description: string): Interaction
	assert(#description <= 100, "description must be less than 100 characters")
	assert(#description >= 1, "description must be at least 1 character")

	self.description = description

	return self
end

--[=[
	@within Builders.Interaction

	Localization dictionary for the description field. Values follow the same restrictions as description
]=]
function Interaction.Prototype.setDescriptionLocalization(
	self: Interaction,
	localization: apiTypes.LanguageLocales,
	description: string
): Interaction
	assert(#description <= 100, "description must be less than 100 characters")
	assert(#description >= 1, "description must be at least 1 character")

	self.descriptionLocalizations[localization] = description

	return self
end

--[=[
	@within Builders.Interaction

	The parameters for the command
]=]
function Interaction.Prototype.addOption(self: Interaction, option: interactionOption.JSON): Interaction
	table.insert(self.options, option)

	return self
end

--[=[
	@within Builders.Interaction

	Set of permissions represented as a bit set, recommended that you use the permission builder.
]=]
function Interaction.Prototype.setDefaultMemberPermissions(self: Interaction, permissions: string): Interaction
	self.defaultMemberPermissions = permissions

	return self
end

--[=[
	@within Builders.Interaction

	Installation context(s) where the command is available
]=]
function Interaction.Prototype.addIntegrationType(self: Interaction, type: apiTypes.IntegrationTypesConfig): Interaction
	table.insert(self.integrationTypes, type)

	return self
end

--[=[
	@within Builders.Interaction

	Interaction context(s) where the command can be used
]=]
function Interaction.Prototype.addContext(self: Interaction, context: apiTypes.InteractionContextType): Interaction
	table.insert(self.contexts, context)

	return self
end

--[=[
	@within Builders.Interaction

	Indicates whether the command is age-restricted
]=]
function Interaction.Prototype.setNsfw(self: Interaction, isNsfw: boolean): Interaction
	self.nsfw = isNsfw

	return self
end

--[=[
	@within Builders.Interaction

	Responsible for building the default reaction object that the Discord API can understand.
]=]
function Interaction.Prototype.build(self: Interaction): JSON
	assert(self.name, "name must be set")
	assert(#self.integrationTypes > 0, `must have one or more integration types set`)
	assert(#self.contexts > 0, `must have one or more contexts set`)

	local contexts: { number } = {}
	local integrationTypeArray: { number } = {}

	for _, context in self.contexts do
		table.insert(contexts, apiTypes.interaction.InteractionContextType[context])
	end

	for _, interactionType in self.integrationTypes do
		table.insert(integrationTypeArray, apiTypes.interaction.IntegrationTypesConfig[interactionType])
	end

	return {
		id = nil :: any,
		application_id = nil :: any,
		version = nil :: any,
		guild_id = nil :: any,
		name = self.name,
		name_localizations = self.nameLocalizations,
		description = self.description,
		description_localizations = self.descriptionLocalizations,
		options = self.options,
		default_member_permissions = self.defaultMemberPermissions,
		dm_permission = nil :: any,
		default_permission = nil :: any,
		integration_types = integrationTypeArray,
		contexts = contexts,
		type = apiTypes.application.ApplicationCommandType[self.type] or nil,
		nsfw = self.nsfw,
	}
end

--[=[
	@within Builders.Interaction

	Constructor for the Discord Default Reaction Builder.
]=]
function Interaction.Interface.new(resource: {
	name: string?,
	nameLocalizations: { [apiTypes.LanguageLocales]: string }?,
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string }?,
	options: { interactionOption.JSON }?,
	defaultMemberPermissions: string?,
	integrationTypes: { apiTypes.IntegrationTypesConfig }?,
	contexts: { apiTypes.InteractionContextType }?,
	nsfw: boolean?,
}?): Interaction
	--[=[
		@prop name string
		@within Builders.Interaction
		The name of the command.
	]=]
	--[=[
		@prop nameLocalizations { [package].LanguageLocales: string }
		@within Builders.Interaction
		Localization dictionary for the name field.
	]=]
	--[=[
		@prop description string
		@within Builders.Interaction
		The description of the command.
	]=]
	--[=[
		@prop descriptionLocalizations { [package].LanguageLocales: string }
		@within Builders.Interaction
		Localization dictionary for the description field.
	]=]
	--[=[
		@prop options { package.option.JSON }
		@within Builders.Interaction
		A list of parameters/options for the command.
	]=]
	--[=[
		@prop defaultMemberPermissions string?
		@within Builders.Interaction
		Permissions required to execute the command.
	]=]
	--[=[
		@prop integrationTypes { package.api_types.IntegrationTypesConfig }
		@within Builders.Interaction
		Installation contexts the command is available to.
	]=]
	--[=[
		@prop contexts { package.api_types.InteractionContextType }
		@within Builders.Interaction
		Interaction contexts where the command can be used.
	]=]
	--[=[
		@prop nsfw boolean?
		@within Builders.Interaction
		Whether this command is age-restricted.
	]=]
	local self = setmetatable(
		{
			nameLocalizations = {},
			descriptionLocalizations = {},
			options = {},
			integrationTypes = {},
			contexts = {},
		} :: Interaction,
		{ __index = Interaction.Prototype }
	)

	if resource and resource.name then
		self:setName(resource.name)
	end

	if resource and resource.nameLocalizations then
		for localization: apiTypes.LanguageLocales, name in resource.nameLocalizations do
			self:setNameLocalization(localization, name)
		end
	end

	if resource and resource.description then
		self:setDescription(resource.description)
	end

	if resource and resource.descriptionLocalizations then
		for localization: apiTypes.LanguageLocales, name in resource.descriptionLocalizations do
			self:setDescriptionLocalization(localization, name)
		end
	end

	if resource and resource.options then
		for _, option in resource.options do
			self:addOption(option)
		end
	end

	if resource and resource.defaultMemberPermissions then
		self:setDefaultMemberPermissions(resource.defaultMemberPermissions)
	end

	if resource and resource.integrationTypes then
		for _, type: apiTypes.IntegrationTypesConfig in resource.integrationTypes do
			self:addIntegrationType(type)
		end
	end

	if resource and resource.contexts then
		for _, context: apiTypes.InteractionContextType in resource.contexts do
			self:addContext(context)
		end
	end

	if resource and resource.nsfw then
		self:setNsfw(resource.nsfw)
	end

	return self
end

export type Interaction = typeof(Interaction.Prototype) & {
	name: string,
	nameLocalizations: { [apiTypes.LanguageLocales]: string },
	description: string,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string },
	options: { interactionOption.JSON },
	defaultMemberPermissions: string?,
	integrationTypes: { apiTypes.IntegrationTypesConfig },
	contexts: { apiTypes.InteractionContextType },
	type: apiTypes.ApplicationCommandType,
	nsfw: boolean?,
}

export type JSON = typeof(Interaction.Prototype.build(nil :: any))

return Interaction.Interface
