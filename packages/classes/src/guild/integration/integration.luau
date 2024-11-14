--[[
	Implementation of the Discord Integration class in Luau

	https://discord.com/developers/docs/resources/integration#integration-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")
local guildTypes = require("@api-types/guild")

local account = require("@classes/guild/integration/account")
local application = require("@classes/guild/integration/application")

local user = require("@classes/user")

local Integration = {}

Integration.Interface = {}
Integration.Prototype = {}

function Integration.Prototype.sync(self: Integration, integrationData: apiTypes.IntegrationObject)
	self.id = integrationData.id
	self.name = integrationData.name
	self.type = guildTypes.IntegrationType[integrationData.type]
	self.enabled = integrationData.enabled
	self.syncing = integrationData.syncing
	self.roleId = integrationData.role_id
	self.enableEmoticons = integrationData.enable_emoticons
	self.expireBehavior = guildTypes.IntegrationExpireBehaviour[integrationData.expire_behaviour]
	self.expireGracePeriod = integrationData.expire_grace_period
	self.user = integrationData.user and user.new(integrationData.user)
	self.account = integrationData.account and account.new(integrationData.account)
	self.syncedAt = integrationData.synced_at and datetime.fromIsoDate(integrationData.synced_at)
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
	type: guildTypes.IntegrationType,
	enabled: boolean,
	syncing: boolean?,
	roleId: apiTypes.Snowflake?,
	enableEmoticons: boolean?,
	expireBehavior: guildTypes.IntegrationExpireBehaviour,
	expireGracePeriod: number?,
	user: user.User?,
	account: account.Account,
	syncedAt: datetime.DateTime?,
	subscriberCount: number?,
	revoked: boolean?,
	application: application.Application?,
	scopes: { apiTypes.OAuth2Scopes }?,
}

return Integration.Interface
