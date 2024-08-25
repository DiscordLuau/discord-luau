--[[
	Implementation of discords Permission Overwrite object as a Luau builder.	

	See permissions for more information about the allow and deny fields.

	https://discord.com/developers/docs/topics/permissions#permissions
	https://discord.com/developers/docs/resources/channel#overwrite-object
]]

local apiTypes = require("@api-types/apiTypes")
local permissionTypes = require("@api-types/permission")

local PermissionOverwriteBuilder = {}

PermissionOverwriteBuilder.Prototype = {}
PermissionOverwriteBuilder.Interface = {}

--[[
	Responsible for allowing specific permissionTypes to be set on either a Role of a Member.
]]
function PermissionOverwriteBuilder.Prototype.allowPermissions(
	self: PermissionOverwriteBuilder,
	...: permissionTypes.Permissions
): PermissionOverwriteBuilder
	for _, permissionTypes in { ... } do
		table.insert(self.allowedPermissionFlags, permissionTypes)
	end

	return self
end

--[[
	Responsible for denying specific permissionTypes to be set on either a Role of a Member.
]]
function PermissionOverwriteBuilder.Prototype.denyPermissions(
	self: PermissionOverwriteBuilder,
	...: permissionTypes.Permissions
): PermissionOverwriteBuilder
	for _, permissionTypes in { ... } do
		table.insert(self.deniedPermissionFlags, permissionTypes)
	end

	return self
end

--[[
	Responsible for building the OverwriteObject JSON that can be parsed by the Discord API.
]]
function PermissionOverwriteBuilder.Prototype.build(self: PermissionOverwriteBuilder): apiTypes.OverwriteObject
	local allowPermissionBits = {}
	local denyPermissionBits = {}

	for index, permissionEnum in self.allowedPermissionFlags do
		local permissionBit = permissionTypes[permissionEnum]

		allowPermissionBits[index] = permissionBit
	end

	for index, permissionEnum in self.deniedPermissionFlags do
		local permissionBit = permissionTypes[permissionEnum]

		denyPermissionBits[index] = permissionBit
	end

	return {
		type = self.type == "role" and 0 or 1,

		allow = tostring(bit32.bor(table.unpack(allowPermissionBits))),
		deny = tostring(bit32.bor(table.unpack(denyPermissionBits))),
	} :: apiTypes.OverwriteObject
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
function PermissionOverwriteBuilder.Interface.new(resource: {
	permissionType: PermissionOverwriteType,
	allowFlags: { permissionTypes.Permissions }?,
	denyFlags: { permissionTypes.Permissions }?,
}): PermissionOverwriteBuilder
	return setmetatable(
		{
			allowedPermissionFlags = resource.allowFlags or {},
			deniedPermissionFlags = resource.denyFlags or {},

			type = resource.permissionType,
		} :: PermissionOverwriteBuilder,
		{
			__index = PermissionOverwriteBuilder.Prototype,
		}
	)
end

--[[
	Responsible for creating a new PermissionOverwriteBuilder from an existing ID/Object.

	Supports properties that the .new constructor doesn't support. (id)
]]
function PermissionOverwriteBuilder.Interface.fromId(resource: {
	permissionId: apiTypes.Snowflake,
	permissionType: PermissionOverwriteType,
	allowFlags: { permissionTypes.Permissions }?,
	denyFlags: { permissionTypes.Permissions }?,
}): PermissionOverwriteBuilder
	local self = PermissionOverwriteBuilder.Interface.new(resource)

	self.id = resource.permissionId

	return self
end

export type PermissionOverwriteBuilder = typeof(PermissionOverwriteBuilder.Prototype) & {
	allowedPermissionFlags: { permissionTypes.Permissions },
	deniedPermissionFlags: { permissionTypes.Permissions },

	type: PermissionOverwriteType,
	id: apiTypes.Snowflake,
}

export type PermissionOverwriteType = "role" | "member"
export type PermissionOverwriteObject = apiTypes.OverwriteObject

return PermissionOverwriteBuilder.Interface
