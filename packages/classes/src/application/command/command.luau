--[[
	Implementation of the Discord Command class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local permission = require("../../permission")

local option = require("./option")

local Command = {}

Command.Interface = {}
Command.Prototype = {}

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

	self.id = commandData.id or "-1"
	self.type = apiTypes.application.ApplicationCommandType[commandData.type]
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
