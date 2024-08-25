--[[
	Implementation of a Discord Guild Role as a Luau builder.

	https://discord.com/developers/docs/resources/guild#create-guild-role-json-params
]]

local apiTypes = require("@api-types/apiTypes")
local permissionTypes = require("@api-types/permission")

local validateKebabCase = require("@utils/validateKebabCase")

local GuildRoleBuilder = {}

GuildRoleBuilder.Prototype = {}
GuildRoleBuilder.Interface = {}

--[[
	Sets the name of the role, optionally this could be defined when creating the Role Builder as well.
]]
function GuildRoleBuilder.Prototype.setName(self: GuildRoleBuilder, roleName: string): GuildRoleBuilder
	assert(#roleName <= 100, `Role name must be less than 100 characters.`)
	assert(#roleName > 1, `Role name must be more than 1 characters.`)

	assert(validateKebabCase(roleName), `Tag name must be kebab-case.`)

	self.name = roleName

	return self
end

--[[
	Sets the permissions of the role, optionally this could be defined when creating the Role Builder as well.
]]
function GuildRoleBuilder.Prototype.setPermissions(
	self: GuildRoleBuilder,
	...: permissionTypes.Permissions
): GuildRoleBuilder
	for _, permissionTypes in { ... } do
		table.insert(self.permissionFlags, permissionTypes)
	end

	return self
end

--[[
	Sets the color of the role. Colors are presennted as a hexadecimal number.
]]
function GuildRoleBuilder.Prototype.setColor(self: GuildRoleBuilder, color: number): GuildRoleBuilder
	self.color = color

	return self
end

--[[
	Sets the role to be hoisted. A hoisted role is displayed in the user listing, vs's an unhoisted role which is not displayed at all.
]]
function GuildRoleBuilder.Prototype.setHoisted(self: GuildRoleBuilder, isHoisted: boolean): GuildRoleBuilder
	self.isHoisted = isHoisted

	return self
end

--[[
	Sets the role to be mentionable through the @ mention.
]]
function GuildRoleBuilder.Prototype.setMentionable(self: GuildRoleBuilder, isMentionable: boolean): GuildRoleBuilder
	self.isMentionable = isMentionable

	return self
end

--[[
	Responsible for buillding the role object that the Discord API can understand.
]]
function GuildRoleBuilder.Prototype.build(self: GuildRoleBuilder): apiTypes.GuildRoleObject
	local permissionBits = {}

	for index, permissionEnum in self.permissionFlags do
		local permissionBit = permissionTypes[permissionEnum]

		permissionBits[index] = permissionBit
	end

	return {
		name = self.name,
		permissions = tostring(bit32.bor(table.unpack(permissionBits))),
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
	local role = GuildRoleBuilder.new("Role Name", { permissions.Permission.SendMessages })
		:setColor(0xFFFFFF)
		:setHoisted(true)
		:setMentionable(true)
		:build()
	```
]]
function GuildRoleBuilder.Interface.new(resource: {
	roleName: string?,
	rolePermissions: { permissionTypes.Permissions }?,
}): GuildRoleBuilder
	local self = setmetatable(
		{
			name = "",
			permissionFlags = {},
			color = 0xFFFFFF,
			isHoisted = false,
			isMentionable = true,

			-- icon,
			-- unicodeEmoji,
		} :: GuildRoleBuilder,
		{ __index = GuildRoleBuilder.Prototype }
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

export type GuildRoleBuilder = typeof(GuildRoleBuilder.Prototype) & {
	name: string,
	permissionFlags: { permissionTypes.Permissions },
	color: number,
	isHoisted: boolean,
	icon: string?,
	unicodeEmoji: string?,
	isMentionable: boolean,
}

return GuildRoleBuilder.Interface
