--[=[
	@class Classes.AuditLogChange
	@__index Prototype

	Implementation of the Discord AuditLogChange class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-change-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local AuditLogChange = {}

AuditLogChange.Interface = {}
AuditLogChange.Prototype = {}

--[=[
	@within Classes.AuditLogChange
	@private

	Responsible for syncing data to this audit log change object. This is typically called by the API when this object is
	created or updated.
]=]
function AuditLogChange.Prototype.sync(self: AuditLogChange, auditLogChangeData: apiTypes.AuditLogChangeObject)
	--[=[
		@prop key string
		@within Classes.AuditLogChange

		The key that was changed in this audit log entry
	]=]
	self.key = auditLogChangeData.key

	--[=[
		@prop newValue any
		@within Classes.AuditLogChange

		The new value of the key after the change was made
	]=]
	self.newValue = auditLogChangeData.new_value

	--[=[
		@prop oldValue any
		@within Classes.AuditLogChange

		The previous value of the key before the change was made
	]=]
	self.oldValue = auditLogChangeData.old_value
end

--[=[
	@within Classes.AuditLogChange
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
