--[=[
	@class Classes.TriggerMetadata
	@__index Prototype

	Implementation of the Discord TriggerMetadata class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object-trigger-metadata
]=]

local apiTypes = require("../../../lune_packages/api_types")

local TriggerMetadata = {}

TriggerMetadata.Interface = {}
TriggerMetadata.Prototype = {}

--[=[
	@within Classes.TriggerMetadata
	@private

	Responsible for syncing data to this trigger metadata object. This is typically called by the API when this object is
	created or updated.
]=]
function TriggerMetadata.Prototype.sync(
	self: TriggerMetadata,
	triggerMetadataData: apiTypes.AutomoderationRuleTriggerMetadataObject
)
	--[=[
		@prop keywordFilter { string }
		@within Classes.TriggerMetadata
		List of strings that will trigger the rule. Each keyword can be up to 60 characters in length and can include spaces.
	]=]
	self.keywordFilter = triggerMetadataData.keyword_filter

	--[=[
		@prop regexPatterns { string }
		@within Classes.TriggerMetadata
		Array of regular expression patterns that will trigger the rule. Each regex pattern can be up to 260 characters in length.
	]=]
	self.regexPatterns = triggerMetadataData.regex_patterns

	--[=[
		@prop presets { apiTypes.KeywordPresetType }
		@within Classes.TriggerMetadata
		The internally pre-defined wordsets that will trigger the rule. These are managed by Discord and cannot be modified.
	]=]
	local presets = {}
	for _, presetType in triggerMetadataData.presets do
		table.insert(presets, apiTypes.guild.KeywordPresetType[presetType])
	end
	self.presets = presets

	--[=[
		@prop allowList { string }
		@within Classes.TriggerMetadata
		Substrings that should not trigger the rule. Each string can be up to 60 characters in length and can include spaces.
	]=]
	self.allowList = triggerMetadataData.allow_list

	--[=[
		@prop mentionRaidProtectionEnabled boolean
		@within Classes.TriggerMetadata
		Whether to automatically detect mention raids and apply the rule action. Only available for mention spam trigger type.
	]=]
	self.mentionRaidProtectionEnabled = triggerMetadataData.mention_raid_protection_enabled
end

--[=[
	@within Classes.TriggerMetadata
	@private

	Responsible for constructing this class.
]=]
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
