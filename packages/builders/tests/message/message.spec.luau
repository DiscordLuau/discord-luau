local message = require("../../src/message/message")
local frktest = require("../../../../luau_packages/frktest")

local Message = message
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Message builds with content", function()
		local m = Message.new()
		m:setContent("Hello world")
		local json = m:build()

		check.equal(json.content, "Hello world")
	end)

	test.case("Message allows exactly 2000 character content", function()
		local m = Message.new()
		check.should_not_error(function()
			m:setContent(string.rep("a", 2000))
			return
		end)
	end)

	test.case("Message errors when content exceeds 2000 characters", function()
		local m = Message.new()
		check.should_error(function()
			m:setContent(string.rep("a", 2001))
			return
		end)
	end)

	test.case("Message builds with no content (all optional)", function()
		local m = Message.new()
		local json = m:build()

		check.equal(json.content, nil)
		check.equal(json.embeds, nil)
		check.equal(json.components, nil)
	end)

	test.case("Message errors when more than 10 embeds are added", function()
		local m = Message.new()
		local fakeEmbed = { title = "x" } :: any
		for _ = 1, 10 do
			m:addEmbed(fakeEmbed)
		end
		check.should_error(function()
			m:addEmbed(fakeEmbed)
			return
		end)
	end)

	test.case("Message errors when more than 3 sticker IDs are added", function()
		local m = Message.new()
		m:addStickerId("1"):addStickerId("2"):addStickerId("3")
		check.should_error(function()
			m:addStickerId("4")
			return
		end)
	end)

	test.case("Message nonce must be at most 25 characters", function()
		local m = Message.new()
		check.should_error(function()
			m:setNonce(string.rep("a", 26))
			return
		end)
	end)

	test.case("Message tts is passed through", function()
		local m = Message.new()
		m:setTTS(true)
		local json = m:build()

		check.equal(json.tts, true)
	end)

	test.case("Message flags are combined with bor", function()
		local m = Message.new()
		m:setFlags(4):setFlags(8)
		local json = m:build()

		check.equal(json.flags, 12)
	end)
end
