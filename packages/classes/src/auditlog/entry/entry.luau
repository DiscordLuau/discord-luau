--[=[
	@class Classes.AuditLogEntry
	@__index Prototype

	Implementation of the Discord AuditLog class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-object-audit-log-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local auditLogChange = require("../change")
local auditLogInfo = require("./info")

local AuditLogEntry = {}

AuditLogEntry.Interface = {}
AuditLogEntry.Prototype = {}

--[=[
	@within Classes.AuditLogEntry
	@private

	Responsible for syncing data to this audit log entry object. This is typically called by the API when this object is
	created or updated.
]=]
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

	--[=[
		@prop changes { Classes.AuditLogChange }
		@within Classes.AuditLogEntry

		An array of audit log changes that occurred during this audit log entry
	]=]
	self.changes = changes

	--[=[
		@prop options { Classes.AuditLogEntryInfo }
		@within Classes.AuditLogEntry

		Additional information about the audit log entry
	]=]
	self.options = options

	--[=[
		@prop targetId string?
		@within Classes.AuditLogEntry

		ID of the affected entity (webhook, user, role, etc.)
	]=]
	self.targetId = auditLogEntryData.target_id

	--[=[
		@prop userId string?
		@within Classes.AuditLogEntry

		The user who made the changes
	]=]
	self.userId = auditLogEntryData.user_id

	--[=[
		@prop id string
		@within Classes.AuditLogEntry

		Unique identifier for this entry
	]=]
	self.id = auditLogEntryData.id

	--[=[
		@prop actionType apiTypes.AuditLogEvent
		@within Classes.AuditLogEntry

		Type of action that occurred
	]=]
	self.actionType = apiTypes.guild.AuditLogEvent[auditLogEntryData.action_type]

	--[=[
		@prop reason string?
		@within Classes.AuditLogEntry

		The reason for the change (0-512 characters)
	]=]
	self.reason = auditLogEntryData.reason
end

--[=[
	@within Classes.AuditLogEntry
	@private

	Responsible for constructing this class.
]=]
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
