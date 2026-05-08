local executeWebhook = require("../../src/webhook/executeWebhook")
local frktest = require("../../../../luau_packages/frktest")

local ExecuteWebhook = executeWebhook
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("ExecuteWebhook builds with content", function()
		local ew = ExecuteWebhook.new()
		ew:setContent("Hello from webhook!")
		local json = ew:build()

		check.equal(json.content, "Hello from webhook!")
	end)

	test.case("ExecuteWebhook build errors when no content/embeds/poll/components set", function()
		local ew = ExecuteWebhook.new()
		check.should_error(function()
			ew:build()
			return
		end)
	end)

	test.case("ExecuteWebhook content rejects strings longer than 2000 characters", function()
		local ew = ExecuteWebhook.new()
		check.should_error(function()
			ew:setContent(string.rep("a", 2001))
			return
		end)
	end)

	test.case("ExecuteWebhook content accepts exactly 2000 characters", function()
		local ew = ExecuteWebhook.new()
		check.should_not_error(function()
			ew:setContent(string.rep("a", 2000))
			return
		end)
	end)

	test.case("ExecuteWebhook username and avatar_url are passed through", function()
		local ew = ExecuteWebhook.new()
		ew:setContent("Hi"):setUsername("Custom Bot"):setAvatarUrl("https://example.com/avatar.png")
		local json = ew:build()

		check.equal(json.username, "Custom Bot")
		check.equal(json.avatar_url, "https://example.com/avatar.png")
	end)

	test.case("ExecuteWebhook tts is passed through", function()
		local ew = ExecuteWebhook.new()
		ew:setContent("Text"):setTTS(true)
		local json = ew:build()

		check.equal(json.tts, true)
	end)

	test.case("ExecuteWebhook embeds limit is 10", function()
		local ew = ExecuteWebhook.new()
		for _ = 1, 10 do
			ew:addEmbed({ title = "Embed" } :: any)
		end
		check.should_error(function()
			ew:addEmbed({ title = "11th" } :: any)
			return
		end)
	end)

	test.case("ExecuteWebhook thread_name is passed through", function()
		local ew = ExecuteWebhook.new()
		ew:setContent("Hi"):setThreadName("my-thread")
		local json = ew:build()

		check.equal(json.thread_name, "my-thread")
	end)

	test.case("ExecuteWebhook optional fields are nil when not set", function()
		local ew = ExecuteWebhook.new()
		ew:setContent("Hi")
		local json = ew:build()

		check.equal(json.username, nil)
		check.equal(json.avatar_url, nil)
		check.equal(json.tts, nil)
		check.equal(json.embeds, nil)
		check.equal(json.thread_name, nil)
		check.equal(json.poll, nil)
	end)
end
