--[[
	Implementation of the Discord Entitlement class in Luau

	https://discord.com/developers/docs/monetization/entitlements#entitlement-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")
local entitlementTypes = require("@api-types/entitlement")

local Entitlement = {}

Entitlement.Interface = {}
Entitlement.Prototype = {}

function Entitlement.Prototype.sync(self: Entitlement, entitlementData: apiTypes.EntitlementObject)
	self.type = (
		entitlementData.type == 1 and "Purchase"
		or entitlementData.type == 2 and "PremiumSubscription"
		or entitlementData.type == 3 and "DeveloperGift"
		or entitlementData.type == 4 and "TestModePurchase"
		or entitlementData.type == 5 and "FreePurchase"
		or entitlementData.type == 6 and "UserGift"
		or entitlementData.type == 7 and "PremiumPurchase"
		or entitlementData.type == 8 and "ApplicationSubscription"
	) :: entitlementTypes.EntitlementType

	self.id = entitlementData.id
	self.skuId = entitlementData.sku_id
	self.applicationId = entitlementData.application_id
	self.userId = entitlementData.user_id
	self.deleted = entitlementData.deleted
	self.startsAt = entitlementData.starts_at and datetime.fromIsoDate(entitlementData.starts_at)
	self.endsAt = entitlementData.ends_at and datetime.fromIsoDate(entitlementData.ends_at)
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
	type: entitlementTypes.EntitlementType,
	deleted: boolean,
	startsAt: datetime.DateTime?,
	endsAt: datetime.DateTime?,
	guildId: apiTypes.Snowflake?,
	consumed: boolean?,
}

return Entitlement.Interface
