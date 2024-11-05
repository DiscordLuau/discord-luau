--[[
	Implementation of the Discord Role class in Luau

	https://discord.com/developers/docs/topics/permissions#role-object
]]

local apiTypes = require("@api-types/apiTypes")

local roleTags = require("@classes/guild/roleTag")
local roleBitflag = require("@classes/bitflags/role")

local Role = {}

Role.Interface = {}
Role.Prototype = {}

-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
-- https://discord.com/developers/docs/resources/guild#modify-guild-role
-- https://discord.com/developers/docs/resources/guild#delete-guild-role

function Role.Prototype.sync(self: Role, roleData: apiTypes.GuildRoleObject)
	local tagArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, tagData in next, roleData.tags or {} do
		table.insert(tagArray, roleTags.new(tagData))
	end

	self.flags = roleBitflag.new(roleData.flags)

	self.tags = tagArray
	self.id = roleData.id
	self.name = roleData.name
	self.color = roleData.color
	self.hoist = roleData.hoist
	self.icon = roleData.icon
	self.unicodeEmoji = roleData.unicode_emoji
	self.position = roleData.position
	self.permissions = roleData.permissions
	self.managed = roleData.managed
	self.mentionable = roleData.mentionable
end

function Role.Interface.new(roleData: apiTypes.GuildRoleObject): Role
	local self = setmetatable({} :: Role, { __index = Role.Prototype })

	self:sync(roleData)

	return self
end

export type Role = typeof(Role.Prototype) & {
	id: apiTypes.Snowflake?,
	name: string,
	color: number,
	hoist: boolean,
	icon: string?,
	unicodeEmoji: string?,
	position: number,
	permissions: string,
	managed: boolean,
	mentionable: boolean,
	tags: { roleTags.RoleTag }?,
	flags: roleBitflag.RoleBitflag,
}

return Role.Interface
