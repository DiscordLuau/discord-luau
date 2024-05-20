local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Objects.DiscordAutomoderationRuleBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordAutomoderationRuleBuilder = {}

DiscordAutomoderationRuleBuilder.Prototype = {}
DiscordAutomoderationRuleBuilder.Interface = {}

DiscordAutomoderationRuleBuilder.Prototype.type = "DiscordAutomoderationRuleBuilder"

DiscordAutomoderationRuleBuilder.Interface.EventType = Enumerate.new({
	MessageSend = 1
})

DiscordAutomoderationRuleBuilder.Interface.TriggerType = Enumerate.new({
	Keyword = 1,
	Spam = 3,
	KeywordPreset = 4,
	MentionSpam = 5
})

DiscordAutomoderationRuleBuilder.Interface.KeywordPresets = Enumerate.new({
	Profanity = 1,
	SexualContent = 2,
	Slurs = 3,
})

DiscordAutomoderationRuleBuilder.Interface.ActionType = Enumerate.new({
	BlockMessage = 1,
	SendAlertMessage = 2,
	Timeout = 3,
})

function DiscordAutomoderationRuleBuilder.Prototype.setName(self: DiscordAutomoderationRuleBuilder, name: string)
	self.ruleName = name
end

function DiscordAutomoderationRuleBuilder.Prototype.setEventType(self: DiscordAutomoderationRuleBuilder, eventType: number)
	self.roleEventType = eventType	
end

function DiscordAutomoderationRuleBuilder.Prototype.setTriggerType(self: DiscordAutomoderationRuleBuilder, triggerType: number)
	self.ruleTriggerType = triggerType
end

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
end

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
end

function DiscordAutomoderationRuleBuilder.Prototype.setEnabled(self: DiscordAutomoderationRuleBuilder, enabled: boolean)
	self.ruleEnabled = enabled
end

function DiscordAutomoderationRuleBuilder.Prototype.addExemptRole(self: DiscordAutomoderationRuleBuilder, roleId: string)
	table.insert(self.exemptRoles, roleId)
end

function DiscordAutomoderationRuleBuilder.Prototype.addExemptChannel(self: DiscordAutomoderationRuleBuilder, channelId: string)
	table.insert(self.exemptChannels, channelId)
end

function DiscordAutomoderationRuleBuilder.Prototype.toJSONObject(self: DiscordAutomoderationRuleBuilder)
	local triggerMetadata = {}
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
		trigger_metadata = triggerMetadata,
		actions = actions,
		enabled = self.ruleEnabled,
		exempt_roles = self.exemptRoles,
		exempt_channels = self.exemptChannels
	}
end

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