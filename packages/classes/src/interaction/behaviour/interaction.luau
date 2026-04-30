--[=[
	@class Classes.Interactions.InteractionBehaviour
	@__index Prototype

	Represents a Discord Interaction object that implements the Discord Interaction class in Luau.
	This class serves as the base for all interaction types in Discord.

	 https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object
]=]

--[=[
	@prop type string
	@within Classes.Interactions.InteractionBehaviour
	
	The type of interaction. This can be one of the following values:
	- "PING"
	- "APPLICATION_COMMAND"
	- "MESSAGE_COMPONENT"
	- "APPLICATION_COMMAND_AUTOCOMPLETE"
	- "MODAL_SUBMIT"
]=]

--[=[
	@prop context string
	@within Classes.Interactions.InteractionBehaviour
	
	The context type of the interaction. This can be one of the following values:
	- "GUILD"
	- "BOT_DM"
	- "PRIVATE_CHANNEL"
]=]

--[=[
	@prop id string
	@within Classes.Interactions.InteractionBehaviour
	
	The unique identifier for the interaction.
]=]

--[=[
	@prop applicationId string
	@within Classes.Interactions.InteractionBehaviour
	
	The ID of the application this interaction is for.
]=]

--[=[
	@prop data Classes.InteractionBehaviourData?
	@within Classes.Interactions.InteractionBehaviour
	
	The data associated with the interaction. The structure of this data varies based on the interaction type.
]=]

--[=[
	@prop guild Classes.UnavailableGuild?
	@within Classes.Interactions.InteractionBehaviour
	
	The guild where the interaction was triggered. This is only present for guild interactions.
]=]

--[=[
	@prop guildId string?
	@within Classes.Interactions.InteractionBehaviour
	
	The ID of the guild where the interaction was triggered. This is only present for guild interactions.
]=]

--[=[
	@prop channelId string?
	@within Classes.Interactions.InteractionBehaviour
	
	The ID of the channel where the interaction was triggered.
]=]

--[=[
	@prop member Classes.Guild.Member?
	@within Classes.Interactions.InteractionBehaviour
	
	The member who triggered the interaction. This is only present for guild interactions.
]=]

--[=[
	@prop user Classes.User?
	@within Classes.Interactions.InteractionBehaviour
	
	The user who triggered the interaction.
]=]

--[=[
	@prop token string
	@within Classes.Interactions.InteractionBehaviour
	
	The token used for responding to the interaction.
]=]

--[=[
	@prop version number
	@within Classes.Interactions.InteractionBehaviour
	
	The version of the interaction.
]=]

--[=[
	@prop message Classes.Message?
	@within Classes.Interactions.InteractionBehaviour
	
	The message that triggered the interaction. This is only present for message component interactions.
]=]

--[=[
	@prop appPermissions Classes.Permission
	@within Classes.Interactions.InteractionBehaviour
	
	The permissions the application has in the channel where the interaction was triggered.
]=]

--[=[
	@prop locale string?
	@within Classes.Interactions.InteractionBehaviour
	
	The selected language of the user who triggered the interaction.
]=]

--[=[
	@prop guildLocale string?
	@within Classes.Interactions.InteractionBehaviour
	
	The guild's preferred locale, if the interaction was triggered in a guild.
]=]

--[=[
	@prop entitlements {Classes.Entitlement}
	@within Classes.Interactions.InteractionBehaviour
	
	The entitlements for the user who triggered the interaction.
]=]

--[=[
	@prop authorizingIntegrationOwners {[string]: string}
	@within Classes.Interactions.InteractionBehaviour
	
	The mapping of integration types to their respective owners.
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

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
	@within Classes.Interactions.InteractionBehaviour
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

	class.type = apiTypes.interaction.InteractionType[interactionData.type]

	class.context = apiTypes.interaction.InteractionContextType[interactionData.context]

	class.id = interactionData.id

	class.applicationId = interactionData.application_id

	class.data = interactionData.data and data.new(class.state, interactionData.data)

	class.guild = interactionData.guild and unavailableGuild.new(class.state, interactionData.guild.id :: string)

	class.guildId = interactionData.guild_id

	class.channelId = interactionData.channel_id

	class.member = interactionData.member
		and member.new(class.state, interactionData.guild_id :: string, interactionData.member)

	class.user = interactionData.user and user.new(interactionData.user)

	class.token = interactionData.token

	class.version = interactionData.version

	class.message = interactionData.message and message.new(class.state, interactionData.message)

	class.appPermissions = permission.new(interactionData.app_permissions)

	class.locale = interactionData.locale

	class.guildLocale = interactionData.guild_locale

	class.entitlements = entitlementArray

	class.authorizingIntegrationOwners = authorizingIntegrationOwners
end

--[=[
	@within Classes.Interactions.InteractionBehaviour
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
