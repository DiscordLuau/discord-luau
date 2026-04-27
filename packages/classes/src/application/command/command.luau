--[=[
	@class Classes.Application.Command
	@__index Prototype

	Implementation of the Discord Command class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object
]=]

--[=[
	@prop id string
	@within Classes.Application.Command

	The unique identifier for this command
]=]

--[=[
	@prop type apiTypes.ApplicationCommandType
	@within Classes.Application.Command

	The type of command this represents
]=]

--[=[
	@prop applicationId string
	@within Classes.Application.Command

	The unique identifier of the parent application
]=]

--[=[
	@prop guildId string?
	@within Classes.Application.Command

	ID of the guild this command is registered to, if any
]=]

--[=[
	@prop name string
	@within Classes.Application.Command

	Name of the command
]=]

--[=[
	@prop nameLocalizations { [apiTypes.LanguageLocales]: string }?
	@within Classes.Application.Command

	Localization dictionary for the command name
]=]

--[=[
	@prop description string
	@within Classes.Application.Command

	Description of the command
]=]

--[=[
	@prop descriptionLocalizations { [apiTypes.LanguageLocales]: string }?
	@within Classes.Application.Command

	Localization dictionary for the command description
]=]

--[=[
	@prop options { Classes.Option }
	@within Classes.Application.Command

	The parameters for the command
]=]

--[=[
	@prop defaultMemberPermissions Classes.Permission?
	@within Classes.Application.Command

	Default required permissions to use this command
]=]

--[=[
	@prop nsfw boolean?
	@within Classes.Application.Command

	Whether this command is age-restricted
]=]

--[=[
	@prop integrationTypes { apiTypes.IntegrationTypesConfig }
	@within Classes.Application.Command

	The integration types this command supports
]=]

--[=[
	@prop contexts { apiTypes.InteractionContextType }
	@within Classes.Application.Command

	The contexts this command can be used in
]=]

--[=[
	@prop version string
	@within Classes.Application.Command

	Auto-incrementing version identifier updated during substantial record changes
]=]

local apiTypes = require("../../../luau_packages/api_types")

local permission = require("../../permission")

local option = require("./option")

local Command = {}

Command.Interface = {}
Command.Prototype = {}

--[=[
	@within Classes.Application.Command
	@private

	Responsible for syncing data to this command object. This is typically called by the API when this object is
	created or updated.
]=]
function Command.Prototype.sync(self: Command, commandData: apiTypes.ApplicationCommandObject)
	local optionArray = {}
	local integrationTypeArray = {}
	local contextArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, optionData in next, commandData.options or {} do
		table.insert(optionArray, option.new(optionData))
	end

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, integrationType in next, commandData.integration_types or {} do
		table.insert(integrationTypeArray, apiTypes.application.IntegrationTypesConfig[integrationType])
	end

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, context in next, commandData.contexts or {} do
		table.insert(integrationTypeArray, apiTypes.interaction.InteractionContextType[context])
	end

	self.id = commandData.id or "-1"

	self.type = apiTypes.interaction.ApplicationCommandType[commandData.type]

	self.applicationId = commandData.application_id or "-1"

	self.guildId = commandData.guild_id

	self.name = commandData.name

	self.nameLocalizations = commandData.name_localizations

	self.description = commandData.description

	self.descriptionLocalizations = commandData.description_localizations

	self.options = optionArray

	self.defaultMemberPermissions = commandData.default_member_permissions
		and permission.new(commandData.default_member_permissions)

	self.nsfw = commandData.nsfw

	self.integrationTypes = integrationTypeArray

	self.contexts = contextArray

	self.version = commandData.version or "-1"
end

--[=[
	@within Classes.Application.Command
	@private

	Responsible for constructing this class.
]=]
function Command.Interface.new(commandData: apiTypes.ApplicationCommandObject): Command
	local self = setmetatable({} :: Command, { __index = Command.Prototype })

	self:sync(commandData)

	return self
end

export type Command = typeof(Command.Prototype) & {
	id: apiTypes.Snowflake,
	type: apiTypes.ApplicationCommandType?,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake?,
	name: string,
	nameLocalizations: { [apiTypes.LanguageLocales]: string }?,
	description: string,
	descriptionLocalizations: { [apiTypes.LanguageLocales]: string }?,
	options: { option.Option },
	defaultMemberPermissions: permission.Permission?,
	-- dmPermission: boolean?,
	-- defaultPermissions: boolean?
	nsfw: boolean?,
	integrationTypes: { apiTypes.IntegrationTypesConfig },
	contexts: { apiTypes.InteractionContextType },
	version: apiTypes.Snowflake,
	-- handler: -- todo: implement handler type
}

return Command.Interface
