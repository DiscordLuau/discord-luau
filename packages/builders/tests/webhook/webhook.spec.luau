local webhook = require("../../src/webhook/webhook")
local frktest = require("../../../../luau_packages/frktest")

local Webhook = webhook
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Webhook builds with name", function()
		local w = Webhook.new()
		w:setName("My Bot")
		local json = w:build()

		check.equal(json.name, "My Bot")
	end)

	test.case("Webhook build errors when name is missing", function()
		local w = Webhook.new()
		check.should_error(function()
			w:build()
			return
		end)
	end)

	test.case("Webhook name rejects empty string", function()
		local w = Webhook.new()
		check.should_error(function()
			w:setName("")
			return
		end)
	end)

	test.case("Webhook name rejects strings longer than 80 characters", function()
		local w = Webhook.new()
		check.should_error(function()
			w:setName(string.rep("a", 81))
			return
		end)
	end)

	test.case("Webhook name rejects 'clyde'", function()
		local w = Webhook.new()
		check.should_error(function()
			w:setName("clyde")
			return
		end)
	end)

	test.case("Webhook avatar is optional and passed through", function()
		local w = Webhook.new()
		w:setName("Bot"):setAvatar("data:image/png;base64,abc123")
		local json = w:build()

		check.equal(json.avatar, "data:image/png;base64,abc123")
	end)

	test.case("Webhook avatar is nil when not set", function()
		local w = Webhook.new()
		w:setName("Bot")
		local json = w:build()

		check.equal(json.avatar, nil)
	end)
end
