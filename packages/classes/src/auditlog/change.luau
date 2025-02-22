--[[
	Implementation of the Discord AuditLogChange class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-change-object
]]

local apiTypes = require("../../lune_packages/api_types")

local AuditLogChange = {}

AuditLogChange.Interface = {}
AuditLogChange.Prototype = {}

function AuditLogChange.Prototype.sync(self: AuditLogChange, auditLogChangeData: apiTypes.AuditLogChangeObject)
	self.key = auditLogChangeData.key
	self.newValue = auditLogChangeData.new_value
	self.oldValue = auditLogChangeData.old_value
end

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
