--[[
	Voice Behaviour, responsible for implementing the various properties, and methods for a voice-able channels.
]]

local apiTypes = require("@api-types/apiTypes")
local applicationTypes = require("@api-types/application")
local interactionTypes = require("@api-types/interaction")

local data = require("@classes/interaction/data")
local unavailableGuild = require("@classes/guild/unavailableGuild")
local member = require("@classes/guild/member")
local user = require("@classes/user")
local message = require("@classes/message/message")
local permission = require("@classes/permission")
local entitlement = require("@classes/entitlement")
local state = require("@classes/state")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

function Interaction.Interface.inheritProperties(class: any, interactionData: apiTypes.InteractionObject)
	local entitlementArray = {}
	local authorizingIntegrationOwners = {}

	for _, entitlementData in next, interactionData.entitlements or {} do
		table.insert(entitlementArray, entitlement.new(entitlementData))
	end

	for integrationType, owner in ipairs(interactionData.authorizing_integration_owners) do
		-- todo: are these actually numbers or strings?

		if integrationType == 0 then
			authorizingIntegrationOwners.GuildInstall = owner
		elseif integrationType == 1 then
			authorizingIntegrationOwners.UserInstall = owner
		end
	end

	class.type = interactionTypes.InteractionType[interactionData.type]
	class.context = interactionTypes.InteractionContextType[interactionData.context]

	class.id = interactionData.id
	class.applicationId = interactionData.application_id
	class.data = interactionData.data and data.new(class.state, interactionData.data)
	class.guild = interactionData.guild and unavailableGuild.new(class.state, interactionData.guild.id :: string)
	class.guildId = interactionData.guild_id
	-- class.channel = interactionData.channel and message.new(class.state, interactionData.channel)
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
	type: interactionTypes.InteractionType,
	data: data.Data?,
	guild: unavailableGuild.UnavailableGuild?,
	guildId: apiTypes.Snowflake?,
	-- channel: apiTypes.Snowflake?, -- fixme: we can't type the channels since channels require this message class.
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
		[applicationTypes.IntegrationTypesConfig]: apiTypes.Snowflake,
	},
	context: interactionTypes.InteractionContextType?,
}

export type Interaction = InteractionMethods & InteractionProperties

return Interaction.Interface
