local editMessage = require("../../src/message/editMessage")
local frktest = require("../../../../luau_packages/frktest")

local EditMessage = editMessage
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("EditMessage builds with no fields set (all optional)", function()
		local em = EditMessage.new()
		local json = em:build()

		check.equal(json.content, nil)
		check.equal(json.embeds, nil)
		check.equal(json.flags, nil)
		check.equal(json.allowed_mentions, nil)
		check.equal(json.components, nil)
		check.equal(json.attachments, nil)
	end)

	test.case("EditMessage content is passed through", function()
		local em = EditMessage.new()
		em:setContent("Updated content")
		local json = em:build()

		check.equal(json.content, "Updated content")
	end)

	test.case("EditMessage content rejects strings longer than 2000 characters", function()
		local em = EditMessage.new()
		check.should_error(function()
			em:setContent(string.rep("a", 2001))
			return
		end)
	end)

	test.case("EditMessage content accepts exactly 2000 characters", function()
		local em = EditMessage.new()
		check.should_not_error(function()
			em:setContent(string.rep("a", 2000))
			return
		end)
	end)

	test.case("EditMessage setContent nil clears content", function()
		local em = EditMessage.new()
		em:setContent(nil)
		local json = em:build()

		check.equal(json.content, nil)
	end)

	test.case("EditMessage embeds are accumulated via addEmbed", function()
		local em = EditMessage.new()
		em:addEmbed({ title = "First" } :: any)
		em:addEmbed({ title = "Second" } :: any)
		local json = em:build()

		check.equal(json.embeds ~= nil, true)
		local embeds = json.embeds
		assert(embeds)
		check.equal(#embeds, 2)
	end)

	test.case("EditMessage embeds limit is 10", function()
		local em = EditMessage.new()
		for _ = 1, 10 do
			em:addEmbed({ title = "E" } :: any)
		end
		check.should_error(function()
			em:addEmbed({ title = "11th" } :: any)
			return
		end)
	end)

	test.case("EditMessage setEmbeds nil clears embeds", function()
		local em = EditMessage.new()
		em:setEmbeds(nil)
		local json = em:build()

		check.equal(json.embeds, nil)
	end)

	test.case("EditMessage flags is passed through", function()
		local em = EditMessage.new()
		em:setFlags(64)
		local json = em:build()

		check.equal(json.flags, 64)
	end)
end
