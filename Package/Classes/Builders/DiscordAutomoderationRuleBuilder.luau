local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class DiscordAutomoderationRuleBuilder

	DiscordAutomoderationRuleBuilder is used to construct an auto-moderation rule for a Discord guild, including trigger types, actions, and exempt roles or channels.

	Usage:
	```lua
	local rule = DiscordAutomoderationRuleBuilder.new()
		:setName("No Profanity")
		:setEventType(DiscordAutomoderationRuleBuilder.EventType.MessageSend)
		:setTriggerType(DiscordAutomoderationRuleBuilder.TriggerType.Keyword)
		:setTriggerMetadata({ keywordFilter = {"badword1", "badword2"} })
		:addAction(DiscordAutomoderationRuleBuilder.ActionType.BlockMessage, { customMessage = "Profanity is not allowed!" })
		:setEnabled(true)
	```
]=]
local DiscordAutomoderationRuleBuilder = {}

DiscordAutomoderationRuleBuilder.Prototype = {}
DiscordAutomoderationRuleBuilder.Interface = {}

DiscordAutomoderationRuleBuilder.Prototype.type = "DiscordAutomoderationRuleBuilder"

--[=[
	@prop EventType table
	@within DiscordAutomoderationRuleBuilder

	An enumeration of event types.

	- MessageSend: 1
]=]
DiscordAutomoderationRuleBuilder.Interface.EventType = Enumerate.new({
	MessageSend = 1
})

--[=[
	@prop TriggerType table
	@within DiscordAutomoderationRuleBuilder

	An enumeration of trigger types.

	- Keyword: 1
	- Spam: 3
	- KeywordPreset: 4
	- MentionSpam: 5
]=]
DiscordAutomoderationRuleBuilder.Interface.TriggerType = Enumerate.new({
	Keyword = 1,
	Spam = 3,
	KeywordPreset = 4,
	MentionSpam = 5
})

--[=[
	@prop KeywordPresets table
	@within DiscordAutomoderationRuleBuilder

	An enumeration of keyword presets.

	- Profanity: 1
	- SexualContent: 2
	- Slurs: 3
]=]
DiscordAutomoderationRuleBuilder.Interface.KeywordPresets = Enumerate.new({
	Profanity = 1,
	SexualContent = 2,
	Slurs = 3,
})

--[=[
	@prop ActionType table
	@within DiscordAutomoderationRuleBuilder

	An enumeration of action types.

	- BlockMessage: 1
	- SendAlertMessage: 2
	- Timeout: 3
]=]
DiscordAutomoderationRuleBuilder.Interface.ActionType = Enumerate.new({
	BlockMessage = 1,
	SendAlertMessage = 2,
	Timeout = 3,
})

--[=[
	Sets the name of the rule.
	
	@method setName
	@param name string -- The name of the rule.
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.setName(self: DiscordAutomoderationRuleBuilder, name: string)
	self.ruleName = name

	return self
end

--[=[
	Sets the event type for the rule.
	
	@method setEventType
	@param eventType number -- The event type of the rule.
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.setEventType(self: DiscordAutomoderationRuleBuilder, eventType: number)
	self.roleEventType = eventType

	return self
end

--[=[
	Sets the trigger type for the rule.
	
	@method setTriggerType
	@param triggerType number -- The trigger type of the rule.
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.setTriggerType(self: DiscordAutomoderationRuleBuilder, triggerType: number)
	self.ruleTriggerType = triggerType

	return self
end

--[=[
	Sets the trigger metadata for the rule.
	
	@method setTriggerMetadata
	@param triggerMetadata table -- The metadata for the trigger.
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.setTriggerMetadata(self: DiscordAutomoderationRuleBuilder, triggerMetadata: {
	keywordFilter: { string }?,
	regexPattern: { string }?,
	presets: { number }?,
	allowList: { string }?,
	mentionTotalLimit: number?,
	mentionRaidProtectionEnabled: boolean?
})
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
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.addAction(self: DiscordAutomoderationRuleBuilder, actionType: number, actionMetadata: {
	channelId: string?,
	durationSeconds: number?,
	customMessage: string?
})
	table.insert(self.actions, {
		type = actionType,
		metadata = {
			channelId = actionMetadata.channelId,
			durationSeconds = actionMetadata.durationSeconds,
			customMessage = actionMetadata.customMessage
		}
	})

	return self
end

--[=[
	Sets whether the rule is enabled.
	
	@method setEnabled
	@param enabled boolean -- Whether the rule is enabled.
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.setEnabled(self: DiscordAutomoderationRuleBuilder, enabled: boolean)
	self.ruleEnabled = enabled

	return self
end

--[=[
	Adds an exempt role to the rule.
	
	@method addExemptRole
	@param roleId string -- The ID of the role to exempt.
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.addExemptRole(self: DiscordAutomoderationRuleBuilder, roleId: string)
	table.insert(self.exemptRoles, roleId)

	return self
end

--[=[
	Adds an exempt channel to the rule.
	
	@method addExemptChannel
	@param channelId string -- The ID of the channel to exempt.
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- Returns the DiscordAutomoderationRuleBuilder instance for method chaining.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.addExemptChannel(self: DiscordAutomoderationRuleBuilder, channelId: string)
	table.insert(self.exemptChannels, channelId)

	return self
end

--[=[
	Converts the rule to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within DiscordAutomoderationRuleBuilder
	@return table -- The JSON representation of the rule.
]=]
function DiscordAutomoderationRuleBuilder.Prototype.toJSONObject(self: DiscordAutomoderationRuleBuilder)
	local actions = {}

	for _, actionObject in self.actions do
		table.insert(actions, {
			type = actionObject.type,
			metadata = {
				channel_id = actionObject.metadata.channelId,
				duration_seconds = actionObject.metadata.durationSeconds,
				custom_message = actionObject.metadata.customMessage,
			}
		})
	end

	return {
		name = self.ruleName,
		event_type = self.roleEventType,
		trigger_type = self.ruleTriggerType,
		trigger_metadata = self.triggerMetadata,
		actions = actions,
		enabled = self.ruleEnabled,
		exempt_roles = self.exemptRoles,
		exempt_channels = self.exemptChannels
	}
end

--[=[
	Creates a new instance of DiscordAutomoderationRuleBuilder.
	
	@function new
	@within DiscordAutomoderationRuleBuilder
	@return DiscordAutomoderationRuleBuilder -- A new instance of DiscordAutomoderationRuleBuilder.
]=]
function DiscordAutomoderationRuleBuilder.Interface.new(): DiscordAutomoderationRuleBuilder
	return Construct({
		actions = {},
		exemptRoles = {},
		exemptChannels = {}
	}, DiscordAutomoderationRuleBuilder.Prototype) :: any
end

export type DiscordAutomoderationRuleBuilder = typeof(DiscordAutomoderationRuleBuilder.Prototype) & {
	exemptChannels: { string },
	exemptRoles: { string },
	actions: {
		{ 
			type: number,
			metadata: {
				channelId: string?,
				durationSeconds: number?,
				customMessage: string?
			}
		}	
	},

	triggerMetadata: {
		keywordFilter: { string },
		regexPattern: { string },
		presets: { number },
		allowList: { string },
		mentionTotalLimit: number,
		mentionRaidProtectionEnabled: boolean
	},

	ruleEnabled: boolean,
	ruleTriggerType: number,
	ruleName: string,
	roleEventType: number
}

return DiscordAutomoderationRuleBuilder.Interface
