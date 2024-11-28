--[[
	Implementation of the Discord RoleSubscriptionData class in Luau

	https://discord.com/developers/docs/resources/message#role-subscription-data-object
]]

local apiTypes = require("../../lune_packages/api_types")

local RoleSubscriptionData = {}

RoleSubscriptionData.Interface = {}
RoleSubscriptionData.Prototype = {}

function RoleSubscriptionData.Prototype.sync(
	self: RoleSubscriptionData,
	subscriptionData: apiTypes.RoleSubscriptionDataObject
)
	self.roleSubscriptionListingId = subscriptionData.role_subscription_listing_id
	self.tierName = subscriptionData.tier_name
	self.totalMonthsSubscribed = subscriptionData.total_months_subscribed
	self.isRenewal = subscriptionData.is_renewal
end

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
