--[[
	Guild Role Builder, responsible for building a Role object that Discords API can understand.
]]

local apiTypes = require("@api-types/apiTypes")
local permissions = require("@api-types/permissions")

local guildRoleBuilder = {}

guildRoleBuilder.Prototype = {}
guildRoleBuilder.Interface = {}

--[[
	Sets the name of the role, optionally this could be defined when creating the Role Builder as well.
]]
function guildRoleBuilder.Prototype.SetName(self: guildRoleBuilder, roleName: string)
	assert(#roleName <= 100, `Role name must be less than 100 characters.`)

	self.roleName = roleName

	return self
end

--[[
	Sets the permissions of the role, optionally this could be defined when creating the Role Builder as well.
]]
function guildRoleBuilder.Prototype.SetPermissions(self: guildRoleBuilder, ...: permissions.Permission)
	for _, permission in { ... } do
		table.insert(self.rolePermissions, permission)
	end

	return self
end

--[[
	Sets the color of the role. Colors are presennted as a hexadecimal number.
]]
function guildRoleBuilder.Prototype.SetColor(self: guildRoleBuilder, color: number)
	self.roleColor = color

	return self
end

--[[
	Sets the role to be hoisted. A hoisted role is displayed in the user listing, vs's an unhoisted role which is not displayed at all.
]]
function guildRoleBuilder.Prototype.SetHoisted(self: guildRoleBuilder, isHoisted: boolean)
	self.roleIsHoisted = isHoisted

	return self
end

--[[
	Sets the role to be mentionable through the @ mention.
]]
function guildRoleBuilder.Prototype.SetMentionable(self: guildRoleBuilder, isMentionable: boolean)
	self.roleIsMentionable = isMentionable

	return self
end

--[[
	Responsible for buillding the role object that the Discord API can understand.
]]
function guildRoleBuilder.Prototype.Build(self: guildRoleBuilder): apiTypes.GuildRoleObject
	local permissionBits = {}

	for index, permission in self.rolePermissions do
		local permissionBit = permissions[permission]

		permissionBits[index] = permissionBit
	end

	return {
		name = self.roleName,
		permissions = tostring(bit32.bor(table.unpack(permissionBits))),
		color = self.roleColor,
		hoist = self.roleIsHoisted,
		icon = self.roleIcon,
		unicode_emoji = self.roleUnicodeEmoji,
		mentionable = self.roleIsMentionable,
	}
end

--[[
	Constructs a new Role Builder.

	```lua
	local roleBuilder = guildRoleBuilder.new("Role Name", { permissions.Permission.SendMessages })
		:SetColor(0xFFFFFF)
		:SetHoisted(true)
		:SetMentionable(true)
		:Build()
	```
]]
function guildRoleBuilder.Interface.new(roleName: string?, rolePermissions: { permissions.Permission }?)
	local self = setmetatable(
		{
			roleName = "",
			rolePermissions = {},
			roleColor = 0xFFFFFF,
			roleIsHoisted = false,
			roleIsMentionable = true,

			-- roleIcon,
			-- roleUnicodeEmoji,
		} :: guildRoleBuilder,
		{ __index = guildRoleBuilder.Prototype }
	)

	if roleName then
		self:SetName(roleName)
	end

	if rolePermissions then
		-- HACK: Typecasting here so that all varargs are typed as a Permission.
		self:SetPermissions(table.unpack(rolePermissions) :: permissions.Permission)
	end

	return self
end

export type guildRoleBuilder = typeof(guildRoleBuilder.Prototype) & {
	roleName: string,
	rolePermissions: { permissions.Permission },
	roleColor: number,
	roleIsHoisted: boolean,
	roleIcon: string?,
	roleUnicodeEmoji: string?,
	roleIsMentionable: boolean,
}

return guildRoleBuilder.Interface
