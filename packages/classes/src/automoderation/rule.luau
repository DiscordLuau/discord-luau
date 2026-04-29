--[=[
	@class Classes.AutoModeration.Rule
	@__index Prototype

	Implementation of the Discord AutomoderationRule class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object
]=]

--[=[
	@prop id string
	@within Classes.AutoModeration.Rule

	The unique identifier for this automoderation rule.
]=]

--[=[
	@prop guildId string
	@within Classes.AutoModeration.Rule

	The ID of the guild this automoderation rule belongs to.
]=]

--[=[
	@prop name string
	@within Classes.AutoModeration.Rule

	The name of this automoderation rule.
]=]

--[=[
	@prop creatorId string
	@within Classes.AutoModeration.Rule

	The ID of the user who created this automoderation rule.
]=]

--[=[
	@prop eventType apiTypes.EventTypes
	@within Classes.AutoModeration.Rule

	The type of event that triggers this automoderation rule.
]=]

--[=[
	@prop triggerType apiTypes.TriggerTypes
	@within Classes.AutoModeration.Rule

	The type of trigger that activates this automoderation rule.
]=]

--[=[
	@prop triggerMetadata Classes.AutoModeration.TriggerMetadata?
	@within Classes.AutoModeration.Rule

	Additional metadata about the trigger conditions for this automoderation rule.
]=]

--[=[
	@prop actions {Classes.AutoModeration.Action}
	@within Classes.AutoModeration.Rule

	Array of actions to be executed when the rule is triggered.
]=]

--[=[
	@prop enabled boolean?
	@within Classes.AutoModeration.Rule

	Whether this automoderation rule is enabled.
]=]

--[=[
	@prop exemptRoles {string}?
	@within Classes.AutoModeration.Rule

	Array of role IDs that are exempt from this automoderation rule.
]=]

--[=[
	@prop exemptChannels {string}?
	@within Classes.AutoModeration.Rule

	Array of channel IDs that are exempt from this automoderation rule.
]=]

local future = require("../../luau_packages/future")
local apiTypes = require("../../luau_packages/api_types")
local state = require("../../luau_packages/state")
local builders = require("../../luau_packages/builders")
local rest = require("../../luau_packages/rest")

local triggerMetadata = require("./trigger/metadata")
local action = require("./action/action")

local AutomoderationRule = {}

AutomoderationRule.Interface = {}
AutomoderationRule.Prototype = {}

--[=[
	@within Classes.AutoModeration.Rule

	Modify an existing rule. Returns an auto moderation rule on success.
]=]
function AutomoderationRule.Prototype.modifyAsync(
	self: AutomoderationRule,
	automoderationRuleJSON: builders.AutomoderationRuleJSON,
	auditLogReason: string?
): future.FutureLike<string, AutomoderationRule>
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

--[=[
	@within Classes.AutoModeration.Rule

	Deletes an automoderation rule.
]=]
function AutomoderationRule.Prototype.deleteAsync(self: AutomoderationRule, auditLogReason: string?): future.FutureLike<string, nil>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response =
			rest.autoModeration.deleteAutoModerationRuleAsync(request, self.guildId, self.id, auditLogReason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.AutoModeration.Rule
	@private

	Responsible for syncing data to this automoderation rule object. This is typically called by the API when this object is
	created or updated.
]=]
function AutomoderationRule.Prototype.sync(
	self: AutomoderationRule,
	automoderationData: apiTypes.AutomoderationRuleObject
): nil
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

--[=[
	@within Classes.AutoModeration.Rule
	@private

	Responsible for constructing this class.
]=]
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
