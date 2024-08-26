--[[
	Implementation of the Discord Permissions in Luau

	https://discord.com/developers/docs/topics/permissions
]]

local permissionTypes = require("@api-types/permission")

local Permission = {}

Permission.Interface = {}
Permission.Prototype = {}

--[[
	Responsible for querying what permission a discord permission bitflag has.
]]
function Permission.Prototype.hasPermission(self: Permission, permission: permissionTypes.Permissions)
	return bit32.band(self.permission, permissionTypes.Permissions[permission])
		== permissionTypes.Permissions[permission]
end

function Permission.Interface.new(permission: string): Permission
	local self = setmetatable(
		{
			permission = tonumber(permission),
		} :: Permission,
		{ __index = Permission.Prototype }
	)

	return self
end

export type Permission = typeof(Permission.Prototype) & {
	permission: number,
}

return Permission.Interface
