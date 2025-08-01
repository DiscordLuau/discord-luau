--[=[
	@class Builders.Role
	@__index Prototype

	Implementation of a Discord Guild Role as a Luau builder.

	https://discord.com/developers/docs/resources/guild#create-guild-role-json-params
]=]

local apiTypes = require("../../lune_packages/api_types")
local util = require("../../lune_packages/util")

local bit = require("../../luau_packages/bit")

local Role = {}

Role.Prototype = {}
Role.Interface = {}

--[=[
	@within Builders.Role

	Sets the name of the role, optionally this could be defined when creating the Role Builder as well.
]=]
function Role.Prototype.setName(self: Role, roleName: string): Role
	assert(#roleName <= 100, `Role name must be less than 100 characters.`)
	assert(#roleName > 1, `Role name must be more than 1 characters.`)

	assert(util.validateKebabCase(roleName), `Tag name must be kebab-case.`)

	self.name = roleName

	return self
end

--[=[
	@within Builders.Role

	Sets the permissions of the role, optionally this could be defined when creating the Role Builder as well.
]=]
function Role.Prototype.setPermissions(self: Role, ...: apiTypes.Permissions): Role
	for _, permissionType in { ... } do
		table.insert(self.permissionFlags, permissionType)
	end

	return self
end

--[=[
	@within Builders.Role

	Sets the color of the role. Colors are presennted as a hexadecimal number.
]=]
function Role.Prototype.setColor(self: Role, color: number): Role
	self.color = color

	return self
end

--[=[
	@within Builders.Role

	Sets the role to be hoisted. A hoisted role is displayed in the user listing, vs's an unhoisted role which is not displayed at all.
]=]
function Role.Prototype.setHoisted(self: Role, isHoisted: boolean): Role
	self.isHoisted = isHoisted

	return self
end

--[=[
	@within Builders.Role

	Sets the role to be mentionable through the @ mention.
]=]
function Role.Prototype.setMentionable(self: Role, isMentionable: boolean): Role
	self.isMentionable = isMentionable

	return self
end

--[=[
	@within Builders.Role

	Responsible for buillding the role object that the Discord API can understand.
]=]
function Role.Prototype.build(self: Role): JSON
	local permissionBits = {}

	for index, permissionEnum in self.permissionFlags do
		local permissionBit = apiTypes.permission.Permissions[permissionEnum]

		permissionBits[index] = permissionBit
	end

	return {
		name = self.name,
		permissions = #permissionBits == 0 and nil or tostring(bit.bor(table.unpack(permissionBits))),
		color = self.color,
		hoist = self.isHoisted,
		icon = self.icon,
		unicode_emoji = self.unicodeEmoji,
		mentionable = self.isMentionable,
	}
end

--[=[
	@within Builders.Role

	Constructs a new Role Builder.

	```luau
	local role = Role.new("Role Name", { permissions.Permission.SendMessages })
		:setColor(0xFFFFFF)
		:setHoisted(true)
		:setMentionable(true)
		:build()
	```
]=]
function Role.Interface.new(resource: {
	roleName: string?,
	rolePermissions: { apiTypes.Permissions }?,
}?): Role
	local self = setmetatable(
		{
			--[=[
				@prop name string?
				@within Builders.Role
				The name of the role.
			]=]

			--[=[
				@prop permissionFlags { apiTypes.Permissions }
				@within Builders.Role
				The permissions assigned to the role.
			]=]
			permissionFlags = {},

			--[=[
				@prop color number?
				@within Builders.Role
				The color of the role represented as a hexadecimal number.
			]=]

			--[=[
				@prop isHoisted boolean?
				@within Builders.Role
				Whether the role is displayed separately in the member list.
			]=]

			--[=[
				@prop icon string?
				@within Builders.Role
				The icon of the role.
			]=]

			--[=[
				@prop unicodeEmoji string?
				@within Builders.Role
				The unicode emoji of the role.
			]=]

			--[=[
				@prop isMentionable boolean?
				@within Builders.Role
				Whether the role can be mentioned by users.
			]=]
		} :: Role,
		{ __index = Role.Prototype }
	)

	if resource then
		if resource.roleName then
			self:setName(resource.roleName)
		end

		if resource.rolePermissions then
			-- HACK: Typecasting here so that all varargs are typed as a Permission.
			self:setPermissions(table.unpack(resource.rolePermissions) :: apiTypes.Permissions)
		end
	end

	return self
end

export type Role = typeof(Role.Prototype) & {
	name: string?,
	permissionFlags: { apiTypes.Permissions },
	color: number?,
	isHoisted: boolean?,
	icon: string?,
	unicodeEmoji: string?,
	isMentionable: boolean?,
}

export type JSON = typeof(Role.Prototype.build(nil :: any))

return Role.Interface
