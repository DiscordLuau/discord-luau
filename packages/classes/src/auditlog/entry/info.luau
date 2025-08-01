--[=[
	@class Classes.AuditLogEntryInfo
	@__index Prototype

	Implementation of the Discord AuditLog class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-object-audit-log-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local AuditLogEntryInfo = {}

AuditLogEntryInfo.Interface = {}
AuditLogEntryInfo.Prototype = {}

--[=[
	@within Classes.AuditLogEntryInfo
	@private

	Responsible for syncing data to this audit log entry info object. This is typically called by the API when this object is
	created or updated.
]=]
function AuditLogEntryInfo.Prototype.sync(
	self: AuditLogEntryInfo,
	auditLogInfoData: apiTypes.OptionalAuditEntryInfoObject
)
	--[=[
		@prop applicationId string
		@within Classes.AuditLogEntryInfo

		The ID of the application that was affected by this audit log entry
	]=]
	self.applicationId = auditLogInfoData.application_id

	--[=[
		@prop autoModeartionRuleName string
		@within Classes.AuditLogEntryInfo

		The name of the auto moderation rule that was triggered
	]=]
	self.autoModeartionRuleName = auditLogInfoData.auto_moderation_rule_name

	--[=[
		@prop autoModerationRuleTriggerType string
		@within Classes.AuditLogEntryInfo

		The type of trigger that caused the auto moderation rule to activate
	]=]
	self.autoModerationRuleTriggerType = auditLogInfoData.auto_moderation_rule_trigger_type
		and tostring(auditLogInfoData.auto_moderation_rule_trigger_type)

	--[=[
		@prop channelId string
		@within Classes.AuditLogEntryInfo

		The ID of the channel that was affected by this audit log entry
	]=]
	self.channelId = auditLogInfoData.channel_id

	--[=[
		@prop count string
		@within Classes.AuditLogEntryInfo

		The number of entities that were affected by this audit log entry
	]=]
	self.count = auditLogInfoData.count

	--[=[
		@prop deleteMemberDays string
		@within Classes.AuditLogEntryInfo

		The number of days after which inactive members were kicked
	]=]
	self.deleteMemberDays = auditLogInfoData.delete_member_days

	--[=[
		@prop id string
		@within Classes.AuditLogEntryInfo

		The unique identifier for this audit log entry info
	]=]
	self.id = auditLogInfoData.id

	--[=[
		@prop membersRemoved string
		@within Classes.AuditLogEntryInfo

		The number of members that were removed in this action
	]=]
	self.membersRemoved = auditLogInfoData.members_removed

	--[=[
		@prop messageId string
		@within Classes.AuditLogEntryInfo

		The ID of the message that was affected by this audit log entry
	]=]
	self.messageId = auditLogInfoData.message_id

	--[=[
		@prop roleName string
		@within Classes.AuditLogEntryInfo

		The name of the role that was affected by this audit log entry
	]=]
	self.roleName = auditLogInfoData.role_name

	--[=[
		@prop type string
		@within Classes.AuditLogEntryInfo

		The type of audit log entry info
	]=]
	self.type = auditLogInfoData.type

	--[=[
		@prop integrationType string
		@within Classes.AuditLogEntryInfo

		The type of integration that was affected by this audit log entry
	]=]
	self.integrationType = auditLogInfoData.integration_type and tostring(auditLogInfoData.integration_type)
end

--[=[
	@within Classes.AuditLogEntryInfo
	@private

	Responsible for constructing this class.
]=]
function AuditLogEntryInfo.Interface.new(auditLogInfoData: apiTypes.OptionalAuditEntryInfoObject): AuditLogEntryInfo
	local self = setmetatable({} :: AuditLogEntryInfo, { __index = AuditLogEntryInfo.Prototype })

	self:sync(auditLogInfoData)

	return self
end

export type AuditLogEntryInfo = typeof(AuditLogEntryInfo.Prototype) & {
	applicationId: apiTypes.Snowflake,
	autoModeartionRuleName: string,
	autoModerationRuleTriggerType: string,
	channelId: string,
	count: string,
	deleteMemberDays: string,
	id: apiTypes.Snowflake,
	membersRemoved: string,
	messageId: apiTypes.Snowflake,
	roleName: string,
	type: string,
	integrationType: string,
}

return AuditLogEntryInfo.Interface
