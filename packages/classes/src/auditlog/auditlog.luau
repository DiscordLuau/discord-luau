--[=[
	@class Classes.AuditLog
	@__index Prototype

	Implementation of the Discord AuditLog class in Luau

	https://discord.com/developers/docs/resources/audit-log#audit-log-object-audit-log-structure
]=]

--[=[
	@prop state state.State
	@within Classes.AuditLog

	The state object that contains all the cache and client information.
]=]

--[=[
	@prop applicationCommands { Classes.Application.Command }
	@within Classes.AuditLog

	Array of application commands found in the audit log.
]=]

--[=[
	@prop auditLogEntries { Classes.AuditLog.Entry }
	@within Classes.AuditLog

	Array of audit log entries containing information about various changes made in the guild.
]=]

--[=[
	@prop autoModerationRules { Classes.AutoModeration.Rule }
	@within Classes.AuditLog

	Array of auto moderation rules that have been created, updated, or deleted in the guild.
]=]

--[=[
	@prop guildScheduledEvents { Classes.Guild.ScheduledEvent }
	@within Classes.AuditLog

	Array of scheduled events that have been created, updated, or deleted in the guild.
]=]

--[=[
	@prop integrations { Classes.Guild.Integration }
	@within Classes.AuditLog

	Array of integrations that have been created, updated, or deleted in the guild.
]=]

--[=[
	@prop threads { Classes.Channels.PublicThread }
	@within Classes.AuditLog

	Array of threads that have been created, updated, or deleted in the guild.
]=]

--[=[
	@prop users { Classes.User }
	@within Classes.AuditLog

	Array of users that are referenced in the audit log entries.
]=]

--[=[
	@prop webhooks { Classes.Webhook }
	@within Classes.AuditLog

	Array of webhooks that have been created, updated, or deleted in the guild.
]=]

local apiTypes = require("../../luau_packages/api_types")
local state = require("../../luau_packages/state")

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

--[=[
	@within Classes.AuditLog
	@private

	Responsible for syncing data to this audit logs object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.AuditLog
	@private

	Responsible for constructing this class.
]=]
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
