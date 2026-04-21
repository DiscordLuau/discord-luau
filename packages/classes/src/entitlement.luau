--[=[
	@class Classes.Entitlement
	@__index Prototype

	Implementation of the Discord Entitlement class in Luau

	https://discord.com/developers/docs/monetization/entitlements#entitlement-object
]=]

--[=[
	@prop type apiTypes.EntitlementType
	@within Classes.Entitlement
	The type of entitlement this object represents. Maps to Discord's entitlement types.
]=]

--[=[
	@prop id apiTypes.Snowflake
	@within Classes.Entitlement
	The unique identifier for this entitlement.
]=]

--[=[
	@prop skuId apiTypes.Snowflake
	@within Classes.Entitlement
	The ID of the SKU (Stock Keeping Unit) that this entitlement grants access to.
]=]

--[=[
	@prop applicationId apiTypes.Snowflake
	@within Classes.Entitlement
	The ID of the application this entitlement is for.
]=]

--[=[
	@prop userId apiTypes.Snowflake?
	@within Classes.Entitlement
	The ID of the user this entitlement belongs to. May be null for some entitlement types.
]=]

--[=[
	@prop deleted boolean
	@within Classes.Entitlement
	Whether this entitlement has been deleted.
]=]

--[=[
	@prop startsAt stdPolyfills.DateTime?
	@within Classes.Entitlement
	The date and time when this entitlement becomes active. May be null for permanent entitlements.
]=]

--[=[
	@prop endsAt stdPolyfills.DateTime?
	@within Classes.Entitlement
	The date and time when this entitlement expires. May be null for permanent entitlements.
]=]

--[=[
	@prop guildId apiTypes.Snowflake?
	@within Classes.Entitlement
	The ID of the guild this entitlement is for. May be null for user-specific entitlements.
]=]

--[=[
	@prop consumed boolean?
	@within Classes.Entitlement
	Whether this entitlement has been consumed. Only applicable to consumable entitlements.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local apiTypes = require("../luau_packages/api_types")

local Entitlement = {}

Entitlement.Interface = {}
Entitlement.Prototype = {}

--[=[
	@within Classes.Entitlement
	@private

	Responsible for syncing data to this entitlement object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.Entitlement
	@private

	Responsible for constructing this class.
]=]
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
