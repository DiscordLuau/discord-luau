local forumTag = require("../src/forumTag")
local frktest = require("../../../luau_packages/frktest")

local ForumTag = forumTag
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("ForumTag builder builds JSON with provided tag properties", function()
		local tag = ForumTag.new({
			tagName = "Bug Report",
			emoji = { name = "smiley-face", id = "123456789012345678" },
		})
		tag:setModerated(false)
		local json = tag:build()

		check.equal(json.name, "Bug Report")
		check.equal(json.moderated, false)
		check.equal(json.emoji_name, "smiley-face")
		check.equal(json.emoji_id, "123456789012345678")
	end)

	test.case("ForumTag builder accepts names with spaces and uppercase", function()
		local tag = ForumTag.new({ tagName = "valid-tag" })
		check.should_not_error(function()
			tag:setName("Feature Request")
			return tag
		end)
		check.should_not_error(function()
			tag:setName("URGENT")
			return tag
		end)
	end)

	test.case("ForumTag builder allows chaining of methods", function()
		local tag = ForumTag.new({ tagName = "Chain Tag" })
		check.should_not_error(function()
			tag:setName("Chain Tag"):setModerated(true):setEmoji("987654321098765432", "cool-emoji"):build()
			return tag
		end)
	end)

	test.case("ForumTag builder fromId sets id property and builds correctly", function()
		local tag = ForumTag.fromId({
			tagId = "111111111111111111",
			tagName = "Resource Tag",
			emoji = { name = "happy-emoji", id = "222222222222222222" },
		})
		local json = tag:build()

		check.equal(tag.id, "111111111111111111")
		check.equal(json.name, "Resource Tag")
		check.equal(json.emoji_name, "happy-emoji")
		check.equal(json.emoji_id, "222222222222222222")
	end)

	test.case("ForumTag builder errors when tag name exceeds 20 characters", function()
		local longTag = string.rep("a", 21)
		local tag = ForumTag.new({ tagName = "valid-tag" })

		check.should_error(function()
			tag:setName(longTag)
			return
		end)
	end)

	test.case("ForumTag builder errors when tag name is empty", function()
		local tag = ForumTag.new({ tagName = "valid-tag" })
		check.should_error(function()
			tag:setName("")
			return
		end)
	end)
end
