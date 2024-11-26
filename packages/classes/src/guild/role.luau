--[[
	Implementation of the Discord Role class in Luau

	https://discord.com/developers/docs/topics/permissions#role-object
]]

local apiTypes = require("@api-types/apiTypes")
local permissionTypes = require("@api-types/permission")

local future = require("@vendor/future")

local roleTags = require("@classes/guild/roleTag")
local roleBitflag = require("@classes/bitflags/role")
local permission = require("@classes/permission")

local roleBuilder = require("@builders/guild/role")
local permissionBuilder = require("@builders/permission")

local state = require("@classes/state")

local guildRest = require("@rest/guild")

local Role = {}

Role.Interface = {}
Role.Prototype = {}

--[[
	Delete a guild role. Requires the MANAGE_ROLES permission. 
]]
function Role.Prototype.deleteAsync(self: Role, reason: string?): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.deleteGuildRoleAsync(request, self.guildId, self.id, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Modify a guild role. Requires the MANAGE_ROLES permission. Returns the updated role on success.
]]
function Role.Prototype.modifyAsync(self: Role, json: roleBuilder.JSON, reason: string?): future.Future<Role>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.modifyGuildRoleAsync(request, self.guildId, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		self:sync(response)

		return self
	end)
end

--[[
	Modify the positions of a set of role objects for the guild. Requires the MANAGE_ROLES permission. 
]]
function Role.Prototype.modifyPositionAsync(self: Role, position: number, reason: string?): future.Future<{ Role }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.modifyGuildRolePositionsAsync(request, self.guildId, {
				id = self.id,
				position = position,
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		local guildRoles = {}

		for _, roleData in response do
			table.insert(guildRoles, Role.Interface.new(self.state, self.guildId, roleData))
		end

		return guildRoles
	end)
end

--[[
	Sets the name of the role.
]]
function Role.Prototype.setNameAsync(self: Role, name: string, reason: string?): future.Future<Role>
	return self:modifyAsync({
		name = name,
	}, reason)
end

--[[
	Adds a permission to the role's current permission set.
]]
function Role.Prototype.addPermissionAsync(
	self: Role,
	permission: permissionTypes.Permissions,
	reason: string?
): future.Future<Role>
	local permissionBuilder = permissionBuilder.fromPermissions(self.permissions:toList())

	permissionBuilder:addPermission(permission)

	return self:modifyAsync({
		permissions = permissionBuilder:build(),
	}, reason)
end

--[[
	Removes a permission from the role's current permission set.
]]
function Role.Prototype.removePermissionAsync(
	self: Role,
	permission: permissionTypes.Permissions,
	reason: string?
): future.Future<Role>
	local permissionBuilder = permissionBuilder.fromPermissions(self.permissions:toList())

	permissionBuilder:removePermission(permission)

	return self:modifyAsync({
		permissions = permissionBuilder:build(),
	}, reason)
end

--[[
	Sets the color of the role.
]]
function Role.Prototype.setColorAsync(self: Role, color: number, reason: string?): future.Future<Role>
	return self:modifyAsync({
		color = color,
	}, reason)
end

--[[
	Sets whether the role should be displayed separately in the member list.
]]
function Role.Prototype.setHoistedAsync(self: Role, hoisted: boolean, reason: string?): future.Future<Role>
	return self:modifyAsync({
		hoist = hoisted,
	}, reason)
end

--[[
	Sets the icon image for the role.
]]
function Role.Prototype.setIconAsync(self: Role, iconData: string, reason: string?): future.Future<Role>
	return self:modifyAsync({
		icon = iconData,
	}, reason)
end

--[[
	Sets the unicode emoji for the role.
]]
function Role.Prototype.setEmojiAsync(self: Role, emoji: string, reason: string?): future.Future<Role>
	return self:modifyAsync({
		emoji = emoji,
	}, reason)
end

--[[
	Sets the role to be mentionable through the @ mention.
]]
function Role.Prototype.setMentionableAsync(self: Role, mentionable: boolean, reason: string?): future.Future<Role>
	return self:modifyAsync({
		mentionable = mentionable,
	}, reason)
end
function Role.Prototype.sync(self: Role, roleData: apiTypes.GuildRoleObject)
	local tagArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, tagData in next, roleData.tags or {} do
		table.insert(tagArray, roleTags.new(tagData))
	end

	self.flags = roleBitflag.new(roleData.flags)

	self.tags = tagArray
	self.id = roleData.id :: string
	self.name = roleData.name
	self.color = roleData.color
	self.hoist = roleData.hoist
	self.icon = roleData.icon
	self.unicodeEmoji = roleData.unicode_emoji
	self.position = roleData.position
	self.permissions = roleData.permissions and permission.new(roleData.permissions)
	self.managed = roleData.managed
	self.mentionable = roleData.mentionable
end

function Role.Interface.new(state: state.State, guildId: apiTypes.Snowflake, roleData: apiTypes.GuildRoleObject): Role
	local self = setmetatable(
		{
			state = state,
			guildId = guildId,
		} :: Role,
		{ __index = Role.Prototype }
	)

	self:sync(roleData)

	return self
end

export type Role = typeof(Role.Prototype) & {
	state: state.State,
	guildId: apiTypes.Snowflake,
	id: apiTypes.Snowflake,

	name: string,
	color: number,
	hoist: boolean,
	icon: string?,
	unicodeEmoji: string?,
	position: number,
	permissions: permission.Permission,
	managed: boolean,
	mentionable: boolean,
	tags: { roleTags.RoleTag }?,
	flags: roleBitflag.RoleBitflag,
}

return Role.Interface
