--[[
	Implementation of discords Permissions as a Luau builder.	

	https://discord.com/developers/docs/topics/permissions#permissions
]]

local apiTypes = require("../lune_packages/api_types")

local bit = require("../luau_packages/bit")

local Permission = {}

Permission.Prototype = {}
Permission.Interface = {}

--[[
	set the bitflag for this builder.
]]
function Permission.Prototype.setPermissionBitflag(self: Permission, bitflag: string | number): Permission
	local numberRepresentation = tonumber(bitflag)

	assert(numberRepresentation ~= nil, `Bitflag must be a number or a string representation of a number.`)

	self.bitflag = numberRepresentation

	return self
end

--[[
	add a specific permission to this permissions builder.
]]
function Permission.Prototype.addPermission(self: Permission, permission: apiTypes.Permissions): Permission
	table.insert(self.addedPermissions, permission)

	return self
end

--[[
	remove a specific permission to this permissions builder.
]]
function Permission.Prototype.removePermission(self: Permission, permission: apiTypes.Permissions): Permission
	table.insert(self.removedPermissions, permission)

	return self
end

--[[
	Returns the bitflag representation of the permission.
]]
function Permission.Prototype.build(self: Permission): JSON
	local bitflag = self.bitflag

	for _, permission in self.addedPermissions do
		bitflag = bit.bor(bitflag, apiTypes.permission.Permissions[permission])
	end

	for _, permission in self.removedPermissions do
		bitflag = bit.band(bitflag, bit.bnot(apiTypes.permission.Permissions[permission]))
	end

	return tostring(bitflag)
end

--[[
	Responsible for creating a new Permission.

	```lua
	
	```
]]
function Permission.Interface.new(resource: {
	bitflag: (string | number)?,
}?): Permission
	local self = setmetatable(
		{
			addedPermissions = {},
			removedPermissions = {},
			bitflag = 0,
		} :: Permission,
		{
			__index = Permission.Prototype,
		}
	)

	if resource then
		if resource.bitflag then
			self:setPermissionBitflag(resource.bitflag)
		end
	end

	return self
end

--[[
	Enables you to create a permission builder from a list of permissions.
]]
function Permission.Interface.fromPermissions(permissions: { apiTypes.Permissions }): Permission
	local bitflag = 0

	for _, permission in permissions do
		bitflag = bit.bor(bitflag, apiTypes.permission.Permissions[permission])
	end

	return Permission.Interface.new({
		bitflag = bitflag,
	})
end

export type Permission = typeof(Permission.Prototype) & {
	bitflag: number,
	addedPermissions: { apiTypes.Permissions },
	removedPermissions: { apiTypes.Permissions },
}

export type JSON = typeof(Permission.Prototype.build(nil :: any))

return Permission.Interface
