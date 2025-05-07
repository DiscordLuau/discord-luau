--[=[
	@class Classes.RoleTag
	@__index Prototype

	Implementation of the Discord RoleTag class in Luau

	https://discord.com/developers/docs/topics/permissions#role-object-role-tags-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local RoleTag = {}

RoleTag.Interface = {}
RoleTag.Prototype = {}

--[=[
	@within Classes.RoleTag
	@private

	Responsible for syncing data to this role tag object. This is typically called by the API when this object is
	created or updated.
]=]
function RoleTag.Prototype.sync(self: RoleTag, roleTagData: apiTypes.GuildRoleTagObject)
	--[=[
		@prop botId string?
		@within Classes.RoleTag
		The ID of the bot this role belongs to
	]=]
	self.botId = roleTagData.bot_id

	--[=[
		@prop integrationId string?
		@within Classes.RoleTag
		The ID of the integration this role belongs to
	]=]
	self.integrationId = roleTagData.integration_id

	--[=[
		@prop premiumSubscriber nil?
		@within Classes.RoleTag
		Whether this is the guild's premium subscriber role
	]=]
	self.premiumSubscriber = roleTagData.premium_subscriber

	--[=[
		@prop subscriptionListingId string?
		@within Classes.RoleTag
		The ID of the subscription listing this role is for
	]=]
	self.subscriptionListingId = roleTagData.subscription_listing_id

	--[=[
		@prop availableForPurchase nil?
		@within Classes.RoleTag
		Whether this role is available for purchase
	]=]
	self.availableForPurchase = roleTagData.available_for_purchase

	--[=[
		@prop guildConnections nil?
		@within Classes.RoleTag
		Whether this role is a guild's linked role
	]=]
	self.guildConnections = roleTagData.guild_connections
end

--[=[
	@within Classes.RoleTag
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
