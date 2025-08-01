--[=[
	@class Classes.AutomoderationRule
	@__index Prototype

	Implementation of the Discord AutomoderationRule class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object
]=]

local future = require("../../luau_packages/future")
local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")
local builders = require("../../lune_packages/builders")
local rest = require("../../lune_packages/rest")

local triggerMetadata = require("@self/trigger/metadata")
local action = require("@self/action/action")

local AutomoderationRule = {}

AutomoderationRule.Interface = {}
AutomoderationRule.Prototype = {}

--[=[
	@within Classes.AutomoderationRule

	Modify an existing rule. Returns an auto moderation rule on success.
]=]
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

--[=[
	@within Classes.AutomoderationRule

	Deletes an automoderation rule.
]=]
function AutomoderationRule.Prototype.deleteAsync(self: AutomoderationRule, auditLogReason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response =
			rest.autoModeration.deleteAutoModerationRuleAsync(request, self.guildId, self.id, auditLogReason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.AutomoderationRule
	@private

	Responsible for syncing data to this automoderation rule object. This is typically called by the API when this object is
	created or updated.
]=]
function AutomoderationRule.Prototype.sync(
	self: AutomoderationRule,
	automoderationData: apiTypes.AutomoderationRuleObject
)
	local actions = {}

	for _, actionData in automoderationData.actions do
		table.insert(actions, action.new(actionData))
	end

	--[=[
		@prop id string
		@within Classes.AutomoderationRule

		The unique identifier for this automoderation rule.
	]=]
	self.id = automoderationData.id

	--[=[
		@prop guildId string
		@within Classes.AutomoderationRule

		The ID of the guild this automoderation rule belongs to.
	]=]
	self.guildId = automoderationData.guild_id

	--[=[
		@prop name string
		@within Classes.AutomoderationRule

		The name of this automoderation rule.
	]=]
	self.name = automoderationData.name

	--[=[
		@prop creatorId string
		@within Classes.AutomoderationRule

		The ID of the user who created this automoderation rule.
	]=]
	self.creatorId = automoderationData.creator_id

	--[=[
		@prop eventType apiTypes.EventTypes
		@within Classes.AutomoderationRule

		The type of event that triggers this automoderation rule.
	]=]
	self.eventType = apiTypes.guild.EventTypes[automoderationData.event_type]

	--[=[
		@prop triggerType apiTypes.TriggerTypes
		@within Classes.AutomoderationRule

		The type of trigger that activates this automoderation rule.
	]=]
	self.triggerType = apiTypes.guild.TriggerType[automoderationData.trigger_type]

	--[=[
		@prop triggerMetadata Classes.TriggerMetadata?
		@within Classes.AutomoderationRule

		Additional metadata about the trigger conditions for this automoderation rule.
	]=]
	self.triggerMetadata = automoderationData.trigger_metadata
		and triggerMetadata.new(automoderationData.trigger_metadata)

	--[=[
		@prop actions {Classes.Action}
		@within Classes.AutomoderationRule

		Array of actions to be executed when the rule is triggered.
	]=]
	self.actions = actions

	--[=[
		@prop enabled boolean?
		@within Classes.AutomoderationRule

		Whether this automoderation rule is enabled.
	]=]
	self.enabled = automoderationData.enabled

	--[=[
		@prop exemptRoles {string}?
		@within Classes.AutomoderationRule

		Array of role IDs that are exempt from this automoderation rule.
	]=]
	self.exemptRoles = automoderationData.exempt_roles

	--[=[
		@prop exemptChannels {string}?
		@within Classes.AutomoderationRule

		Array of channel IDs that are exempt from this automoderation rule.
	]=]
	self.exemptChannels = automoderationData.exempt_channels
end

--[=[
	@within Classes.AutomoderationRule
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
