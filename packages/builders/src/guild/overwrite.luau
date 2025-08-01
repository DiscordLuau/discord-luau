--[=[
	@class Builders.Overwrite
	@__index Prototype

	Implementation of discords Permission Overwrite object as a Luau builder.	

	See permissions for more information about the allow and deny fields.

	https://discord.com/developers/docs/topics/permissions#permissions
	https://discord.com/developers/docs/resources/channel#overwrite-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local bit = require("../../luau_packages/bit")

local Overwrite = {}

Overwrite.Prototype = {}
Overwrite.Interface = {}

--[=[
	@within Builders.Overwrite

	Responsible for allowing specific permissions to be set on either a Role of a Member.
]=]
function Overwrite.Prototype.allowPermissions(self: Overwrite, ...: apiTypes.Permissions): Overwrite
	for _, apiTypes in { ... } do
		table.insert(self.allowedPermissionFlags, apiTypes)
	end

	return self
end

--[=[
	@within Builders.Overwrite

	Responsible for denying specific permissions to be set on either a Role of a Member.
]=]
function Overwrite.Prototype.denyPermissions(self: Overwrite, ...: apiTypes.Permissions): Overwrite
	for _, apiTypes in { ... } do
		table.insert(self.deniedPermissionFlags, apiTypes)
	end

	return self
end

--[=[
	@within Builders.Overwrite

	Sets the permission type for this builder.
]=]
function Overwrite.Prototype.setPermissionType(self: Overwrite, type: PermissionOverwriteType): Overwrite
	self.type = type

	return self
end

--[=[
	@within Builders.Overwrite

	Responsible for building the OverwriteObject JSON that can be parsed by the Discord API.
]=]
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

--[=[
	@within Builders.Overwrite

	Responsible for creating a new Overwrite.
]=]
function Overwrite.Interface.new(resource: {
	permissionType: PermissionOverwriteType,
	allowFlags: { apiTypes.Permissions }?,
	denyFlags: { apiTypes.Permissions }?,
}): Overwrite
	local self = setmetatable(
		{
			--[=[
				@prop allowedPermissionFlags {apiTypes.Permissions}
				@within Builders.Overwrite
				Array of permission flags that are allowed for this overwrite.
			]=]
			allowedPermissionFlags = resource.allowFlags or {},

			--[=[
				@prop deniedPermissionFlags {apiTypes.Permissions}
				@within Builders.Overwrite
				Array of permission flags that are denied for this overwrite.
			]=]
			deniedPermissionFlags = resource.denyFlags or {},

			--[=[
				@prop type PermissionOverwriteType
				@within Builders.Overwrite
				The type of overwrite, either "role" or "member".
			]=]
			type = resource.permissionType,
		} :: Overwrite,
		{
			__index = Overwrite.Prototype,
		}
	)

	if resource then
		if resource.allowFlags then
			for _, flag in resource.allowFlags do
				self:allowPermissions(flag :: apiTypes.Permissions)
			end
		end

		if resource.denyFlags then
			for _, flag in resource.denyFlags do
				self:denyPermissions(flag :: apiTypes.Permissions)
			end
		end

		if resource.permissionType then
			self:setPermissionType(resource.permissionType)
		end
	end

	return self
end

--[=[
	@within Builders.Overwrite

	Responsible for creating a new Overwrite from an existing ID/Object.

	Supports properties that the .new constructor doesn't support. (id)
]=]
function Overwrite.Interface.fromId(resource: {
	permissionId: apiTypes.Snowflake,
	permissionType: PermissionOverwriteType,
	allowFlags: { apiTypes.Permissions }?,
	denyFlags: { apiTypes.Permissions }?,
}): Overwrite
	local self = Overwrite.Interface.new(resource)

	--[=[
		@prop id string
		@within Builders.Overwrite
		The ID of the role or user that the overwrite belongs to.
	]=]
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
