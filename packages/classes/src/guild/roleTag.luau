--[=[
	@class Classes.Guild.RoleTag
	@__index Prototype

	Implementation of the Discord RoleTag class in Luau

	https://discord.com/developers/docs/topics/permissions#role-object-role-tags-structure
]=]

--[=[
	@prop botId string?
	@within Classes.Guild.RoleTag
	The ID of the bot this role belongs to
]=]

--[=[
	@prop integrationId string?
	@within Classes.Guild.RoleTag
	The ID of the integration this role belongs to
]=]

--[=[
	@prop premiumSubscriber nil?
	@within Classes.Guild.RoleTag
	Whether this is the guild's premium subscriber role
]=]

--[=[
	@prop subscriptionListingId string?
	@within Classes.Guild.RoleTag
	The ID of the subscription listing this role is for
]=]

--[=[
	@prop availableForPurchase nil?
	@within Classes.Guild.RoleTag
	Whether this role is available for purchase
]=]

--[=[
	@prop guildConnections nil?
	@within Classes.Guild.RoleTag
	Whether this role is a guild's linked role
]=]

local apiTypes = require("../../luau_packages/api_types")

local RoleTag = {}

RoleTag.Interface = {}
RoleTag.Prototype = {}

--[=[
	@within Classes.Guild.RoleTag
	@private

	Responsible for syncing data to this role tag object. This is typically called by the API when this object is
	created or updated.
]=]
function RoleTag.Prototype.sync(self: RoleTag, roleTagData: apiTypes.GuildRoleTagObject)
	self.botId = roleTagData.bot_id

	self.integrationId = roleTagData.integration_id

	self.premiumSubscriber = roleTagData.premium_subscriber

	self.subscriptionListingId = roleTagData.subscription_listing_id

	self.availableForPurchase = roleTagData.available_for_purchase

	self.guildConnections = roleTagData.guild_connections
end

--[=[
	@within Classes.Guild.RoleTag
	@private

	Responsible for constructing this class.
]=]
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
