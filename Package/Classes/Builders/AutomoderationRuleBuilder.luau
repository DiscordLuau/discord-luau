local Construct = require("@Utils/Construct")
local Enumerate = require("@Utils/Enumerate")

local Resolvable = require("@Network/Resolvable")

local ResolvableType = require("@Enums/ResolveableType")

--[=[
	@class Builders.AutomoderationRuleBuilder

	AutomoderationRuleBuilder is used to construct an auto-moderation rule for a Discord guild, including trigger types, actions, and exempt roles or channels.

	Usage:
	```lua
	local rule = AutomoderationRuleBuilder.new()
		:setName("No Profanity")
		:setEventType(AutomoderationRuleBuilder.EventType.MessageSend)
		:setTriggerType(AutomoderationRuleBuilder.TriggerType.Keyword)
		:setTriggerMetadata({ keywordFilter = {"badword1", "badword2"} })
		:addAction(AutomoderationRuleBuilder.ActionType.BlockMessage, { customMessage = "Profanity is not allowed!" })
		:setEnabled(true)
	```
]=]
local AutomoderationRuleBuilder = {}

AutomoderationRuleBuilder.Prototype = {}
AutomoderationRuleBuilder.Interface = {}

AutomoderationRuleBuilder.Prototype.type = "AutomoderationRuleBuilder"

--[=[
	@prop EventType table
	@within Builders.AutomoderationRuleBuilder

	An enumeration of event types.

	- MessageSend: 1
]=]
AutomoderationRuleBuilder.Interface.EventType = Enumerate.new({
	MessageSend = 1,
})

--[=[
	@prop TriggerType table
	@within Builders.AutomoderationRuleBuilder

	An enumeration of trigger types.

	- Keyword: 1
	- Spam: 3
	- KeywordPreset: 4
	- MentionSpam: 5
]=]
AutomoderationRuleBuilder.Interface.TriggerType = Enumerate.new({
	Keyword = 1,
	Spam = 3,
	KeywordPreset = 4,
	MentionSpam = 5,
})

--[=[
	@prop KeywordPresets table
	@within Builders.AutomoderationRuleBuilder

	An enumeration of keyword presets.

	- Profanity: 1
	- SexualContent: 2
	- Slurs: 3
]=]
AutomoderationRuleBuilder.Interface.KeywordPresets = Enumerate.new({
	Profanity = 1,
	SexualContent = 2,
	Slurs = 3,
})

--[=[
	@prop ActionType table
	@within Builders.AutomoderationRuleBuilder

	An enumeration of action types.

	- BlockMessage: 1
	- SendAlertMessage: 2
	- Timeout: 3
]=]
AutomoderationRuleBuilder.Interface.ActionType = Enumerate.new({
	BlockMessage = 1,
	SendAlertMessage = 2,
	Timeout = 3,
})

--[=[
	Sets the name of the rule.
	
	@method setName
	@param name string -- The name of the rule.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.setName(self: AutomoderationRuleBuilder, name: string)
	self.ruleName = name

	return self
end

--[=[
	Sets the event type for the rule.
	
	@method setEventType
	@param eventType number -- The event type of the rule.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.setEventType(self: AutomoderationRuleBuilder, eventType: number)
	self.roleEventType = eventType

	return self
end

--[=[
	Sets the trigger type for the rule.
	
	@method setTriggerType
	@param triggerType number -- The trigger type of the rule.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.setTriggerType(self: AutomoderationRuleBuilder, triggerType: number)
	self.ruleTriggerType = triggerType

	return self
end

--[=[
	Sets the trigger metadata for the rule.
	
	@method setTriggerMetadata
	@param triggerMetadata table -- The metadata for the trigger.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.setTriggerMetadata(
	self: AutomoderationRuleBuilder,
	triggerMetadata: {
		keywordFilter: { string }?,
		regexPattern: { string }?,
		presets: { number }?,
		allowList: { string }?,
		mentionTotalLimit: number?,
		mentionRaidProtectionEnabled: boolean?,
	}
)
	self.triggerMetadata = {
		keywordFilter = triggerMetadata.keywordFilter or {},
		regexPattern = triggerMetadata.regexPattern or {},
		presets = triggerMetadata.presets or {},
		allowList = triggerMetadata.allowList or {},
		mentionTotalLimit = triggerMetadata.mentionTotalLimit or 1,
		mentionRaidProtectionEnabled = triggerMetadata.mentionRaidProtectionEnabled or false,
	}

	return self
end

--[=[
	Adds an action to the rule.
	
	@method addAction
	@param actionType number -- The type of action.
	@param actionMetadata table -- The metadata for the action.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.addAction(
	self: AutomoderationRuleBuilder,
	actionType: number,
	actionMetadata: {
		channelId: string?,
		durationSeconds: number?,
		customMessage: string?,
	}
)
	table.insert(self.actions, {
		type = actionType,
		metadata = {
			channelId = actionMetadata.channelId,
			durationSeconds = actionMetadata.durationSeconds,
			customMessage = actionMetadata.customMessage,
		},
	})

	return self
end

--[=[
	Sets whether the rule is enabled.
	
	@method setEnabled
	@param enabled boolean -- Whether the rule is enabled.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.setEnabled(self: AutomoderationRuleBuilder, enabled: boolean)
	self.ruleEnabled = enabled

	return self
end

--[=[
	Adds an exempt role to the rule.
	
	@method addExemptRole
	@param roleId string -- The ID of the role to exempt.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.addExemptRole(self: AutomoderationRuleBuilder, roleId: string)
	table.insert(self.exemptRoles, roleId)

	return self
end

--[=[
	Adds an exempt channel to the rule.
	
	@method addExemptChannel
	@param channelId string -- The ID of the channel to exempt.
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- Returns the AutomoderationRuleBuilder instance for method chaining.
]=]
function AutomoderationRuleBuilder.Prototype.addExemptChannel(self: AutomoderationRuleBuilder, channelId: string)
	table.insert(self.exemptChannels, channelId)

	return self
end

--[=[
	Converts the rule to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.AutomoderationRuleBuilder
	@return Network.Resolvable
]=]
function AutomoderationRuleBuilder.Prototype.toPayloadObject(self: AutomoderationRuleBuilder)
	local actions = {}

	for _, actionObject in self.actions do
		table.insert(actions, {
			type = actionObject.type,
			metadata = {
				channel_id = actionObject.metadata.channelId,
				duration_seconds = actionObject.metadata.durationSeconds,
				custom_message = actionObject.metadata.customMessage,
			},
		})
	end

	return Resolvable.new(ResolvableType.JSON, {
		{
			name = self.ruleName,
			event_type = self.roleEventType,
			trigger_type = self.ruleTriggerType,
			trigger_metadata = self.triggerMetadata,
			actions = actions,
			enabled = self.ruleEnabled,
			exempt_roles = self.exemptRoles,
			exempt_channels = self.exemptChannels,
		},
	})
end

--[=[
	Creates a new instance of AutomoderationRuleBuilder.
	
	@function new
	@within Builders.AutomoderationRuleBuilder
	@return Builders.AutomoderationRuleBuilder -- A new instance of AutomoderationRuleBuilder.
]=]
function AutomoderationRuleBuilder.Interface.new()
	return (
		Construct({
			actions = {},
			exemptRoles = {},
			exemptChannels = {},
		}, AutomoderationRuleBuilder.Prototype) :: unknown
	) :: AutomoderationRuleBuilder
end

export type AutomoderationRuleBuilder = typeof(AutomoderationRuleBuilder.Prototype) & {
	exemptChannels: { string },
	exemptRoles: { string },
	actions: {
		{
			type: number,
			metadata: {
				channelId: string?,
				durationSeconds: number?,
				customMessage: string?,
			},
		}
	},

	triggerMetadata: {
		keywordFilter: { string },
		regexPattern: { string },
		presets: { number },
		allowList: { string },
		mentionTotalLimit: number,
		mentionRaidProtectionEnabled: boolean,
	},

	ruleEnabled: boolean,
	ruleTriggerType: number,
	ruleName: string,
	roleEventType: number,
}

return AutomoderationRuleBuilder.Interface
