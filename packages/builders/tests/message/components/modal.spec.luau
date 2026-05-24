local modal = require("../../../src/message/components/modal")
local textInput = require("../../../src/message/components/textInput")
local frktest = require("../../../../../luau_packages/frktest")

local Modal = modal
local TextInput = textInput
local test = frktest.test
local check = frktest.assert.check

local function makeTextInput()
	return TextInput.new():setCustomId("field"):setStyle("Short"):setLabel("Enter text"):build()
end

return function()
	test.case("Modal builds with required fields", function()
		local m = Modal.new()
		m:setCustomId("my-modal"):setTitle("My Modal"):setComponents({ makeTextInput() })
		local json = m:build()

		check.equal(json.custom_id, "my-modal")
		check.equal(json.title, "My Modal")
		check.equal(json.components ~= nil, true)
	end)

	test.case("Modal build errors when customId is missing", function()
		local m = Modal.new()
		m:setTitle("Title"):setComponents({ makeTextInput() })
		check.should_error(function()
			m:build()
			return
		end)
	end)

	test.case("Modal build errors when title is missing", function()
		local m = Modal.new()
		m:setCustomId("my-modal"):setComponents({ makeTextInput() })
		check.should_error(function()
			m:build()
			return
		end)
	end)

	test.case("Modal build errors when components are missing", function()
		local m = Modal.new()
		m:setCustomId("my-modal"):setTitle("My Modal")
		check.should_error(function()
			m:build()
			return
		end)
	end)

	test.case("Modal build errors when more than 5 components are set", function()
		local m = Modal.new()
		m:setCustomId("my-modal"):setTitle("My Modal")
		local components = {}
		for _ = 1, 6 do
			table.insert(components, makeTextInput())
		end
		m:setComponents(components)
		check.should_error(function()
			m:build()
			return
		end)
	end)

	test.case("Modal customId rejects empty string", function()
		local m = Modal.new()
		check.should_error(function()
			m:setCustomId("")
			return
		end)
	end)

	test.case("Modal customId rejects strings longer than 100 characters", function()
		local m = Modal.new()
		check.should_error(function()
			m:setCustomId(string.rep("a", 101))
			return
		end)
	end)

	test.case("Modal title rejects strings longer than 45 characters", function()
		local m = Modal.new()
		check.should_error(function()
			m:setTitle(string.rep("a", 46))
			return
		end)
	end)
end
