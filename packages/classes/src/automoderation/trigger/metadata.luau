--[[
	Implementation of the Discord TriggerMetadata class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object-trigger-metadata
]]

local apiTypes = require("../../../lune_packages/api_types")

local TriggerMetadata = {}

TriggerMetadata.Interface = {}
TriggerMetadata.Prototype = {}

function TriggerMetadata.Prototype.sync(
	self: TriggerMetadata,
	triggerMetadataData: apiTypes.AutomoderationRuleTriggerMetadataObject
)
	local presets = {}

	for _, presetType in triggerMetadataData.presets do
		table.insert(presets, apiTypes.guild.KeywordPresetType[presetType])
	end

	self.keywordFilter = triggerMetadataData.keyword_filter
	self.regexPatterns = triggerMetadataData.regex_patterns
	self.presets = presets
	self.allowList = triggerMetadataData.allow_list
	self.mentionRaidProtectionEnabled = triggerMetadataData.mention_raid_protection_enabled
end

function TriggerMetadata.Interface.new(
	triggerMetadataData: apiTypes.AutomoderationRuleTriggerMetadataObject
): TriggerMetadata
	local self = setmetatable({} :: TriggerMetadata, { __index = TriggerMetadata.Prototype })

	self:sync(triggerMetadataData)

	return self
end

export type TriggerMetadata = typeof(TriggerMetadata.Prototype) & {
	keywordFilter: { string },
	regexPatterns: { string },
	presets: { apiTypes.KeywordPresetType },
	allowList: { string },
	mentionTotalLimit: number,
	mentionRaidProtectionEnabled: boolean,
}

return TriggerMetadata.Interface
