--[[
	Implementation of the Discord Permissions in Luau

	https://discord.com/developers/docs/topics/permissions
]]

local apiTypes = require("../lune_packages/api_types")

local bit = require("../luau_packages/bit")

local Permission = {}

Permission.Interface = {}
Permission.Prototype = {}

--[[
	Responsible for querying what permission a discord permission bitflag has.
]]
function Permission.Prototype.hasPermission(self: Permission, permission: apiTypes.Permissions)
	return bit.band(self.permission, apiTypes.permission.Permissions[permission])
		== apiTypes.permission.Permissions[permission]
end

--[[
	Generates an array of permissions that are apart of this bitflag.
]]
function Permission.Prototype.toList(self: Permission): { apiTypes.Permissions }
	local permissions: { apiTypes.Permissions } = {}

	for key: apiTypes.Permissions in next, apiTypes.permission.Permissions do
		-- tables in the 'type' directory are flipped, only account for the strings!
		if type(key) ~= "string" then
			continue
		end

		if self:hasPermission(key) then
			table.insert(permissions, key)
		end
	end

	return permissions
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
