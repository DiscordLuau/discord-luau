--[=[
	@class Classes.Command
	@__index Prototype

	Implementation of the Discord Command class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local permission = require("../../permission")

local option = require("./option")

local Command = {}

Command.Interface = {}
Command.Prototype = {}

--[=[
	@within Classes.Command
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
		table.insert(integrationTypeArray, apiTypes.application.InteractionContextType[context])
	end

	--[=[
		@prop id string
		@within Classes.Command

		The unique identifier for this command
	]=]
	self.id = commandData.id or "-1"

	--[=[
		@prop type apiTypes.ApplicationCommandType
		@within Classes.Command

		The type of command this represents
	]=]
	self.type = apiTypes.application.ApplicationCommandType[commandData.type]

	--[=[
		@prop applicationId string
		@within Classes.Command

		The unique identifier of the parent application
	]=]
	self.applicationId = commandData.application_id or "-1"

	--[=[
		@prop guildId string?
		@within Classes.Command

		ID of the guild this command is registered to, if any
	]=]
	self.guildId = commandData.guild_id

	--[=[
		@prop name string
		@within Classes.Command

		Name of the command
	]=]
	self.name = commandData.name

	--[=[
		@prop nameLocalizations { [apiTypes.LanguageLocales]: string }?
		@within Classes.Command

		Localization dictionary for the command name
	]=]
	self.nameLocalizations = commandData.name_localizations

	--[=[
		@prop description string
		@within Classes.Command

		Description of the command
	]=]
	self.description = commandData.description

	--[=[
		@prop descriptionLocalizations { [apiTypes.LanguageLocales]: string }?
		@within Classes.Command

		Localization dictionary for the command description
	]=]
	self.descriptionLocalizations = commandData.description_localizations

	--[=[
		@prop options { Classes.Option }
		@within Classes.Command

		The parameters for the command
	]=]
	self.options = optionArray

	--[=[
		@prop defaultMemberPermissions Classes.Permission?
		@within Classes.Command

		Default required permissions to use this command
	]=]
	self.defaultMemberPermissions = commandData.default_member_permissions
		and permission.new(commandData.default_member_permissions)

	--[=[
		@prop nsfw boolean?
		@within Classes.Command

		Whether this command is age-restricted
	]=]
	self.nsfw = commandData.nsfw

	--[=[
		@prop integrationTypes { apiTypes.IntegrationTypesConfig }
		@within Classes.Command

		The integration types this command supports
	]=]
	self.integrationTypes = integrationTypeArray

	--[=[
		@prop contexts { apiTypes.InteractionContextType }
		@within Classes.Command

		The contexts this command can be used in
	]=]
	self.contexts = contextArray

	--[=[
		@prop version string
		@within Classes.Command

		Auto-incrementing version identifier updated during substantial record changes
	]=]
	self.version = commandData.version or "-1"
end

--[=[
	@within Classes.Command
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
