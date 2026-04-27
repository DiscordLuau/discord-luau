--[=[
	@class Builders.AutoModeration.TriggerMetadata
	@__index Prototype

	Implementation of a discord auto moderation trigger metadata object as a luau builder.
]=]

--[=[
	@prop keywordFilter {string}
	@within Builders.AutoModeration.TriggerMetadata
	Array of strings that represent keywords that will trigger the rule.
]=]

--[=[
	@prop regexPatterns {string}
	@within Builders.AutoModeration.TriggerMetadata
	Array of strings that represent regex patterns that will trigger the rule.
]=]

--[=[
	@prop presets {api_types.KeywordPresetType}
	@within Builders.AutoModeration.TriggerMetadata
	Array of preset keyword types that will trigger the rule.
]=]

--[=[
	@prop allowList {string}
	@within Builders.AutoModeration.TriggerMetadata
	Array of strings that represent keywords that should not trigger the rule.
]=]

--[=[
	@prop mentionTotalLimit number
	@within Builders.AutoModeration.TriggerMetadata
	Total number of unique role and user mentions allowed per message.
]=]

--[=[
	@prop mentionRaidProtectionEnabled boolean
	@within Builders.AutoModeration.TriggerMetadata
	Whether to automatically detect mention raids and remove them.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local TriggerMetadata = {}

TriggerMetadata.Prototype = {}
TriggerMetadata.Interface = {}

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Sets the list of keywords to match.
]=]
function TriggerMetadata.Prototype.setKeywordFilter(self: TriggerMetadata, keywordFilter: { string }): TriggerMetadata
	self.keywordFilter = keywordFilter

	return self
end

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Sets the list of regular expressions to match.
]=]
function TriggerMetadata.Prototype.setRegexPatterns(self: TriggerMetadata, regexPatterns: { string }): TriggerMetadata
	self.regexPatterns = regexPatterns

	return self
end

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Sets the list of preset keywords to match.
]=]
function TriggerMetadata.Prototype.setPresets(
	self: TriggerMetadata,
	presets: { apiTypes.KeywordPresetType }
): TriggerMetadata
	self.presets = presets

	return self
end

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Sets the list of allowed keywords.
]=]
function TriggerMetadata.Prototype.setAllowList(self: TriggerMetadata, allowList: { string }): TriggerMetadata
	self.allowList = allowList

	return self
end

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Sets the maximum number of mentions allowed.
]=]
function TriggerMetadata.Prototype.setMentionTotalLimit(
	self: TriggerMetadata,
	mentionTotalLimit: number
): TriggerMetadata
	self.mentionTotalLimit = mentionTotalLimit

	return self
end

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Sets whether raid protection is enabled.
]=]
function TriggerMetadata.Prototype.setMentionRaidProtectionEnabled(
	self: TriggerMetadata,
	mentionRaidProtectionEnabled: boolean
): TriggerMetadata
	self.mentionRaidProtectionEnabled = mentionRaidProtectionEnabled

	return self
end

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Builds the trigger metadata object.
]=]
function TriggerMetadata.Prototype.build(self: TriggerMetadata): JSON
	local presets = {}

	for _, preset in self.presets do
		table.insert(presets, apiTypes.guild.KeywordPresetType[preset])
	end

	return {
		keyword_filter = self.keywordFilter,
		regex_patterns = self.regexPatterns,
		presets = presets,
		allow_list = self.allowList,
		mention_total_limit = self.mentionTotalLimit,
		mention_raid_protection_enabled = self.mentionRaidProtectionEnabled,
	}
end

--[=[
	@within Builders.AutoModeration.TriggerMetadata

	Responsible for creating a new TriggerMetadata.

	```luau
	local metadata = TriggerMetadata.new({
		keywordFilter = {"bad", "words"},
		mentionTotalLimit = 5
	})
	```
]=]
function TriggerMetadata.Interface.new(resource: {
	keywordFilter: { string }?,
	regexPatterns: { string }?,
	presets: { apiTypes.KeywordPresetType }?,
	allowList: { string }?,
	mentionTotalLimit: number?,
	mentionRaidProtectionEnabled: boolean?,
}?): TriggerMetadata
	local self = setmetatable(
		{
			keywordFilter = nil,

			regexPatterns = nil,

			presets = nil,

			allowList = nil,

			mentionTotalLimit = nil,

			mentionRaidProtectionEnabled = nil,
		} :: TriggerMetadata,
		{
			__index = TriggerMetadata.Prototype,
		}
	)

	if resource then
		if resource.keywordFilter then
			self:setKeywordFilter(resource.keywordFilter)
		end

		if resource.regexPatterns then
			self:setRegexPatterns(resource.regexPatterns)
		end

		if resource.presets then
			self:setPresets(resource.presets)
		end

		if resource.allowList then
			self:setAllowList(resource.allowList)
		end

		if resource.mentionTotalLimit then
			self:setMentionTotalLimit(resource.mentionTotalLimit)
		end

		if resource.mentionRaidProtectionEnabled then
			self:setMentionRaidProtectionEnabled(resource.mentionRaidProtectionEnabled)
		end
	end

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

export type JSON = typeof(TriggerMetadata.Prototype.build(nil :: any))

return TriggerMetadata.Interface
