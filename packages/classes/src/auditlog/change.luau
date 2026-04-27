--[=[
	@class Classes.AuditLog.Change
	@__index Prototype

	Implementation of the Discord AuditLogChange class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-change-object
]=]

--[=[
	@prop key string
	@within Classes.AuditLog.Change

	The key that was changed in this audit log entry
]=]

--[=[
	@prop newValue any
	@within Classes.AuditLog.Change

	The new value of the key after the change was made
]=]

--[=[
	@prop oldValue any
	@within Classes.AuditLog.Change

	The previous value of the key before the change was made
]=]

local apiTypes = require("../../luau_packages/api_types")

local AuditLogChange = {}

AuditLogChange.Interface = {}
AuditLogChange.Prototype = {}

--[=[
	@within Classes.AuditLog.Change
	@private

	Responsible for syncing data to this audit log change object. This is typically called by the API when this object is
	created or updated.
]=]
function AuditLogChange.Prototype.sync(self: AuditLogChange, auditLogChangeData: apiTypes.AuditLogChangeObject)
	self.key = auditLogChangeData.key

	self.newValue = auditLogChangeData.new_value

	self.oldValue = auditLogChangeData.old_value
end

--[=[
	@within Classes.AuditLog.Change
	@private

	Responsible for constructing this class.
]=]
function AuditLogChange.Interface.new(auditLogChangeData: apiTypes.AuditLogChangeObject): AuditLogChange
	local self = setmetatable({} :: AuditLogChange, { __index = AuditLogChange.Prototype })

	self:sync(auditLogChangeData)

	return self
end

export type AuditLogChange = typeof(AuditLogChange.Prototype) & {
	newValue: any,
	oldValue: any,
	key: string,
}

return AuditLogChange.Interface
