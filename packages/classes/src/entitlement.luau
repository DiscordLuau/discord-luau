--[[
	Implementation of the Discord Entitlement class in Luau

	https://discord.com/developers/docs/monetization/entitlements#entitlement-object
]]

local stdPolyfills = require("../lune_packages/std_polyfills")

local apiTypes = require("../lune_packages/api_types")

local Entitlement = {}

Entitlement.Interface = {}
Entitlement.Prototype = {}

function Entitlement.Prototype.sync(self: Entitlement, entitlementData: apiTypes.EntitlementObject)
	self.type = apiTypes.entitlement.EntitlementType[entitlementData.type]

	self.id = entitlementData.id
	self.skuId = entitlementData.sku_id
	self.applicationId = entitlementData.application_id
	self.userId = entitlementData.user_id
	self.deleted = entitlementData.deleted
	self.startsAt = entitlementData.starts_at and stdPolyfills.datetime.fromIsoDate(entitlementData.starts_at)
	self.endsAt = entitlementData.ends_at and stdPolyfills.datetime.fromIsoDate(entitlementData.ends_at)
	self.guildId = entitlementData.guild_id
	self.consumed = entitlementData.consumed
end

function Entitlement.Interface.new(entitlementData: apiTypes.EntitlementObject): Entitlement
	local self = setmetatable({} :: Entitlement, { __index = Entitlement.Prototype })

	self:sync(entitlementData)

	return self
end

export type Entitlement = typeof(Entitlement.Prototype) & {
	id: apiTypes.Snowflake,
	skuId: apiTypes.Snowflake,
	applicationId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake?,
	type: apiTypes.EntitlementType,
	deleted: boolean,
	startsAt: stdPolyfills.DateTime?,
	endsAt: stdPolyfills.DateTime?,
	guildId: apiTypes.Snowflake?,
	consumed: boolean?,
}

return Entitlement.Interface
