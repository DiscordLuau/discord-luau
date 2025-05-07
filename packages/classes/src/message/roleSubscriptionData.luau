--[=[
	@class Classes.RoleSubscriptionData
	@__index Prototype

	Implementation of the Discord RoleSubscriptionData class in Luau

	https://discord.com/developers/docs/resources/message#role-subscription-data-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local RoleSubscriptionData = {}

RoleSubscriptionData.Interface = {}
RoleSubscriptionData.Prototype = {}

--[=[
	@within Classes.RoleSubscriptionData
	@private

	Responsible for syncing data to this role subscription data object. This is typically called by the API when this object is
	created or updated.
]=]
function RoleSubscriptionData.Prototype.sync(
	self: RoleSubscriptionData,
	subscriptionData: apiTypes.RoleSubscriptionDataObject
)
	--[=[
		@prop roleSubscriptionListingId string
		@within Classes.RoleSubscriptionData
		The ID of the role subscription listing.
	]=]
	self.roleSubscriptionListingId = subscriptionData.role_subscription_listing_id

	--[=[
		@prop tierName string
		@within Classes.RoleSubscriptionData
		The name of the subscription tier.
	]=]
	self.tierName = subscriptionData.tier_name

	--[=[
		@prop totalMonthsSubscribed number
		@within Classes.RoleSubscriptionData
		The total number of months this user has been subscribed.
	]=]
	self.totalMonthsSubscribed = subscriptionData.total_months_subscribed

	--[=[
		@prop isRenewal boolean
		@within Classes.RoleSubscriptionData
		Whether this is a renewal of an existing subscription.
	]=]
	self.isRenewal = subscriptionData.is_renewal
end

--[=[
	@within Classes.RoleSubscriptionData
	@private

	Responsible for constructing this class.
]=]
function RoleSubscriptionData.Interface.new(subscriptionData: apiTypes.RoleSubscriptionDataObject): RoleSubscriptionData
	local self = setmetatable({} :: RoleSubscriptionData, { __index = RoleSubscriptionData.Prototype })

	self:sync(subscriptionData)

	return self
end

export type RoleSubscriptionData = typeof(RoleSubscriptionData.Prototype) & {
	roleSubscriptionListingId: apiTypes.Snowflake,
	tierName: string,
	totalMonthsSubscribed: number,
	isRenewal: boolean,
}

return RoleSubscriptionData.Interface
