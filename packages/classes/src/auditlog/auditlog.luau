--[[
	Implementation of the Discord AuditLog class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-object-audit-log-structure
]]

local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")

local command = require("../application/command/command")
local rule = require("../automoderation/rule")
local scheduledEvent = require("../guild/scheduledEvent")
local integration = require("../guild/integration/integration")
local user = require("../user")
local entry = require("./entry/entry")
local webhook = require("../webhook")
local publicThread = require("../channels/threads/public")

local AuditLogs = {}

AuditLogs.Interface = {}
AuditLogs.Prototype = {}

function AuditLogs.Prototype.sync(self: AuditLogs, auditLogsData: apiTypes.AuditLogObject)
	for _, commandData in auditLogsData.application_commands do
		table.insert(self.applicationCommands, command.new(commandData))
	end

	for _, auditLogEntryData in auditLogsData.audit_log_entries do
		table.insert(self.auditLogEntries, entry.new(auditLogEntryData))
	end

	for _, automoderationData in auditLogsData.auto_moderation_rules do
		table.insert(self.autoModerationRules, rule.new(self.state, automoderationData))
	end

	for _, scheduledEventData in auditLogsData.guild_scheduled_events do
		table.insert(self.guildScheduledEvents, scheduledEvent.new(scheduledEventData))
	end

	for _, integrationData in auditLogsData.integrations do
		table.insert(self.integrations, integration.new(self.state, nil, integrationData))
	end

	for _, channelData in auditLogsData.threads do
		table.insert(self.threads, publicThread.new(self.state, channelData))
	end

	for _, userData in auditLogsData.users do
		table.insert(self.users, user.new(userData))
	end

	for _, webhookData in auditLogsData.webhooks do
		table.insert(self.webhooks, webhook.new(webhookData))
	end
end

function AuditLogs.Interface.new(state: state.State, auditLogsData: apiTypes.AuditLogObject): AuditLogs
	local self = setmetatable(
		{
			state = state,

			applicationCommands = {},
			auditLogEntries = {},
			autoModerationRules = {},
			guildScheduledEvents = {},
			integrations = {},
			threads = {},
			users = {},
			webhooks = {},
		} :: AuditLogs,
		{ __index = AuditLogs.Prototype }
	)

	self:sync(auditLogsData)

	return self
end

export type AuditLogs = typeof(AuditLogs.Prototype) & {
	state: state.State,

	applicationCommands: { command.Command },
	auditLogEntries: { entry.AuditLogEntry },
	autoModerationRules: { rule.AutomoderationRule },
	guildScheduledEvents: { scheduledEvent.ScheduledEvent },
	integrations: { integration.Integration },
	threads: { publicThread.Public },
	users: { user.User },
	webhooks: { webhook.Webhook },
}

return AuditLogs.Interface
