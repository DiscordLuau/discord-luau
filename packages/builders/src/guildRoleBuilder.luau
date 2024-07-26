--[[
	Guild Role Builder, responsible for building a Role object that Discords API can understand.
]]

local apiTypes = require("@api-types/apiTypes")
local permissions = require("@api-types/permissions")

local GuildRoleBuilder = {}

GuildRoleBuilder.Prototype = {}
GuildRoleBuilder.Interface = {}

--[[
	Sets the name of the role, optionally this could be defined when creating the Role Builder as well.
]]
function GuildRoleBuilder.Prototype.setName(self: GuildRoleBuilder, name: string): GuildRoleBuilder
	assert(#name <= 100, `Role name must be less than 100 characters.`)

	self.name = name

	return self
end

--[[
	Sets the permissions of the role, optionally this could be defined when creating the Role Builder as well.
]]
function GuildRoleBuilder.Prototype.setPermissions(
	self: GuildRoleBuilder,
	...: permissions.Permission
): GuildRoleBuilder
	for _, permission in { ... } do
		table.insert(self.permissionFlags, permission)
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

	for index, permission in self.permissionFlags do
		local permissionBit = permissions[permission]

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
	}
end

--[[
	Constructs a new Role Builder.

	```lua
	local roleBuilder = GuildRoleBuilder.new("Role Name", { permissions.Permission.SendMessages })
		:SetColor(0xFFFFFF)
		:SetHoisted(true)
		:SetMentionable(true)
		:Build()
	```
]]
function GuildRoleBuilder.Interface.new(
	roleName: string?,
	rolePermissions: { permissions.Permission }?
): GuildRoleBuilder
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

	if roleName then
		self:setName(roleName)
	end

	if rolePermissions then
		-- HACK: Typecasting here so that all varargs are typed as a Permission.
		self:setPermissions(table.unpack(rolePermissions) :: permissions.Permission)
	end

	return self
end

export type GuildRoleBuilder = typeof(GuildRoleBuilder.Prototype) & {
	name: string,
	permissionFlags: { permissions.Permission },
	color: number,
	isHoisted: boolean,
	icon: string?,
	unicodeEmoji: string?,
	isMentionable: boolean,
}

return GuildRoleBuilder.Interface
