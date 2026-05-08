local emoji = require("../src/emoji")
local frktest = require("../../../luau_packages/frktest")

local Emoji = emoji
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Emoji builder creates JSON for a custom emoji with id and name", function()
		local e = Emoji.new()
		e:setId("123456789012345678")
		e:setName("happy_cat")
		local json = e:build()

		check.equal(json.id, "123456789012345678")
		check.equal(json.name, "happy_cat")
	end)

	test.case("Emoji builder creates JSON for a Unicode emoji with name only", function()
		local e = Emoji.new()
		e:setName("👍")
		local json = e:build()

		check.equal(json.id, nil)
		check.equal(json.name, "👍")
	end)

	test.case("Emoji builder creates JSON for a custom emoji with id only", function()
		local e = Emoji.new()
		e:setId("123456789012345678")
		local json = e:build()

		check.equal(json.id, "123456789012345678")
	end)

	test.case("Emoji builder allows underscores in emoji names", function()
		local e = Emoji.new()
		check.should_not_error(function()
			e:setName("happy_cat_face")
			return e
		end)
	end)

	test.case("Emoji builder errors when neither id nor name is set", function()
		local e = Emoji.new()
		check.should_error(function()
			e:build()
			return
		end)
	end)

	test.case("Emoji builder allows chaining of methods", function()
		local e = Emoji.new()
		check.should_not_error(function()
			e:setId("987654321098765432"):setName("cool_emoji"):build()
			return e
		end)
	end)

	test.case("Emoji builder initializes correctly with resource table", function()
		local e = Emoji.new({ emojiId = "111111111111111111", emojiName = "party_popper" })
		local json = e:build()

		check.equal(json.id, "111111111111111111")
		check.equal(json.name, "party_popper")
	end)
end
