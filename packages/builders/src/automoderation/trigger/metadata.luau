local apiTypes = require("../../../lune_packages/api_types")

local TriggerMetadata = {}

TriggerMetadata.Prototype = {}
TriggerMetadata.Interface = {}

--[[
	Sets the list of keywords to match.
]]
function TriggerMetadata.Prototype.setKeywordFilter(self: TriggerMetadata, keywordFilter: { string }): TriggerMetadata
	self.keywordFilter = keywordFilter

	return self
end

--[[
	Sets the list of regular expressions to match.
]]
function TriggerMetadata.Prototype.setRegexPatterns(self: TriggerMetadata, regexPatterns: { string }): TriggerMetadata
	self.regexPatterns = regexPatterns

	return self
end

--[[
	Sets the list of preset keywords to match.
]]
function TriggerMetadata.Prototype.setPresets(
	self: TriggerMetadata,
	presets: { apiTypes.KeywordPresetType }
): TriggerMetadata
	self.presets = presets

	return self
end

--[[
	Sets the list of allowed keywords.
]]
function TriggerMetadata.Prototype.setAllowList(self: TriggerMetadata, allowList: { string }): TriggerMetadata
	self.allowList = allowList

	return self
end

--[[
	Sets the maximum number of mentions allowed.
]]
function TriggerMetadata.Prototype.setMentionTotalLimit(
	self: TriggerMetadata,
	mentionTotalLimit: number
): TriggerMetadata
	self.mentionTotalLimit = mentionTotalLimit

	return self
end

--[[
	Sets whether raid protection is enabled.
]]
function TriggerMetadata.Prototype.setMentionRaidProtectionEnabled(
	self: TriggerMetadata,
	mentionRaidProtectionEnabled: boolean
): TriggerMetadata
	self.mentionRaidProtectionEnabled = mentionRaidProtectionEnabled

	return self
end

--[[
	Builds the trigger metadata object.
]]
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

--[[
	Responsible for creating a new TriggerMetadata.

	```lua
	
	```
]]
function TriggerMetadata.Interface.new(resource: {
	keywordFilter: { string }?,
	regexPatterns: { string }?,
	presets: { apiTypes.KeywordPresetType }?,
	allowList: { string }?,
	mentionTotalLimit: number?,
	mentionRaidProtectionEnabled: boolean?,
}?): TriggerMetadata
	local self = setmetatable({} :: TriggerMetadata, {
		__index = TriggerMetadata.Prototype,
	})

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
