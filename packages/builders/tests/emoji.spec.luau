local emoji = require("../src/emoji")
local frktest = require("../../../lune_packages/frktest")

local Emoji = emoji
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Emoji builder creates JSON with provided id and valid kebab-case name", function()
		local e = Emoji.new()
		e:setId("123456789012345678")
		e:setName("smiley-face")
		local json = e:build()

		check.equal(json.id, "123456789012345678")
		check.equal(json.name, "smiley-face")
	end)

	test.case("Emoji builder allows chaining of methods", function()
		local e = Emoji.new()
		check.should_not_error(function()
			e:setId("987654321098765432"):setName("cool-emoji"):build()
			return e
		end)
	end)

	test.case("Emoji builder initializes correctly with resource table", function()
		local e = Emoji.new({ emojiId = "111111111111111111", emojiName = "happy-face" })
		local json = e:build()

		check.equal(json.id, "111111111111111111")
		check.equal(json.name, "happy-face")
	end)

	test.case("Emoji builder errors with non-kebab-case name", function()
		local e = Emoji.new()
		e:setId("222222222222222222")

		check.should_error(function()
			e:setName("InvalidName")

			return
		end)
	end)
end
