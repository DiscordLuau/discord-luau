--[[
	Implementation of the Discord Interaction class in Luau

https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
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

function Interaction.Prototype.sync(self: Interaction, interactionData: apiTypes.InteractionObject)
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

	self.type = interactionTypes.InteractionType[interactionData.type]
	self.context = interactionTypes.InteractionContextType[interactionData.context]

	self.id = interactionData.id
	self.applicationId = interactionData.application_id
	self.data = interactionData.data and data.new(self.state, interactionData.data)
	self.guild = interactionData.guild and unavailableGuild.new(self.state, interactionData.guild.id)
	self.guildId = interactionData.guild_id
	-- self.channel = interactionData.channel and message.new(self.state, interactionData.channel)
	self.channelId = interactionData.channel_id
	self.member = interactionData.member and member.new(interactionData.member)
	self.user = interactionData.user and user.new(interactionData.user)
	self.token = interactionData.token
	self.version = interactionData.version
	self.message = interactionData.message and message.new(self.state, interactionData.message)
	self.appPermissions = permission.new(interactionData.app_permissions)
	self.locale = interactionData.locale
	self.guildLocale = interactionData.guild_locale
	self.entitlements = entitlementArray
	self.authorizingIntegrationOwners = authorizingIntegrationOwners
end

function Interaction.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Interaction
	local self = setmetatable(
		{
			state = state,
		} :: Interaction,
		{ __index = Interaction.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Interaction = typeof(Interaction.Prototype) & {
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

return Interaction.Interface
