--[[
	Implementation of discords Permission Overwrite object as a Luau builder.	

	See permissions for more information about the allow and deny fields.

	https://discord.com/developers/docs/topics/permissions#permissions
	https://discord.com/developers/docs/resources/channel#overwrite-object
]]

local apiTypes = require("../../lune_packages/api_types")

local bit = require("../../luau_packages/bit")

local Overwrite = {}

Overwrite.Prototype = {}
Overwrite.Interface = {}

--[[
	Responsible for allowing specific apiTypes to be set on either a Role of a Member.
]]
function Overwrite.Prototype.allowPermissions(self: Overwrite, ...: apiTypes.Permissions): Overwrite
	for _, apiTypes in { ... } do
		table.insert(self.allowedPermissionFlags, apiTypes)
	end

	return self
end

--[[
	Responsible for denying specific apiTypes to be set on either a Role of a Member.
]]
function Overwrite.Prototype.denyPermissions(self: Overwrite, ...: apiTypes.Permissions): Overwrite
	for _, permissionType in { ... } do
		table.insert(self.deniedPermissionFlags, permissionType)
	end

	return self
end

--[[
	Responsible for building the OverwriteObject JSON that can be parsed by the Discord API.
]]
function Overwrite.Prototype.build(self: Overwrite): JSON
	local allowPermissionBits = {}
	local denyPermissionBits = {}

	for index, permissionEnum in self.allowedPermissionFlags do
		local permissionBit = apiTypes.permission.Permissions[permissionEnum]

		allowPermissionBits[index] = permissionBit
	end

	for index, permissionEnum in self.deniedPermissionFlags do
		local permissionBit = apiTypes.permission.Permissions[permissionEnum]

		denyPermissionBits[index] = permissionBit
	end

	return {
		type = self.type == "role" and 0 or 1,

		allow = tostring(bit.bor(table.unpack(allowPermissionBits))),
		deny = tostring(bit.bor(table.unpack(denyPermissionBits))),
	}
end

--[[
	Responsible for creating a new Overwrite.

	```lua
	
	```
]]
function Overwrite.Interface.new(resource: {
	permissionType: PermissionOverwriteType,
	allowFlags: { apiTypes.Permissions }?,
	denyFlags: { apiTypes.Permissions }?,
}): Overwrite
	return setmetatable(
		{
			allowedPermissionFlags = resource.allowFlags or {},
			deniedPermissionFlags = resource.denyFlags or {},

			type = resource.permissionType,
		} :: Overwrite,
		{
			__index = Overwrite.Prototype,
		}
	)
end

--[[
	Responsible for creating a new Overwrite from an existing ID/Object.

	Supports properties that the .new constructor doesn't support. (id)
]]
function Overwrite.Interface.fromId(resource: {
	permissionId: apiTypes.Snowflake,
	permissionType: PermissionOverwriteType,
	allowFlags: { apiTypes.Permissions }?,
	denyFlags: { apiTypes.Permissions }?,
}): Overwrite
	local self = Overwrite.Interface.new(resource)

	self.id = resource.permissionId

	return self
end

export type Overwrite = typeof(Overwrite.Prototype) & {
	allowedPermissionFlags: { apiTypes.Permissions },
	deniedPermissionFlags: { apiTypes.Permissions },

	type: PermissionOverwriteType,
	id: apiTypes.Snowflake,
}

export type JSON = typeof(Overwrite.Prototype.build(nil :: any))

export type PermissionOverwriteType = "role" | "member"
export type PermissionOverwriteObject = apiTypes.OverwriteObject

return Overwrite.Interface
