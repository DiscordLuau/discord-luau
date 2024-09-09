--[[
	Implementation of a Discord Guild Role as a Luau builder.

	https://discord.com/developers/docs/resources/guild#create-guild-role-json-params
]]

local apiTypes = require("@api-types/apiTypes")
local permissionTypes = require("@api-types/permission")

local bit = require("@vendor/bit")

local validateKebabCase = require("@utils/validateKebabCase")

local Role = {}

Role.Prototype = {}
Role.Interface = {}

--[[
	Sets the name of the role, optionally this could be defined when creating the Role Builder as well.
]]
function Role.Prototype.setName(self: Role, roleName: string): Role
	assert(#roleName <= 100, `Role name must be less than 100 characters.`)
	assert(#roleName > 1, `Role name must be more than 1 characters.`)

	assert(validateKebabCase(roleName), `Tag name must be kebab-case.`)

	self.name = roleName

	return self
end

--[[
	Sets the permissions of the role, optionally this could be defined when creating the Role Builder as well.
]]
function Role.Prototype.setPermissions(self: Role, ...: permissionTypes.Permissions): Role
	for _, permissionType in { ... } do
		table.insert(self.permissionFlags, permissionType)
	end

	return self
end

--[[
	Sets the color of the role. Colors are presennted as a hexadecimal number.
]]
function Role.Prototype.setColor(self: Role, color: number): Role
	self.color = color

	return self
end

--[[
	Sets the role to be hoisted. A hoisted role is displayed in the user listing, vs's an unhoisted role which is not displayed at all.
]]
function Role.Prototype.setHoisted(self: Role, isHoisted: boolean): Role
	self.isHoisted = isHoisted

	return self
end

--[[
	Sets the role to be mentionable through the @ mention.
]]
function Role.Prototype.setMentionable(self: Role, isMentionable: boolean): Role
	self.isMentionable = isMentionable

	return self
end

--[[
	Responsible for buillding the role object that the Discord API can understand.
]]
function Role.Prototype.build(self: Role): JSON
	local permissionBits = {}

	for index, permissionEnum in self.permissionFlags do
		local permissionBit = permissionTypes.Permissions[permissionEnum]

		permissionBits[index] = permissionBit
	end

	return {
		name = self.name,
		permissions = tostring(bit.bor(table.unpack(permissionBits))),
		color = self.color,
		hoist = self.isHoisted,
		icon = self.icon,
		unicode_emoji = self.unicodeEmoji,
		mentionable = self.isMentionable,
	} :: apiTypes.GuildRoleObject
end

--[[
	Constructs a new Role Builder.

	```lua
	local role = Role.new("Role Name", { permissions.Permission.SendMessages })
		:setColor(0xFFFFFF)
		:setHoisted(true)
		:setMentionable(true)
		:build()
	```
]]
function Role.Interface.new(resource: {
	roleName: string?,
	rolePermissions: { permissionTypes.Permissions }?,
}): Role
	local self = setmetatable(
		{
			name = "",
			permissionFlags = {},
			color = 0xFFFFFF,
			isHoisted = false,
			isMentionable = true,

			-- icon,
			-- unicodeEmoji,
		} :: Role,
		{ __index = Role.Prototype }
	)

	if resource.roleName then
		self:setName(resource.roleName)
	end

	if resource.rolePermissions then
		-- HACK: Typecasting here so that all varargs are typed as a Permission.
		self:setPermissions(table.unpack(resource.rolePermissions) :: permissionTypes.Permissions)
	end

	return self
end

export type Role = typeof(Role.Prototype) & {
	name: string,
	permissionFlags: { permissionTypes.Permissions },
	color: number,
	isHoisted: boolean,
	icon: string?,
	unicodeEmoji: string?,
	isMentionable: boolean,
}

export type JSON = typeof(Role.Prototype.build(nil :: any))

return Role.Interface
