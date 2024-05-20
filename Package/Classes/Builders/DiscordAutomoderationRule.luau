local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Objects.DiscordAutomoderationRule

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordAutomoderationRule = {}

DiscordAutomoderationRule.Prototype = {}
DiscordAutomoderationRule.Interface = {}

DiscordAutomoderationRule.Prototype.type = "DiscordAutomoderationRule"

DiscordAutomoderationRule.Interface.EventType = Enumerate.new({
	MessageSend = 1
})

DiscordAutomoderationRule.Interface.TriggerType = Enumerate.new({
	Keyword = 1,
	Spam = 3,
	KeywordPreset = 4,
	MentionSpam = 5
})

DiscordAutomoderationRule.Interface.KeywordPresets = Enumerate.new({
	Profanity = 1,
	SexualContent = 2,
	Slurs = 3,
})

DiscordAutomoderationRule.Interface.ActionType = Enumerate.new({
	BlockMessage = 1,
	SendAlertMessage = 2,
	Timeout = 3,
})

function DiscordAutomoderationRule.Prototype.setName(self: DiscordAutomoderationRule, name: string)
	self.ruleName = name
end

function DiscordAutomoderationRule.Prototype.setEventType(self: DiscordAutomoderationRule, eventType: number)
	self.roleEventType = eventType	
end

function DiscordAutomoderationRule.Prototype.setTriggerType(self: DiscordAutomoderationRule, triggerType: number)
	self.ruleTriggerType = triggerType
end

function DiscordAutomoderationRule.Prototype.setTriggerMetadata(self: DiscordAutomoderationRule, triggerMetadata: {
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

function DiscordAutomoderationRule.Prototype.addAction(self: DiscordAutomoderationRule, actionType: number, actionMetadata: {
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

function DiscordAutomoderationRule.Prototype.setEnabled(self: DiscordAutomoderationRule, enabled: boolean)
	self.ruleEnabled = enabled
end

function DiscordAutomoderationRule.Prototype.addExemptRole(self: DiscordAutomoderationRule, roleId: string)
	table.insert(self.exemptRoles, roleId)
end

function DiscordAutomoderationRule.Prototype.addExemptChannel(self: DiscordAutomoderationRule, channelId: string)
	table.insert(self.exemptChannels, channelId)
end

function DiscordAutomoderationRule.Prototype.toJSONObject(self: DiscordAutomoderationRule)
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

function DiscordAutomoderationRule.Interface.new(): DiscordAutomoderationRule
	return Construct({
		actions = {},
		exemptRoles = {},
		exemptChannels = {}
	}, DiscordAutomoderationRule.Prototype) :: any
end

export type DiscordAutomoderationRule = typeof(DiscordAutomoderationRule.Prototype) & {
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

return DiscordAutomoderationRule.Interface