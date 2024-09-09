--[[
	Implementation of the Discord Application class in Luau

	https://discord.com/developers/docs/resources/application#application-object
]]

local future = require("@vendor/future")

local apiTypes = require("@api-types/apiTypes")
local applicationTypes = require("@api-types/application")

local user = require("@classes/user")
local unavailableGuild = require("@classes/guild/unavailableGuild")
local team = require("@classes/application/team/team")
local state = require("@classes/state")
local installParams = require("@classes/application/installParams")

local commandsRest = require("@rest/commands")
local interactionBuilder = require("@builders/interaction/interaction")

local commandObject = require("@classes/application/command/command")

local applicationBitflags = require("@classes/bitflags/application")

local Application = {}

Application.Interface = {}
Application.Prototype = {}

--[[
	Creates a global Slash Command for the Application, slash commands can take up to 5 minutes to sync, and will require
	developers to reload their discord client.

	For testing/building commands, it's advised you use guild commands, which do not suffer the same constraints.
]]
function Application.Prototype.createSlashCommandAsync(
	self: Application,
	slashCommand: interactionBuilder.JSON
): future.Future<commandObject.Command>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response =
			commandsRest.createGlobalApplicationCommandAsync(request, self.id, slashCommand):await()

		assert(status == "Fulfilled", tostring(response))

		return commandObject.new(response)
	end)
end

--[[
	Delete an existing global application command.
]]
function Application.Prototype.deleteSlashCommandAsync(
	self: Application,
	slashCommandId: apiTypes.Snowflake
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response =
			commandsRest.deleteGlobalApplicationCommandAsync(request, self.id, slashCommandId):await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	Edit an existing global application command.
]]
function Application.Prototype.editSlashCommandAsync(
	self: Application,
	slashCommandId: apiTypes.Snowflake,
	slashCommand: interactionBuilder.JSON
): future.Future<commandObject.Command>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response =
			commandsRest.editGlobalApplicationCommandAsync(request, self.id, slashCommandId, slashCommand):await()

		assert(status == "Fulfilled", tostring(response))

		return commandObject.new(response)
	end)
end

--[[
	Get a list of global application commands.
]]
function Application.Prototype.getSlashCommandsAsync(
	self: Application,
	withLocalizations: boolean?
): future.Future<{ commandObject.Command }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = commandsRest
			.getGlobalApplicationCommandsAsync(request, self.id, {
				withLocalizations = withLocalizations,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local commands = {}

		for _, commandData in response do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end)
end

--[[
	Overwrite all global application commands. This will skip over commands that are the same as the current commands, and will not remove any existing commands.
]]
function Application.Prototype.overwriteSlashCommandsAsync(
	self: Application,
	slashCommands: { interactionBuilder.JSON }
): future.Future<{ commandObject.Command }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response =
			commandsRest.bulkOverwriteGlobalApplicationCommandsAsync(request, self.id, slashCommands):await()

		assert(status == "Fulfilled", tostring(response))

		local commands = {}

		for _, commandData in response do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end)
end

function Application.Prototype.sync(self: Application, applicationData: apiTypes.ApplicationObject)
	local integrationTypesConfig = {}

	for integrationType, available in next, applicationData.integration_types_config or {} do
		-- todo: are these actually numbers or strings?

		if integrationType == 0 then
			integrationTypesConfig.GuildInstall = available
		elseif integrationType == 1 then
			integrationTypesConfig.UserInstall = available
		end
	end

	self.id = applicationData.id
	self.name = applicationData.name
	self.icon = applicationData.icon
	self.description = applicationData.description
	self.rpcOrigins = applicationData.rpc_origins
	self.botPublic = applicationData.bot_public
	self.botRequireCodeGrant = applicationData.bot_require_code_grant
	self.bot = applicationData.bot and user.new(applicationData.bot)
	self.termsOfServiceUrl = applicationData.terms_of_service_url
	self.privacyPolicyUrl = applicationData.privacy_policy_url
	self.owner = applicationData.owner and user.new(applicationData.owner)
	self.summary = applicationData.summary
	self.verifyKey = applicationData.verify_key
	self.team = applicationData.team and team.new(applicationData.team)
	self.guildId = applicationData.guild_id
	self.guild = applicationData.guild
		and applicationData.guild.id
		and unavailableGuild.new(self.state, applicationData.guild.id)
	self.primarySkuId = applicationData.primary_sku_id
	self.slug = applicationData.slug
	self.coverImage = applicationData.cover_image
	self.flags = applicationData.flags and applicationBitflags.new(applicationData.flags)
	self.installParams = applicationData.install_params and installParams.new(applicationData.install_params)
	self.integrationTypesConfig = integrationTypesConfig
	self.customInstallUrl = applicationData.custom_install_url
end

function Application.Interface.new(state: state.State, applicationData: apiTypes.ApplicationObject): Application
	local self = setmetatable(
		{
			state = state,
		} :: Application,
		{ __index = Application.Prototype }
	)

	self:sync(applicationData)

	return self
end

export type Application = typeof(Application.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	name: string,
	icon: string?,
	description: string,
	rpcOrigins: { string }?,
	botPublic: boolean,
	botRequireCodeGrant: boolean,
	bot: user.User?,
	termsOfServiceUrl: string?,
	privacyPolicyUrl: string?,
	owner: user.User?,
	summary: string?,
	verifyKey: string?,
	team: team.Team?,
	guildId: apiTypes.Snowflake?,
	guild: unavailableGuild.UnavailableGuild?,
	primarySkuId: apiTypes.Snowflake?,
	slug: string?,
	coverImage: string?,
	flags: applicationBitflags.ApplicationBitflag?,
	approximateGuildCount: number?,
	approximateUserInstallCount: number?,
	redirectUris: { string }?,
	installParams: installParams.InstallParams?,
	integrationTypesConfig: { [applicationTypes.IntegrationTypesConfig]: boolean }?,
	customInstallUrl: string?,
}

return Application.Interface
