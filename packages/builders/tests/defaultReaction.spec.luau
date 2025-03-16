local defaultReaction = require("../src/default/reaction")
local frktest = require("../../../lune_packages/frktest")

local DefaultReaction = defaultReaction
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("DefaultReaction builder builds with only emojiId", function()
		local reaction = DefaultReaction.new({ emojiId = "000000000000000001", emojiName = nil })
		local json = reaction:build()

		check.equal(json.emoji_id, "000000000000000001")
		check.equal(json.emoji_name, nil)
	end)

	test.case("DefaultReaction builder builds with only emojiName", function()
		local reaction = DefaultReaction.new({ emojiId = nil, emojiName = "smile" })
		local json = reaction:build()

		check.equal(json.emoji_id, nil)
		check.equal(json.emoji_name, "smile")
	end)

	test.case("DefaultReaction builder builds with both emojiId and emojiName", function()
		local reaction = DefaultReaction.new({ emojiId = "000000000000000002", emojiName = "wink" })
		local json = reaction:build()

		check.equal(json.emoji_id, "000000000000000002")
		check.equal(json.emoji_name, "wink")
	end)
end
