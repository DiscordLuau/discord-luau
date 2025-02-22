--[[
	Implementation of the Discord AuditLog class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-object-audit-log-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local auditLogChange = require("../change")
local auditLogInfo = require("./info")

local AuditLogEntry = {}

AuditLogEntry.Interface = {}
AuditLogEntry.Prototype = {}

function AuditLogEntry.Prototype.sync(self: AuditLogEntry, auditLogEntryData: apiTypes.AuditLogEntryObject)
	local changes = {}
	local options = {}

	if auditLogEntryData.changes then
		for _, auditLogChangeData in auditLogEntryData.changes do
			table.insert(changes, auditLogChange.new(auditLogChangeData))
		end
	end

	if auditLogEntryData.options then
		for _, auditLogChangeData in auditLogEntryData.options do
			table.insert(options, auditLogInfo.new(auditLogChangeData))
		end
	end

	self.changes = changes
	self.options = options

	self.targetId = auditLogEntryData.target_id
	self.userId = auditLogEntryData.user_id
	self.id = auditLogEntryData.id
	self.actionType = apiTypes.guild.AuditLogEvent[auditLogEntryData.action_type]
	self.reason = auditLogEntryData.reason
end

function AuditLogEntry.Interface.new(auditLogEntryData: apiTypes.AuditLogEntryObject): AuditLogEntry
	local self = setmetatable({} :: AuditLogEntry, { __index = AuditLogEntry.Prototype })

	self:sync(auditLogEntryData)

	return self
end

export type AuditLogEntry = typeof(AuditLogEntry.Prototype) & {
	targetId: string?,
	changes: { auditLogChange.AuditLogChange },
	userId: apiTypes.Snowflake?,
	id: apiTypes.Snowflake,
	actionType: apiTypes.AuditLogEvent,
	options: { auditLogInfo.AuditLogEntryInfo },
	reason: string?,
}

return AuditLogEntry.Interface
