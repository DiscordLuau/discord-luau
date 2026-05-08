local textInput = require("../../../src/message/components/textInput")
local frktest = require("../../../../../luau_packages/frktest")
local apiTypes = require("../../../luau_packages/api_types")

local TextInput = textInput
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("TextInput builds with required fields", function()
		local ti = TextInput.new():setCustomId("field-1"):setStyle("Short"):setLabel("Your name")
		local json = ti:build()

		check.equal(json.type, 4)
		check.equal(json.custom_id, "field-1")
		check.equal(json.style, apiTypes.message.TextInputStyle.Short)
		check.equal(json.label, "Your name")
	end)

	test.case("TextInput build errors when customId is missing", function()
		local ti = TextInput.new():setStyle("Short"):setLabel("Name")
		check.should_error(function()
			ti:build()
			return
		end)
	end)

	test.case("TextInput build errors when style is missing", function()
		local ti = TextInput.new():setCustomId("x"):setLabel("Name")
		check.should_error(function()
			ti:build()
			return
		end)
	end)

	test.case("TextInput build errors when label is missing", function()
		local ti = TextInput.new():setCustomId("x"):setStyle("Short")
		check.should_error(function()
			ti:build()
			return
		end)
	end)

	test.case("TextInput Paragraph style is mapped correctly", function()
		local ti = TextInput.new():setCustomId("x"):setStyle("Paragraph"):setLabel("Bio")
		local json = ti:build()

		check.equal(json.style, apiTypes.message.TextInputStyle.Paragraph)
	end)

	test.case("TextInput minLength and maxLength are validated", function()
		local ti = TextInput.new()
		check.should_error(function()
			ti:setMinLength(-1)
			return
		end)
		check.should_error(function()
			ti:setMaxLength(4001)
			return
		end)
	end)

	test.case("TextInput build errors when maxLength < minLength", function()
		local ti = TextInput.new():setCustomId("x"):setStyle("Short"):setLabel("Name")
		ti:setMinLength(10):setMaxLength(5)
		check.should_error(function()
			ti:build()
			return
		end)
	end)

	test.case("TextInput optional fields are passed through", function()
		local ti = TextInput.new()
			:setCustomId("x")
			:setStyle("Short")
			:setLabel("Name")
			:setPlaceholder("Enter name")
			:setValue("Default")
			:setIsRequired(false)
		local json = ti:build()

		check.equal(json.placeholder, "Enter name")
		check.equal(json.value, "Default")
		check.equal(json.required, false)
	end)
end
