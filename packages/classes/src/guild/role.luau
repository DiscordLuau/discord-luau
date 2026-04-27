--[=[
	@class Classes.Guild.Role
	@__index Role.Prototype
	
	Implementation of the Discord Role class in Luau
	
	https://discord.com/developers/docs/topics/permissions#role-object
]=]

--[=[
	@within Classes.Guild.Role
	@prop flags Classes.RoleBitflag
	Role flags combined as a bitfield.
]=]

--[=[
	@within Classes.Guild.Role
	@prop tags { Classes.Guild.RoleTag }
	Tags associated with this role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop id string
	The ID of the role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop name string
	The name of the role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop color number
	The color of the role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop hoist boolean
	Whether the role is displayed separately in the member list.
]=]

--[=[
	@within Classes.Guild.Role
	@prop icon string
	The icon hash of the role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop unicodeEmoji string
	The unicode emoji of the role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop position number
	The position of the role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop permissions Classes.Permission
	The permissions of the role.
]=]

--[=[
	@within Classes.Guild.Role
	@prop managed boolean
	Whether the role is managed by an integration.
]=]

--[=[
	@within Classes.Guild.Role
	@prop mentionable boolean
	Whether the role is mentionable.
]=]

--[=[
	@prop state State
	@within Classes.Guild.Role
	The state object for this role.
]=]

--[=[
	@prop guildId string
	@within Classes.Guild.Role
	The ID of the guild this role belongs to.
]=]

local apiTypes = require("../../luau_packages/api_types")
local future = require("../../luau_packages/future")
local state = require("../../luau_packages/state")
local builders = require("../../luau_packages/builders")
local rest = require("../../luau_packages/rest")

local roleBitflag = require("../bitflags/role")
local permission = require("../permission")
local roleTags = require("./roleTag")

local Role = {}

Role.Interface = {}
Role.Prototype = {}

--[=[
	@within Classes.Guild.Role
	Delete a guild role. Requires the MANAGE_ROLES permission.
]=]
function Role.Prototype.deleteAsync(self: Role, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.deleteGuildRoleAsync(request, self.guildId, self.id, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Guild.Role
	Modify a guild role. Requires the MANAGE_ROLES permission. Returns the updated role on success.
]=]
function Role.Prototype.modifyAsync(self: Role, json: builders.roleJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.modifyGuildRoleAsync(request, self.guildId, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self:sync(response:unwrapOk())

		return self
	end) :: future.FutureLike<string, Role>
end

--[=[
	@within Classes.Guild.Role
	Modify the positions of a set of role objects for the guild. Requires the MANAGE_ROLES permission.
]=]
function Role.Prototype.modifyPositionAsync(self: Role, position: number, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.modifyGuildRolePositionsAsync(request, self.guildId, {
				id = self.id,
				position = position,
			}, reason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local guildRoles = {}

		for _, roleData in response:unwrapOk() do
			table.insert(guildRoles, Role.Interface.new(self.state, self.guildId, roleData))
		end

		return guildRoles
	end) :: future.FutureLike<string, { Role }>
end

--[=[
	@within Classes.Guild.Role
	Sets the name of the role.
]=]
function Role.Prototype.setNameAsync(self: Role, name: string, reason: string?)
	return self:modifyAsync({
		name = name,
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	Adds a permission to the role's current permission set.
]=]
function Role.Prototype.addPermissionAsync(self: Role, permission: apiTypes.Permissions, reason: string?)
	local permissionBuilder = builders.permission.fromPermissions(self.permissions:toList())

	permissionBuilder:addPermission(permission)

	return self:modifyAsync({
		permissions = permissionBuilder:build(),
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	Removes a permission from the role's current permission set.
]=]
function Role.Prototype.removePermissionAsync(self: Role, permission: apiTypes.Permissions, reason: string?)
	local permissionBuilder = builders.permission.fromPermissions(self.permissions:toList())

	permissionBuilder:removePermission(permission)

	return self:modifyAsync({
		permissions = permissionBuilder:build(),
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	Sets the color of the role.
]=]
function Role.Prototype.setColorAsync(self: Role, color: number, reason: string?)
	return self:modifyAsync({
		color = color,
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	Sets whether the role should be displayed separately in the member list.
]=]
function Role.Prototype.setHoistedAsync(self: Role, hoisted: boolean, reason: string?)
	return self:modifyAsync({
		hoist = hoisted,
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	Sets the icon image for the role.
]=]
function Role.Prototype.setIconAsync(self: Role, iconData: string, reason: string?)
	return self:modifyAsync({
		icon = iconData,
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	Sets the unicode emoji for the role.
]=]
function Role.Prototype.setEmojiAsync(self: Role, emoji: string, reason: string?)
	return self:modifyAsync({
		emoji = emoji,
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	Sets the role to be mentionable through the @ mention.
]=]
function Role.Prototype.setMentionableAsync(self: Role, mentionable: boolean, reason: string?)
	return self:modifyAsync({
		mentionable = mentionable,
	}, reason)
end

--[=[
	@within Classes.Guild.Role
	@private
	Synchronizes the role object with the data from the API.
]=]
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

--[=[
	@private
	@within Classes.Guild.Role
	Creates a new Role instance with the specified role data.
]=]
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
