--[=[
	@class Classes.Guild.InviteGuild
	@__index Prototype

	Implementation of the partial guild object returned inside Discord invite responses.

	https://discord.com/developers/docs/resources/invite#invite-object
]=]

--[=[
	@prop id string
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop name string
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop icon string?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop splash string?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop banner string?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop description string?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop features { apiTypes.GuildFeature }
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop verificationLevel apiTypes.VerificationLevel?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop vanityUrlCode string?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop nsfwLevel number?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop premiumSubscriptionCount number?
	@within Classes.Guild.InviteGuild
]=]

--[=[
	@prop roles { apiTypes.Snowflake }
	@within Classes.Guild.InviteGuild
	IDs of roles present in this guild.
]=]

local apiTypes = require("../../luau_packages/api_types")

local InviteGuild = {}

InviteGuild.Interface = {}
InviteGuild.Prototype = {}

--[=[
	@within Classes.Guild.InviteGuild
]=]
function InviteGuild.Prototype.sync(self: InviteGuild, guildData: apiTypes.InviteGuildObject)
	local roleIds = {}

	for _, role in next, guildData.roles or {} do
		table.insert(roleIds, role.id)
	end

	self.id = guildData.id
	self.name = guildData.name
	self.icon = guildData.icon
	self.splash = guildData.splash
	self.banner = guildData.banner
	self.description = guildData.description
	self.features = guildData.features
	self.verificationLevel = guildData.verification_level :: any
	self.vanityUrlCode = guildData.vanity_url_code
	self.nsfwLevel = guildData.nsfw_level
	self.premiumSubscriptionCount = guildData.premium_subscription_count
	self.roles = roleIds
end

--[=[
	@within Classes.Guild.InviteGuild
]=]
function InviteGuild.Interface.new(guildData: apiTypes.InviteGuildObject): InviteGuild
	local self = setmetatable({} :: InviteGuild, { __index = InviteGuild.Prototype })

	self:sync(guildData)

	return self
end

export type InviteGuild = typeof(InviteGuild.Prototype) & {
	id: apiTypes.Snowflake,
	name: string,
	icon: string?,
	splash: string?,
	banner: string?,
	description: string?,
	features: { apiTypes.GuildFeature },
	verificationLevel: apiTypes.VerificationLevel?,
	vanityUrlCode: string?,
	nsfwLevel: number?,
	premiumSubscriptionCount: number?,
	roles: { apiTypes.Snowflake },
}

return InviteGuild.Interface
