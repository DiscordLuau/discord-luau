--[=[
	@class Classes.InteractionBehaviour
	@__index Prototype

	Represents a Discord Interaction object that implements the Discord Interaction class in Luau.
	This class serves as the base for all interaction types in Discord.

	 https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local data = require("../data")
local unavailableGuild = require("../../guild/unavailableGuild")
local member = require("../../guild/member")
local user = require("../../user")
local message = require("../../message/message")
local permission = require("../../permission")
local entitlement = require("../../entitlement")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

--[=[
	@within Classes.InteractionBehaviour
	@private

	Responsible for inheriting properties from the interaction data to the class instance.
	This function initializes all the properties of an Interaction instance based on the provided interaction data.
]=]
function Interaction.Interface.inheritProperties(class: any, interactionData: apiTypes.InteractionObject)
	local entitlementArray = {}
	local authorizingIntegrationOwners = {}

	for _, entitlementData in next, interactionData.entitlements or {} do
		table.insert(entitlementArray, entitlement.new(entitlementData))
	end

	for integrationType, owner in ipairs(interactionData.authorizing_integration_owners) do
		if integrationType == 0 then
			authorizingIntegrationOwners.GuildInstall = owner
		elseif integrationType == 1 then
			authorizingIntegrationOwners.UserInstall = owner
		end
	end

	--[=[
		@prop type string
		@within Classes.InteractionBehaviour
		
		The type of interaction. This can be one of the following values:
		- "PING"
		- "APPLICATION_COMMAND"
		- "MESSAGE_COMPONENT"
		- "APPLICATION_COMMAND_AUTOCOMPLETE"
		- "MODAL_SUBMIT"
	]=]
	class.type = apiTypes.interaction.InteractionType[interactionData.type]

	--[=[
		@prop context string
		@within Classes.InteractionBehaviour
		
		The context type of the interaction. This can be one of the following values:
		- "GUILD"
		- "BOT_DM"
		- "PRIVATE_CHANNEL"
	]=]
	class.context = apiTypes.interaction.InteractionContextType[interactionData.context]

	--[=[
		@prop id string
		@within Classes.InteractionBehaviour
		
		The unique identifier for the interaction.
	]=]
	class.id = interactionData.id

	--[=[
		@prop applicationId string
		@within Classes.InteractionBehaviour
		
		The ID of the application this interaction is for.
	]=]
	class.applicationId = interactionData.application_id

	--[=[
		@prop data Classes.InteractionBehaviourData?
		@within Classes.InteractionBehaviour
		
		The data associated with the interaction. The structure of this data varies based on the interaction type.
	]=]
	class.data = interactionData.data and data.new(class.state, interactionData.data)

	--[=[
		@prop guild Classes.UnavailableGuild?
		@within Classes.InteractionBehaviour
		
		The guild where the interaction was triggered. This is only present for guild interactions.
	]=]
	class.guild = interactionData.guild and unavailableGuild.new(class.state, interactionData.guild.id :: string)

	--[=[
		@prop guildId string?
		@within Classes.InteractionBehaviour
		
		The ID of the guild where the interaction was triggered. This is only present for guild interactions.
	]=]
	class.guildId = interactionData.guild_id

	--[=[
		@prop channelId string?
		@within Classes.InteractionBehaviour
		
		The ID of the channel where the interaction was triggered.
	]=]
	class.channelId = interactionData.channel_id

	--[=[
		@prop member Classes.Member?
		@within Classes.InteractionBehaviour
		
		The member who triggered the interaction. This is only present for guild interactions.
	]=]
	class.member = interactionData.member
		and member.new(class.state, interactionData.guild_id :: string, interactionData.member)

	--[=[
		@prop user Classes.User?
		@within Classes.InteractionBehaviour
		
		The user who triggered the interaction.
	]=]
	class.user = interactionData.user and user.new(interactionData.user)

	--[=[
		@prop token string
		@within Classes.InteractionBehaviour
		
		The token used for responding to the interaction.
	]=]
	class.token = interactionData.token

	--[=[
		@prop version number
		@within Classes.InteractionBehaviour
		
		The version of the interaction.
	]=]
	class.version = interactionData.version

	--[=[
		@prop message Classes.Message?
		@within Classes.InteractionBehaviour
		
		The message that triggered the interaction. This is only present for message component interactions.
	]=]
	class.message = interactionData.message and message.new(class.state, interactionData.message)

	--[=[
		@prop appPermissions Classes.Permission
		@within Classes.InteractionBehaviour
		
		The permissions the application has in the channel where the interaction was triggered.
	]=]
	class.appPermissions = permission.new(interactionData.app_permissions)

	--[=[
		@prop locale string?
		@within Classes.InteractionBehaviour
		
		The selected language of the user who triggered the interaction.
	]=]
	class.locale = interactionData.locale

	--[=[
		@prop guildLocale string?
		@within Classes.InteractionBehaviour
		
		The guild's preferred locale, if the interaction was triggered in a guild.
	]=]
	class.guildLocale = interactionData.guild_locale

	--[=[
		@prop entitlements {Classes.Entitlement}
		@within Classes.InteractionBehaviour
		
		The entitlements for the user who triggered the interaction.
	]=]
	class.entitlements = entitlementArray

	--[=[
		@prop authorizingIntegrationOwners {[string]: string}
		@within Classes.InteractionBehaviour
		
		The mapping of integration types to their respective owners.
	]=]
	class.authorizingIntegrationOwners = authorizingIntegrationOwners
end

--[=[
	@within Classes.InteractionBehaviour
	@private

	Responsible for inheriting methods from the Interaction prototype to the class instance.
	This function copies all methods from the Interaction.Prototype to the provided class instance.
]=]
function Interaction.Interface.inheritMethods(class: any)
	for key, value in Interaction.Prototype do
		class[key] = value
	end
end

export type InteractionMethods = typeof(Interaction.Prototype)
export type InteractionProperties = {
	state: state.State,

	id: apiTypes.Snowflake,
	applicationId: apiTypes.Snowflake,
	type: apiTypes.InteractionType,
	data: data.Data?,
	guild: unavailableGuild.UnavailableGuild?,
	guildId: apiTypes.Snowflake?,
	channelId: apiTypes.Snowflake?,
	member: member.Member?,
	user: user.User?,
	token: string,
	version: number,
	message: message.Message?,
	appPermissions: permission.Permission,
	locale: apiTypes.LanguageLocales?,
	guildLocale: apiTypes.LanguageLocales?,
	entitlements: { entitlement.Entitlement },
	authorizingIntegrationOwners: {
		[apiTypes.IntegrationTypesConfig]: apiTypes.Snowflake,
	},
	context: apiTypes.InteractionContextType?,
}

export type Interaction = InteractionMethods & InteractionProperties

return Interaction.Interface
