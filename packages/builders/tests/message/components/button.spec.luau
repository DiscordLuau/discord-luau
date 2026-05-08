local button = require("../../../src/message/components/button")
local frktest = require("../../../../../luau_packages/frktest")
local apiTypes = require("../../../luau_packages/api_types")

local Button = button
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Button builds a Primary button with customId", function()
		local b = Button.new():setStyle("Blurple"):setLabel("Click me"):setCustomId("btn-1")
		local json = b:build()

		check.equal(json.type, 2)
		check.equal(json.style, apiTypes.message.ButtonStyle.Blurple)
		check.equal(json.label, "Click me")
		check.equal(json.custom_id, "btn-1")
	end)

	test.case("Button builds a Link button with url", function()
		local b = Button.new():setStyle("Link"):setLabel("Visit"):setUrl("https://discord.com")
		local json = b:build()

		check.equal(json.url, "https://discord.com")
		check.equal(json.custom_id, nil)
	end)

	test.case("Button builds a Premium button with skuId", function()
		local b = Button.new():setStyle("Premium"):setSkuId("123456789012345678")
		local json = b:build()

		check.equal(json.sku_id, "123456789012345678")
	end)

	test.case("Button build errors when style is not set", function()
		local b = Button.new()
		check.should_error(function()
			b:build()
			return
		end)
	end)

	test.case("Non-link button build errors without customId", function()
		local b = Button.new():setStyle("Blurple"):setLabel("Click")
		check.should_error(function()
			b:build()
			return
		end)
	end)

	test.case("Non-link button build errors with url set", function()
		local b = Button.new():setStyle("Blurple"):setLabel("Click"):setCustomId("x"):setUrl("https://discord.com")
		check.should_error(function()
			b:build()
			return
		end)
	end)

	test.case("Link button build errors without url", function()
		local b = Button.new():setStyle("Link"):setLabel("Visit")
		check.should_error(function()
			b:build()
			return
		end)
	end)

	test.case("Link button build errors with customId set", function()
		local b = Button.new():setStyle("Link"):setUrl("https://discord.com"):setCustomId("x")
		check.should_error(function()
			b:build()
			return
		end)
	end)

	test.case("Premium button build errors with label set", function()
		local b = Button.new():setStyle("Premium"):setSkuId("123"):setLabel("Buy")
		check.should_error(function()
			b:build()
			return
		end)
	end)

	test.case("Button label rejects empty string", function()
		local b = Button.new()
		check.should_error(function()
			b:setLabel("")
			return
		end)
	end)

	test.case("Button label rejects strings longer than 80 characters", function()
		local b = Button.new()
		check.should_error(function()
			b:setLabel(string.rep("a", 81))
			return
		end)
	end)

	test.case("Button disabled flag is passed through", function()
		local b = Button.new():setStyle("Blurple"):setLabel("Off"):setCustomId("x"):setDisabled(true)
		local json = b:build()

		check.equal(json.disabled, true)
	end)
end
