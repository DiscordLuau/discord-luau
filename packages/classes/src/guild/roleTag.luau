--[[
	Implementation of the Discord RoleTag class in Luau

	https://discord.com/developers/docs/topics/permissions#role-object-role-tags-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local RoleTag = {}

RoleTag.Interface = {}
RoleTag.Prototype = {}

function RoleTag.Prototype.sync(self: RoleTag, roleTagData: apiTypes.GuildRoleTagObject)
	self.botId = roleTagData.bot_id
	self.integrationId = roleTagData.integration_id
	self.premiumSubscriber = roleTagData.premium_subscriber
	self.subscriptionListingId = roleTagData.subscription_listing_id
	self.availableForPurchase = roleTagData.available_for_purchase
	self.guildConnections = roleTagData.guild_connections
end

function RoleTag.Interface.new(roleTagData: apiTypes.GuildRoleTagObject): RoleTag
	local self = setmetatable({} :: RoleTag, { __index = RoleTag.Prototype })

	self:sync(roleTagData)

	return self
end

export type RoleTag = typeof(RoleTag.Prototype) & {
	botId: apiTypes.Snowflake?,
	integrationId: apiTypes.Snowflake?,
	premiumSubscriber: nil?,
	subscriptionListingId: apiTypes.Snowflake?,
	availableForPurchase: nil?,
	guildConnections: nil?,
}

return RoleTag.Interface
