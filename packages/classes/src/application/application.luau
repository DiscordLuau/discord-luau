--[=[
	@class Classes.Application
	@__index Prototype

	Implementation of the Discord Application class in Luau.
	This class represents a Discord application and provides methods to manage application commands and properties.

	https://discord.com/developers/docs/resources/application#application-object
]=]

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

--[=[
	@within Classes.Application
	Creates a global Slash Command for the Application, slash commands can take up to 5 minutes to sync, and will require
	developers to reload their discord client.

	For testing/building commands, it's advised you use guild commands, which do not suffer the same constraints.
]=]
function Application.Prototype.createSlashCommandAsync(self: Application, slashCommand: builders.interactionJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands.createGlobalApplicationCommandAsync(request, self.id, slashCommand):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return commandObject.new(response:unwrapOk())
	end) :: future.FutureLike<string, commandObject.Command>
end

--[=[
	@within Classes.Application
	Delete an existing global application command.
]=]
function Application.Prototype.deleteSlashCommandAsync(self: Application, slashCommandId: apiTypes.Snowflake)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands.deleteGlobalApplicationCommandAsync(request, self.id, slashCommandId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Application
	Edit an existing global application command.
]=]
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

--[=[
	@within Classes.Application
	Get a list of global application commands.
]=]
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

--[=[
	@within Classes.Application
	Overwrite all global application commands. This will skip over commands that are the same as the current commands, and will not remove any existing commands.
]=]
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

--[=[
	@within Classes.Application
	@private

	Synchronizes the application object with the data from the API.
]=]
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

	--[=[
		@within Classes.Application
		@prop id string
		The unique identifier for this application. This is a Discord snowflake that represents when this application
		was created and other metadata.
	]=]
	self.id = applicationData.id

	--[=[
		@within Classes.Application
		@prop name string
		The name of the application as it appears on Discord. This is what users will see when they interact with
		your application.
	]=]
	self.name = applicationData.name

	--[=[
		@within Classes.Application
		@prop icon string?
		The icon hash of the application. This can be used to generate the application's icon URL for display
		purposes.
	]=]
	self.icon = applicationData.icon

	--[=[
		@within Classes.Application
		@prop description string
		A detailed description of what your application does. This appears in various places across Discord's
		interface.
	]=]
	self.description = applicationData.description

	--[=[
		@within Classes.Application
		@prop rpcOrigins { string }?
		An array of allowed RPC origin URLs. These URLs are permitted to make RPC connections to your application
		if RPC is enabled.
	]=]
	self.rpcOrigins = applicationData.rpc_origins

	--[=[
		@within Classes.Application
		@prop botPublic boolean
		Controls who can add the bot to servers. When false, only the application owner can add the bot to servers,
		providing more control over bot distribution.
	]=]
	self.botPublic = applicationData.bot_public

	--[=[
		@within Classes.Application
		@prop botRequireCodeGrant boolean
		Determines the OAuth2 flow behavior. When true, users must complete the full OAuth2 code grant flow before
		the bot can join their server.
	]=]
	self.botRequireCodeGrant = applicationData.bot_require_code_grant

	--[=[
		@within Classes.Application
		@prop bot Classes.User?
		The bot user associated with this application. Contains information about the bot's Discord user account.
	]=]
	self.bot = applicationData.bot and user.new(applicationData.bot)

	--[=[
		@within Classes.Application
		@prop termsOfServiceUrl string?
		A URL linking to your application's terms of service. This should contain important legal information
		about using your application.
	]=]
	self.termsOfServiceUrl = applicationData.terms_of_service_url

	--[=[
		@within Classes.Application
		@prop privacyPolicyUrl string?
		A URL linking to your application's privacy policy. This should detail how you handle user data and
		privacy concerns.
	]=]
	self.privacyPolicyUrl = applicationData.privacy_policy_url

	--[=[
		@within Classes.Application
		@prop owner Classes.User?
		The Discord user who owns this application. This user has full control over the application's settings
		and behavior.
	]=]
	self.owner = applicationData.owner and user.new(applicationData.owner)

	--[=[
		@within Classes.Application
		@prop summary string?
		A brief summary of your application. This appears in various places across Discord's interface where
		a shorter description is needed.
	]=]
	self.summary = applicationData.summary

	--[=[
		@within Classes.Application
		@prop verifyKey string?
		A hex-encoded key used for verification in interactions and the GameSDK's GetTicket. This is important
		for security verification.
	]=]
	self.verifyKey = applicationData.verify_key

	--[=[
		@within Classes.Application
		@prop team Classes.Team?
		Information about the team that owns and manages this application. Teams allow multiple users to
		collaborate on an application.
	]=]
	self.team = applicationData.team and team.new(applicationData.team)

	--[=[
		@within Classes.Application
		@prop guildId string?
		For applications that are games sold on Discord, this is the ID of the guild that the game has been
		linked to.
	]=]
	self.guildId = applicationData.guild_id

	--[=[
		@within Classes.Application
		@prop guild Classes.UnavailableGuild?
		For applications that are games sold on Discord, this represents the guild that the game has been
		linked to.
	]=]
	self.guild = applicationData.guild
		and applicationData.guild.id
		and unavailableGuild.new(self.state, applicationData.guild.id)

	--[=[
		@within Classes.Application
		@prop primarySkuId string?
		For games sold on Discord, this is the ID of the primary SKU that is created for the game. This
		represents the main purchasable version of the game.
	]=]
	self.primarySkuId = applicationData.primary_sku_id

	--[=[
		@within Classes.Application
		@prop slug string?
		For games sold on Discord, this is the URL-friendly string that links to the store page. This makes
		it easy to share and access the game's store listing.
	]=]
	self.slug = applicationData.slug

	--[=[
		@within Classes.Application
		@prop coverImage string?
		The hash of the default rich presence invite cover image. This image appears when users share your
		application through Discord's rich presence feature.
	]=]
	self.coverImage = applicationData.cover_image

	--[=[
		@within Classes.Application
		@prop flags Classes.ApplicationBitflag?
		The public flags associated with this application. These flags can indicate various features or states
		of the application.
	]=]
	self.flags = applicationData.flags and applicationBitflags.new(applicationData.flags)

	--[=[
		@within Classes.Application
		@prop installParams Classes.InstallParams?
		The default parameters used when installing the application. These parameters configure how the
		application is set up when added to a server.
	]=]
	self.installParams = applicationData.install_params and installParams.new(applicationData.install_params)

	--[=[
		@within Classes.Application
		@prop integrationTypesConfig { [apiTypes.IntegrationTypesConfig]: boolean }?
		Configuration settings for different types of integrations. This determines what integration options
		are available for the application.
	]=]
	self.integrationTypesConfig = integrationTypesConfig

	--[=[
		@within Classes.Application
		@prop customInstallUrl string?
		A custom URL that users can visit to install the application. This can be used to provide a branded
		or customized installation experience.
	]=]
	self.customInstallUrl = applicationData.custom_install_url
end

--[=[
	@within Classes.Application
	@private

	Creates a new Application instance with the specified application data.
]=]
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
