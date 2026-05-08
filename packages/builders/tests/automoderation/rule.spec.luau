local rule = require("../../src/automoderation/rule")
local action = require("../../src/automoderation/action/action")
local frktest = require("../../../../luau_packages/frktest")

local Rule = rule
local Action = action
local test = frktest.test
local check = frktest.assert.check

local function makeAction()
	return Action.new():setType("BlockMessage"):build()
end

return function()
	test.case("Rule builds with required fields", function()
		local r = Rule.new()
		r:setName("My Rule")
			:setEventType("MessageSend")
			:setTriggerType("Keyword")
			:setActions({ makeAction() })
		local json = r:build()

		check.equal(json.name, "My Rule")
	end)

	test.case("Rule new() with enabled=false applies the value", function()
		local r = Rule.new({ enabled = false })

		check.equal(r.enabled, false)
	end)

	test.case("Rule new() with enabled=true applies the value", function()
		local r = Rule.new({ enabled = true })

		check.equal(r.enabled, true)
	end)

	test.case("Rule setEnabled(false) sets the field", function()
		local r = Rule.new()
		r:setEnabled(false)

		check.equal(r.enabled, false)
	end)

	test.case("Rule enabled field is emitted in build output", function()
		local r = Rule.new()
		r:setName("Test"):setEventType("MessageSend"):setTriggerType("Keyword"):setActions({ makeAction() })
		r:setEnabled(false)
		local json = r:build()

		check.equal(json.enabled, false)
	end)

	test.case("Rule exempt roles and channels are passed through", function()
		local r = Rule.new()
		r:setName("Test")
			:setEventType("MessageSend")
			:setTriggerType("Keyword")
			:setActions({ makeAction() })
			:setExemptRoles({ "111111111111111111" })
			:setExemptChannels({ "222222222222222222" })
		local json = r:build()

		local exempt_roles = json.exempt_roles
		assert(exempt_roles)
		local exempt_channels = json.exempt_channels
		assert(exempt_channels)
		check.equal(exempt_roles[1], "111111111111111111")
		check.equal(exempt_channels[1], "222222222222222222")
	end)
end
