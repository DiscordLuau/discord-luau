--[=[
	@class Classes.Integration
	@__index Prototype

	Implementation of the Discord Integration class in Luau

	https://discord.com/developers/docs/resources/integration#integration-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")
local rest = require("../../../lune_packages/rest")
local stdPolyfills = require("../../../lune_packages/std_polyfills")
local future = require("../../../luau_packages/future")

local account = require("./account")
local application = require("./application")

local user = require("../../user")

local Integration = {}

Integration.Interface = {}
Integration.Prototype = {}

--[=[
	@within Classes.Integration
	Delete the attached integration object for the guild. Deletes any associated webhooks and kicks the associated bot
	if there is one. Requires the MANAGE_GUILD permission.
]=]
function Integration.Prototype.deleteAsync(self: Integration, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.guildId, "guild id not found!")

		local response = rest.guild.deleteGuildIntegrationAsync(request, self.guildId, self.id, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Integration
	@private
]=]
function Integration.Prototype.sync(self: Integration, integrationData: apiTypes.IntegrationObject)
	--[=[
		@prop id string
		@within Classes.Integration
		The integration's id
	]=]
	self.id = integrationData.id

	--[=[
		@prop name string
		@within Classes.Integration
		The integration's name
	]=]
	self.name = integrationData.name

	--[=[
		@prop type apiTypes.IntegrationType
		@within Classes.Integration
		Integration type (twitch, youtube, discord, or guild_subscription)
	]=]
	self.type = apiTypes.guild.IntegrationType[integrationData.type]

	--[=[
		@prop enabled boolean
		@within Classes.Integration
		Whether this integration is enabled
	]=]
	self.enabled = integrationData.enabled

	--[=[
		@prop syncing boolean?
		@within Classes.Integration
		Whether this integration is syncing
	]=]
	self.syncing = integrationData.syncing

	--[=[
		@prop roleId string?
		@within Classes.Integration
		ID that this integration uses for "subscribers"
	]=]
	self.roleId = integrationData.role_id

	--[=[
		@prop enableEmoticons boolean?
		@within Classes.Integration
		Whether emoticons should be synced for this integration
	]=]
	self.enableEmoticons = integrationData.enable_emoticons

	--[=[
		@prop expireBehavior apiTypes.IntegrationExpireBehaviour
		@within Classes.Integration
		The behavior of expiring subscribers
	]=]
	self.expireBehavior = apiTypes.guild.IntegrationExpireBehaviour[integrationData.expire_behaviour]

	--[=[
		@prop expireGracePeriod number?
		@within Classes.Integration
		The grace period (in days) before expiring subscribers
	]=]
	self.expireGracePeriod = integrationData.expire_grace_period

	--[=[
		@prop user Classes.User?
		@within Classes.Integration
		User for this integration
	]=]
	self.user = integrationData.user and user.new(integrationData.user)

	--[=[
		@prop account Classes.Account
		@within Classes.Integration
		Integration account information
	]=]
	self.account = integrationData.account and account.new(integrationData.account)

	--[=[
		@prop syncedAt stdPolyfills.DateTime?
		@within Classes.Integration
		When this integration was last synced
	]=]
	self.syncedAt = integrationData.synced_at and stdPolyfills.datetime.fromIsoDate(integrationData.synced_at)

	--[=[
		@prop subscriberCount number?
		@within Classes.Integration
		How many subscribers this integration has
	]=]
	self.subscriberCount = integrationData.subscriber_count

	--[=[
		@prop revoked boolean?
		@within Classes.Integration
		Whether this integration has been revoked
	]=]
	self.revoked = integrationData.revoked

	--[=[
		@prop application Classes.Application?
		@within Classes.Integration
		The bot/OAuth2 application for discord integrations
	]=]
	self.application = integrationData.application and application.new(integrationData.application)

	--[=[
		@prop scopes { apiTypes.OAuth2Scopes }?
		@within Classes.Integration
		The scopes the application has been authorized for
	]=]
	self.scopes = integrationData.scopes
end

--[=[
	@within Classes.Integration
	@private
]=]
function Integration.Interface.new(
	state: state.State,
	guildId: apiTypes.Snowflake?,
	integrationData: apiTypes.IntegrationObject
): Integration
	local self = setmetatable(
		{
			state = state,
			guildId = guildId,
		} :: Integration,
		{ __index = Integration.Prototype }
	)

	self:sync(integrationData)

	return self
end

export type Integration = typeof(Integration.Prototype) & {
	state: state.State,
	guildId: apiTypes.Snowflake?,

	id: apiTypes.Snowflake,
	name: string,
	type: apiTypes.IntegrationType,
	enabled: boolean,
	syncing: boolean?,
	roleId: apiTypes.Snowflake?,
	enableEmoticons: boolean?,
	expireBehavior: apiTypes.IntegrationExpireBehaviour,
	expireGracePeriod: number?,
	user: user.User?,
	account: account.Account,
	syncedAt: stdPolyfills.DateTime?,
	subscriberCount: number?,
	revoked: boolean?,
	application: application.Application?,
	scopes: { apiTypes.OAuth2Scopes }?,
}

return Integration.Interface
