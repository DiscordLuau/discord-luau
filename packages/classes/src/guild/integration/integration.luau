--[[
	Implementation of the Discord Integration class in Luau

	https://discord.com/developers/docs/resources/integration#integration-object
]]

local apiTypes = require("../../../lune_packages/api_types")
local stdPolyfills = require("../../../lune_packages/std_polyfills")

local account = require("./account")
local application = require("./application")

local user = require("../../user")

local Integration = {}

Integration.Interface = {}
Integration.Prototype = {}

function Integration.Prototype.sync(self: Integration, integrationData: apiTypes.IntegrationObject)
	self.id = integrationData.id
	self.name = integrationData.name
	self.type = apiTypes.guild.IntegrationType[integrationData.type]
	self.enabled = integrationData.enabled
	self.syncing = integrationData.syncing
	self.roleId = integrationData.role_id
	self.enableEmoticons = integrationData.enable_emoticons
	self.expireBehavior = apiTypes.guild.IntegrationExpireBehaviour[integrationData.expire_behaviour]
	self.expireGracePeriod = integrationData.expire_grace_period
	self.user = integrationData.user and user.new(integrationData.user)
	self.account = integrationData.account and account.new(integrationData.account)
	self.syncedAt = integrationData.synced_at and stdPolyfills.datetime.fromIsoDate(integrationData.synced_at)
	self.subscriberCount = integrationData.subscriber_count
	self.revoked = integrationData.revoked
	self.application = integrationData.application and application.new(integrationData.application)
	self.scopes = integrationData.scopes
end

function Integration.Interface.new(integrationData: apiTypes.IntegrationObject): Integration
	local self = setmetatable({} :: Integration, { __index = Integration.Prototype })

	self:sync(integrationData)

	return self
end

export type Integration = typeof(Integration.Prototype) & {
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
