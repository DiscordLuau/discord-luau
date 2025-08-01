--[=[
	@class Classes.Role
	@__index Role.Prototype
	
	Implementation of the Discord Role class in Luau
	
	https://discord.com/developers/docs/topics/permissions#role-object
]=]

local apiTypes = require("../../lune_packages/api_types")
local future = require("../../luau_packages/future")
local state = require("../../lune_packages/state")
local builders = require("../../lune_packages/builders")
local rest = require("../../lune_packages/rest")

local roleBitflag = require("../bitflags/role")
local permission = require("../permission")
local roleTags = require("./roleTag")

local Role = {}

Role.Interface = {}
Role.Prototype = {}

--[=[
	@within Classes.Role
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
	@within Classes.Role
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
	@within Classes.Role
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
	@within Classes.Role
	Sets the name of the role.
]=]
function Role.Prototype.setNameAsync(self: Role, name: string, reason: string?)
	return self:modifyAsync({
		name = name,
	}, reason)
end

--[=[
	@within Classes.Role
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
	@within Classes.Role
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
	@within Classes.Role
	Sets the color of the role.
]=]
function Role.Prototype.setColorAsync(self: Role, color: number, reason: string?)
	return self:modifyAsync({
		color = color,
	}, reason)
end

--[=[
	@within Classes.Role
	Sets whether the role should be displayed separately in the member list.
]=]
function Role.Prototype.setHoistedAsync(self: Role, hoisted: boolean, reason: string?)
	return self:modifyAsync({
		hoist = hoisted,
	}, reason)
end

--[=[
	@within Classes.Role
	Sets the icon image for the role.
]=]
function Role.Prototype.setIconAsync(self: Role, iconData: string, reason: string?)
	return self:modifyAsync({
		icon = iconData,
	}, reason)
end

--[=[
	@within Classes.Role
	Sets the unicode emoji for the role.
]=]
function Role.Prototype.setEmojiAsync(self: Role, emoji: string, reason: string?)
	return self:modifyAsync({
		emoji = emoji,
	}, reason)
end

--[=[
	@within Classes.Role
	Sets the role to be mentionable through the @ mention.
]=]
function Role.Prototype.setMentionableAsync(self: Role, mentionable: boolean, reason: string?)
	return self:modifyAsync({
		mentionable = mentionable,
	}, reason)
end

--[=[
	@within Classes.Role
	@private
	Synchronizes the role object with the data from the API.
]=]
function Role.Prototype.sync(self: Role, roleData: apiTypes.GuildRoleObject)
	local tagArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, tagData in next, roleData.tags or {} do
		table.insert(tagArray, roleTags.new(tagData))
	end

	--[=[
		@within Classes.Role
		@prop flags Classes.RoleBitflag
		Role flags combined as a bitfield.
	]=]
	self.flags = roleBitflag.new(roleData.flags)

	--[=[
		@within Classes.Role
		@prop tags { Classes.RoleTag }
		Tags associated with this role.
	]=]
	self.tags = tagArray

	--[=[
		@within Classes.Role
		@prop id string
		The ID of the role.
	]=]
	self.id = roleData.id :: string

	--[=[
		@within Classes.Role
		@prop name string
		The name of the role.
	]=]
	self.name = roleData.name

	--[=[
		@within Classes.Role
		@prop color number
		The color of the role.
	]=]
	self.color = roleData.color

	--[=[
		@within Classes.Role
		@prop hoist boolean
		Whether the role is displayed separately in the member list.
	]=]
	self.hoist = roleData.hoist

	--[=[
		@within Classes.Role
		@prop icon string
		The icon hash of the role.
	]=]
	self.icon = roleData.icon

	--[=[
		@within Classes.Role
		@prop unicodeEmoji string
		The unicode emoji of the role.
	]=]
	self.unicodeEmoji = roleData.unicode_emoji

	--[=[
		@within Classes.Role
		@prop position number
		The position of the role.
	]=]
	self.position = roleData.position

	--[=[
		@within Classes.Role
		@prop permissions Classes.Permission
		The permissions of the role.
	]=]
	self.permissions = roleData.permissions and permission.new(roleData.permissions)

	--[=[
		@within Classes.Role
		@prop managed boolean
		Whether the role is managed by an integration.
	]=]
	self.managed = roleData.managed

	--[=[
		@within Classes.Role
		@prop mentionable boolean
		Whether the role is mentionable.
	]=]
	self.mentionable = roleData.mentionable
end

--[=[
	@private
	@within Classes.Role
	Creates a new Role instance with the specified role data.
]=]
function Role.Interface.new(state: state.State, guildId: apiTypes.Snowflake, roleData: apiTypes.GuildRoleObject): Role
	local self = setmetatable(
		{
			--[=[
				@prop state State
				The state object for this role.
			]=]
			state = state,

			--[=[
				@prop guildId string
				The ID of the guild this role belongs to.
			]=]
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
