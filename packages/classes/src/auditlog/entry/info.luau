--[[
	Implementation of the Discord AuditLog class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-object-audit-log-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local AuditLogEntryInfo = {}

AuditLogEntryInfo.Interface = {}
AuditLogEntryInfo.Prototype = {}

function AuditLogEntryInfo.Prototype.sync(
	self: AuditLogEntryInfo,
	auditLogInfoData: apiTypes.OptionalAuditEntryInfoObject
)
	self.applicationId = auditLogInfoData.application_id
	self.autoModeartionRuleName = auditLogInfoData.auto_moderation_rule_name
	self.autoModerationRuleTriggerType = auditLogInfoData.auto_moderation_rule_trigger_type
		and tostring(auditLogInfoData.auto_moderation_rule_trigger_type)
	self.channelId = auditLogInfoData.channel_id
	self.count = auditLogInfoData.count
	self.deleteMemberDays = auditLogInfoData.delete_member_days
	self.id = auditLogInfoData.id
	self.membersRemoved = auditLogInfoData.members_removed
	self.messageId = auditLogInfoData.message_id
	self.roleName = auditLogInfoData.role_name
	self.type = auditLogInfoData.type
	self.integrationType = auditLogInfoData.integration_type and tostring(auditLogInfoData.integration_type)
end

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
