--[=[
	@class Classes.PrimaryGuild
	@__index Prototype

	Implementation of the Discord User Primary Guild class in Luau

	https://docs.discord.com/developers/resources/user#user-object-user-primary-guild
]=]

--[=[
	@prop identityGuildId string?
	@within Classes.PrimaryGuild
	The guild's ID
]=]

--[=[
	@prop identityEnabled boolean?
	@within Classes.PrimaryGuild
	Whether the guild identity (tag) is enabled
]=]

--[=[
	@prop tag string?
	@within Classes.PrimaryGuild
	The guild's tag shown on the user's profile (1-4 characters)
]=]

--[=[
	@prop badge string?
	@within Classes.PrimaryGuild
	The guild's badge icon hash
]=]

local apiTypes = require("../luau_packages/api_types")

local PrimaryGuild = {}

PrimaryGuild.Interface = {}
PrimaryGuild.Prototype = {}

--[=[
	@within Classes.PrimaryGuild
	@private

	Responsible for syncing data to this primary guild object. This is typically called by the API when this object is
	created or updated.
]=]
function PrimaryGuild.Prototype.sync(self: PrimaryGuild, primaryGuildData: apiTypes.UserPrimaryGuildObject)
	self.identityGuildId = primaryGuildData.identity_guild_id

	self.identityEnabled = primaryGuildData.identity_enabled

	self.tag = primaryGuildData.tag

	self.badge = primaryGuildData.badge
end

--[=[
	@within Classes.PrimaryGuild
	@private

	Responsible for constructing this class.
]=]
function PrimaryGuild.Interface.new(primaryGuildData: apiTypes.UserPrimaryGuildObject): PrimaryGuild
	local self = setmetatable({} :: PrimaryGuild, { __index = PrimaryGuild.Prototype })

	self:sync(primaryGuildData)

	return self
end

export type PrimaryGuild = typeof(PrimaryGuild.Prototype) & {
	identityGuildId: apiTypes.Snowflake?,
	identityEnabled: boolean?,
	tag: string?,
	badge: string?,
}

return PrimaryGuild.Interface
