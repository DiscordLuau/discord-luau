--[[
	Implementation of the Discord AutomoderationRule class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object
]]

local future = require("../../luau_packages/future")
local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")
local builders = require("../../lune_packages/builders")
local rest = require("../../lune_packages/rest")

local triggerMetadata = require("trigger/metadata")
local action = require("action/action")

local AutomoderationRule = {}

AutomoderationRule.Interface = {}
AutomoderationRule.Prototype = {}

function AutomoderationRule.Prototype.modifyAsync(
	self: AutomoderationRule,
	automoderationRuleJSON: builders.AutomoderationRuleJSON,
	auditLogReason: string?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.autoModeration
			.modifyAutoModerationRuleAsync(request, self.guildId, self.id, automoderationRuleJSON, auditLogReason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self:sync(response:unwrapOk())

		return self
	end) :: future.FutureLike<string, AutomoderationRule>
end

function AutomoderationRule.Prototype.deleteAsync(self: AutomoderationRule, auditLogReason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response =
			rest.autoModeration.deleteAutoModerationRuleAsync(request, self.guildId, self.id, auditLogReason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return
	end) :: future.FutureLike<string, nil>
end

function AutomoderationRule.Prototype.sync(
	self: AutomoderationRule,
	automoderationData: apiTypes.AutomoderationRuleObject
)
	local actions = {}

	for _, actionData in automoderationData.actions do
		table.insert(actions, action.new(actionData))
	end

	self.id = automoderationData.id
	self.guildId = automoderationData.guild_id
	self.name = automoderationData.name
	self.creatorId = automoderationData.creator_id
	self.eventType = apiTypes.guild.EventTypes[automoderationData.event_type]
	self.triggerType = apiTypes.guild.TriggerType[automoderationData.trigger_type]
	self.triggerMetadata = automoderationData.trigger_metadata
		and triggerMetadata.new(automoderationData.trigger_metadata)
	self.actions = actions
	self.enabled = automoderationData.enabled
	self.exemptRoles = automoderationData.exempt_roles
	self.exemptChannels = automoderationData.exempt_channels
end

function AutomoderationRule.Interface.new(
	state: state.State,
	automoderationData: apiTypes.AutomoderationRuleObject
): AutomoderationRule
	local self = setmetatable({} :: AutomoderationRule, { __index = AutomoderationRule.Prototype })

	self:sync(automoderationData)

	return self
end

export type AutomoderationRule = typeof(AutomoderationRule.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	name: string,
	creatorId: apiTypes.Snowflake,
	eventType: apiTypes.EventTypes,
	triggerType: apiTypes.TriggerTypes,
	triggerMetadata: triggerMetadata.TriggerMetadata?,
	actions: { action.Action },
	enabled: boolean?,
	exemptRoles: { apiTypes.Snowflake }?,
	exemptChannels: { apiTypes.Snowflake }?,
}

return AutomoderationRule.Interface
