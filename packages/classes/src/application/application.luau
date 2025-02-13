--[[
	Implementation of the Discord Application class in Luau

	https://discord.com/developers/docs/resources/application#application-object
]]

local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")
local rest = require("../../lune_packages/rest")
local builders = require("../../lune_packages/builders")
local future = require("../../luau_packages/future")

local user = require("../user")
local applicationBitflags = require("../bitflags/application")
local team = require("./team/team")
local unavailableGuild = require("../guild/unavailableGuild")
local installParams = require("./installParams")
local commandObject = require("./command/command")

local Application = {}

Application.Interface = {}
Application.Prototype = {}

--[[
	Creates a global Slash Command for the Application, slash commands can take up to 5 minutes to sync, and will require
	developers to reload their discord client.

	For testing/building commands, it's advised you use guild commands, which do not suffer the same constraints.
]]
function Application.Prototype.createSlashCommandAsync(self: Application, slashCommand: builders.interactionJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands.createGlobalApplicationCommandAsync(request, self.id, slashCommand):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return commandObject.new(response:unwrapOk())
	end) :: future.FutureLike<string, commandObject.Command>
end

--[[
	Delete an existing global application command.
]]
function Application.Prototype.deleteSlashCommandAsync(self: Application, slashCommandId: apiTypes.Snowflake)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands.deleteGlobalApplicationCommandAsync(request, self.id, slashCommandId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Edit an existing global application command.
]]
function Application.Prototype.editSlashCommandAsync(
	self: Application,
	slashCommandId: apiTypes.Snowflake,
	slashCommand: builders.interactionJSON
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response =
			rest.commands.editGlobalApplicationCommandAsync(request, self.id, slashCommandId, slashCommand):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return commandObject.new(response:unwrapOk())
	end) :: future.FutureLike<string, commandObject.Command>
end

--[[
	Get a list of global application commands.
]]
function Application.Prototype.getSlashCommandsAsync(self: Application, withLocalizations: boolean?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands
			.getGlobalApplicationCommandsAsync(request, self.id, {
				withLocalizations = withLocalizations,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local commands = {}

		for _, commandData in response:unwrapOk() do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end) :: future.FutureLike<string, { commandObject.Command }>
end

--[[
	Overwrite all global application commands. This will skip over commands that are the same as the current commands, and will not remove any existing commands.
]]
function Application.Prototype.overwriteSlashCommandsAsync(
	self: Application,
	slashCommands: { builders.interactionJSON }
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response =
			rest.commands.bulkOverwriteGlobalApplicationCommandsAsync(request, self.id, slashCommands):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local commands = {}

		for _, commandData in response:unwrapOk() do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end) :: future.FutureLike<string, { commandObject.Command }>
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
	integrationTypesConfig: { [apiTypes.IntegrationTypesConfig]: boolean }?,
	customInstallUrl: string?,
}

return Application.Interface
