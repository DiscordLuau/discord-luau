local triggerMetadata = require("../../src/automoderation/trigger/metadata")
local frktest = require("../../../../luau_packages/frktest")
local apiTypes = require("../../luau_packages/api_types")

local TriggerMetadata = triggerMetadata
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("TriggerMetadata builds without presets set (does not error)", function()
		local tm = TriggerMetadata.new()
		check.should_not_error(function()
			tm:build()
			return
		end)
	end)

	test.case("TriggerMetadata presets are translated to integers", function()
		local tm = TriggerMetadata.new()
		tm:setPresets({ "Profanity" })
		local json = tm:build()

		check.equal(json.presets ~= nil, true)
		local presets = json.presets
		assert(presets, "presets should not be nil")
		check.equal(type(presets[1]), "number")
		check.equal(presets[1], apiTypes.guild.KeywordPresetType.Profanity)
	end)

	test.case("TriggerMetadata builds with keyword_filter", function()
		local tm = TriggerMetadata.new()
		tm:setKeywordFilter({ "badword", "otherword" })
		local json = tm:build()

		check.equal(json.keyword_filter[1], "badword")
		check.equal(json.keyword_filter[2], "otherword")
	end)

	test.case("TriggerMetadata builds with mention_total_limit", function()
		local tm = TriggerMetadata.new()
		tm:setMentionTotalLimit(5)
		local json = tm:build()

		check.equal(json.mention_total_limit, 5)
	end)

	test.case("TriggerMetadata presets is nil in output when not set", function()
		local tm = TriggerMetadata.new()
		local json = tm:build()

		check.equal(json.presets, nil)
	end)

	test.case("TriggerMetadata initializes from resource table", function()
		local tm = TriggerMetadata.new({
			keywordFilter = { "spam" },
			mentionTotalLimit = 3,
		})
		local json = tm:build()

		check.equal(json.keyword_filter[1], "spam")
		check.equal(json.mention_total_limit, 3)
	end)
end
