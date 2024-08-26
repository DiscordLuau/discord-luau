--[[
	Implementation of a discord default reaction object as a luau builder.	

	https://discord.com/developers/docs/interactions/application-commands#create-global-application-command-json-params
]]

local apiTypes = require("@api-types/apiTypes")
local interactionTypes = require("@api-types/interaction")
local applicationTypes = require("@api-types/application")

local validateKebabCase = require("@utils/validateKebabCase")

local Interaction = {}

Interaction.Prototype = {}
Interaction.Interface = {}

--[[
	Name of command, 1-32 characters
]]
function Interaction.Prototype.setName(self: Interaction, name: string): Interaction
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")

	self.name = name

	return self
end

--[[
	Localization dictionary for the name field. Values follow the same restrictions as name
]]
function Interaction.Prototype.setNameLocalization(
	self: Interaction,
	localization: apiTypes.LanguageLocales,
	name: string
): Interaction
	assert(#name <= 32, "name must be less than 32 characters")
	assert(#name >= 1, "name must be at least 1 character")

	validateKebabCase(name)

	self.nameLocalizations[localization] = name

	return self
end

--[[
	1-100 character description
]]
function Interaction.Prototype.setDescription(self: Interaction, description: string): Interaction
	assert(#description <= 100, "description must be less than 100 characters")
	assert(#description >= 1, "description must be at least 1 character")

	self.description = description

	return self
end

--[[
	Localization dictionary for the description field. Values follow the same restrictions as description
]]
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

--[[
	the parameters for the command
]]
function Interaction.Prototype.addOption(
	self: Interaction,
	option: apiTypes.ApplicationCommandOptionObject
): Interaction
	table.insert(self.options, option)

	return self
end

--[[
	Set of permissions represented as a bit set, recommended that you use the permission builder.
]]
function Interaction.Prototype.setDefaultMemberPermissions(self: Interaction, permissions: string): Interaction
	self.defaultMemberPermissions = permissions

	return self
end

--[[
	Installation context(s) where the command is available
]]
function Interaction.Prototype.addIntegrationType(
	self: Interaction,
	type: applicationTypes.IntegrationTypesConfig
): Interaction
	table.insert(self.integrationTypes, type)

	return self
end

--[[
	Interaction context(s) where the command can be used
]]
function Interaction.Prototype.addContext(
	self: Interaction,
	context: interactionTypes.InteractionContextType
): Interaction
	table.insert(self.contexts, context)

	return self
end

--[[
	Indicates whether the command is age-restricted
]]
function Interaction.Prototype.setNsfw(self: Interaction, isNsfw: boolean): Interaction
	self.nsfw = isNsfw

	return self
end

--[[
	Responsible for buillding the default reaction object that the Discord API can understand.
]]
function Interaction.Prototype.build(self: Interaction)
	return {
		name = self.name,
		name_localizations = self.nameLocalizations,
		description = self.description,
		description_localizations = self.descriptionLocalizations,
		options = self.options,
		default_member_permissions = self.defaultMemberPermissions,
		integration_types = self.integrationTypes,
		nsfw = self.nsfw,
	}
end

--[[
	Constructor for the Discord Default Reaction Builder.

	```lua
	local defaultReaction = Interaction.new("000000000000000000", "secret-emoji"):build()
	```
]]
function Interaction.Interface.new(resource: {
	name: string?,
	nameLocalizations: { [apiTypes.LanguageLocales]: string }?,
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string }?,
	options: { apiTypes.ApplicationCommandOptionObject }?,
	defaultMemberPermissions: string?,
	integrationTypes: { applicationTypes.IntegrationTypesConfig }?,
	contexts: { interactionTypes.InteractionContextType }?,
	nsfw: boolean?,
}?): Interaction
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
		for _, type: applicationTypes.IntegrationTypesConfig in resource.integrationTypes do
			self:addIntegrationType(type)
		end
	end

	if resource and resource.contexts then
		for _, context: interactionTypes.InteractionContextType in resource.contexts do
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
	description: string?,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string },
	options: { apiTypes.ApplicationCommandOptionObject },
	defaultMemberPermissions: string?,
	integrationTypes: { applicationTypes.IntegrationTypesConfig },
	contexts: { interactionTypes.InteractionContextType },
	nsfw: boolean?,
}

return Interaction.Interface
