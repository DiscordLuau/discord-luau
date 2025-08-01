--[=[
	@class Builders.AutomoderationRule
	@__index Prototype

	Implementation of a discord automoderation rule object as a luau builder.

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object
]=]

local apiTypes = require("../../lune_packages/api_types")
local triggerMetadata = require("./trigger/metadata")
local action = require("./action/action")

local AutomoderationRule = {}

AutomoderationRule.Prototype = {}
AutomoderationRule.Interface = {}

--[=[
	@within Builders.AutomoderationRule

	Sets the name of the automoderation rule.
]=]
function AutomoderationRule.Prototype.setName(self: AutomoderationRule, name: string): AutomoderationRule
	self.name = name

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Sets the event type for the automoderation rule.
]=]
function AutomoderationRule.Prototype.setEventType(
	self: AutomoderationRule,
	eventType: apiTypes.EventTypes
): AutomoderationRule
	self.eventType = eventType

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Sets the trigger type for the automoderation rule.
]=]
function AutomoderationRule.Prototype.setTriggerType(
	self: AutomoderationRule,
	triggerType: apiTypes.TriggerTypes
): AutomoderationRule
	self.triggerType = triggerType

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Sets the trigger metadata for the automoderation rule.
]=]
function AutomoderationRule.Prototype.setTriggerMetadata(
	self: AutomoderationRule,
	triggerMetadata: triggerMetadata.JSON
): AutomoderationRule
	self.triggerMetadata = triggerMetadata

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Sets the actions for the automoderation rule.
]=]
function AutomoderationRule.Prototype.setActions(self: AutomoderationRule, actions: { action.JSON }): AutomoderationRule
	self.actions = actions

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Sets whether the automoderation rule is enabled.
]=]
function AutomoderationRule.Prototype.setEnabled(self: AutomoderationRule, enabled: boolean): AutomoderationRule
	self.enabled = enabled

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Sets the exempt roles for the automoderation rule.
]=]
function AutomoderationRule.Prototype.setExemptRoles(
	self: AutomoderationRule,
	exemptRoles: { apiTypes.Snowflake }
): AutomoderationRule
	self.exemptRoles = exemptRoles

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Sets the exempt channels for the automoderation rule.
]=]
function AutomoderationRule.Prototype.setExemptChannels(
	self: AutomoderationRule,
	exemptChannels: { apiTypes.Snowflake }
): AutomoderationRule
	self.exemptChannels = exemptChannels

	return self
end

--[=[
	@within Builders.AutomoderationRule

	Builds the automoderation rule object.
]=]
function AutomoderationRule.Prototype.build(self: AutomoderationRule): JSON
	return {
		name = self.name,
		event_type = apiTypes.guild.EventTypes[self.eventType],
		trigger_type = apiTypes.guild.TriggerTypes[self.triggerType],
		trigger_metadata = self.triggerMetadata,
		actions = self.actions,
		enabled = self.enabled,
		exempt_roles = self.exemptRoles,
		exempt_channels = self.exemptChannels,
	}
end

--[=[
	@within Builders.AutomoderationRule

	Constructs a new automoderation rule builder.

	```luau
	local rule = AutomoderationRule.new({
		name = "My Rule",
		eventType = "MESSAGE_SEND",
		triggerType = "KEYWORD",
		actions = {
			{
				type = "BLOCK_MESSAGE",
				metadata = {}
			}
		}
	})
	```
]=]
function AutomoderationRule.Interface.new(resource: {
	name: string?,
	eventType: apiTypes.EventTypes?,
	triggerType: apiTypes.TriggerTypes?,
	triggerMetadata: triggerMetadata.JSON?,
	actions: { action.JSON }?,
	enabled: boolean?,
	exemptRoles: { apiTypes.Snowflake }?,
	exemptChannels: { apiTypes.Snowflake }?,
}?): AutomoderationRule
	local self = setmetatable(
		{
			--[=[
				@prop name string
				@within Builders.AutomoderationRule
				The name of the automoderation rule.
			]=]
			name = nil,

			--[=[
				@prop eventType Builders.EventTypes
				@within Builders.AutomoderationRule
				The event type that will trigger the rule.
			]=]
			eventType = nil,

			--[=[
				@prop triggerType Builders.TriggerTypes
				@within Builders.AutomoderationRule
				The type of content which can trigger the rule.
			]=]
			triggerType = nil,

			--[=[
				@prop triggerMetadata Builders.TriggerMetadata
				@within Builders.AutomoderationRule
				The trigger metadata for the rule.
			]=]
			triggerMetadata = nil,

			--[=[
				@prop actions {Builders.Action}
				@within Builders.AutomoderationRule
				The actions which will execute when the rule is triggered.
			]=]
			actions = nil,

			--[=[
				@prop enabled boolean
				@within Builders.AutomoderationRule
				Whether the rule is enabled.
			]=]
			enabled = nil,

			--[=[
				@prop exemptRoles {string}
				@within Builders.AutomoderationRule
				The role ids that should not be affected by the rule.
			]=]
			exemptRoles = nil,

			--[=[
				@prop exemptChannels {string}
				@within Builders.AutomoderationRule
				The channel ids that should not be affected by the rule.
			]=]
			exemptChannels = nil,
		} :: AutomoderationRule,
		{
			__index = AutomoderationRule.Prototype,
		}
	)

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.eventType then
			self:setEventType(resource.eventType)
		end

		if resource.triggerType then
			self:setTriggerType(resource.triggerType)
		end

		if resource.triggerMetadata then
			self:setTriggerMetadata(resource.triggerMetadata)
		end

		if resource.actions then
			self:setActions(resource.actions)
		end

		if resource.enabled then
			self:setEnabled(resource.enabled)
		end

		if resource.exemptRoles then
			self:setExemptRoles(resource.exemptRoles)
		end

		if resource.exemptChannels then
			self:setExemptChannels(resource.exemptChannels)
		end
	end

	return self
end

export type AutomoderationRule = typeof(AutomoderationRule.Prototype) & {
	name: string,
	eventType: apiTypes.EventTypes,
	triggerType: apiTypes.TriggerTypes,
	triggerMetadata: triggerMetadata.JSON?,
	actions: { action.JSON },
	enabled: boolean?,
	exemptRoles: { apiTypes.Snowflake }?,
	exemptChannels: { apiTypes.Snowflake }?,
}

export type JSON = typeof(AutomoderationRule.Prototype.build(nil :: any))

return AutomoderationRule.Interface
