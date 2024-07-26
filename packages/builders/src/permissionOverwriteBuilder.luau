--[[
	Implementation of discords Permission Overwrite object as a Luau builder.	

	See permissions for more information about the allow and deny fields.

	https://discord.com/developers/docs/topics/permissions#permissions
	https://discord.com/developers/docs/resources/channel#overwrite-object
]]

local apiTypes = require("@api-types/apiTypes")
local permissions = require("@api-types/permissions")

local PermissionOverwriteBuilder = {}

PermissionOverwriteBuilder.Prototype = {}
PermissionOverwriteBuilder.Interface = {}

--[[
	Responsible for allowing specific permission to be set on either a Role of a Member.
]]
function PermissionOverwriteBuilder.Prototype.allowPermissions(
	self: PermissionOverwriteBuilder,
	...: permissions.Permission
): PermissionOverwriteBuilder
	for _, permission in { ... } do
		table.insert(self.allowedPermissionFlags, permission)
	end

	return self
end

--[[
	Responsible for denying specific permission to be set on either a Role of a Member.
]]
function PermissionOverwriteBuilder.Prototype.denyPermissions(
	self: PermissionOverwriteBuilder,
	...: permissions.Permission
): PermissionOverwriteBuilder
	for _, permission in { ... } do
		table.insert(self.deniedPermissionFlags, permission)
	end

	return self
end

--[[
	Responsible for building the OverwriteObject JSON that can be parsed by the Discord API.
]]
function PermissionOverwriteBuilder.Prototype.build(self: PermissionOverwriteBuilder): apiTypes.OverwriteObject
	local allowPermissionBits = {}
	local denyPermissionBits = {}

	for index, permission in self.allowedPermissionFlags do
		local permissionBit = permissions[permission]

		allowPermissionBits[index] = permissionBit
	end

	for index, permission in self.deniedPermissionFlags do
		local permissionBit = permissions[permission]

		denyPermissionBits[index] = permissionBit
	end

	return {
		type = self.permissionType == "role" and 0 or 1,

		allow = tostring(bit32.bor(table.unpack(allowPermissionBits))),
		deny = tostring(bit32.bor(table.unpack(denyPermissionBits))),
	}
end

--[[
	Responsible for creating a new PermissionOverwriteBuilder.

	With this builder, you can specify allow/deny permissions for either a Role or a Member.

	```lua
	local permissionOverwrite = PermissionOverwriteBuilder.new("role")
		:allowPermissions(Permission.ManageMessages, Permission.ManageRoles)
		:denyPermissions(Permission.KickMembers)
		:build()

	print(permissionOverwriteObject)
	```
]]
function PermissionOverwriteBuilder.Interface.new(
	permissionType: PermissionOverwriteType,
	allowFlags: { permissions.Permission }?,
	denyFlags: { permissions.Permission }?
)
	return setmetatable({
		allowedPermissionFlags = allowFlags or {},
		deniedPermissionFlags = denyFlags or {},

		permissionType = permissionType,
	}, {
		__index = PermissionOverwriteBuilder.Prototype,
	})
end

export type PermissionOverwriteBuilder = typeof(PermissionOverwriteBuilder.Prototype) & {
	allowedPermissionFlags: { permissions.Permission },
	deniedPermissionFlags: { permissions.Permission },

	permissionType: PermissionOverwriteType,
}

export type PermissionOverwriteType = "role" | "member"
export type PermissionOverwriteObject = apiTypes.OverwriteObject

return PermissionOverwriteBuilder.Interface
