local frktest = require("../../../luau_packages/frktest")

local activity = require("../src/activity")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Activity builds a custom status from its state", function()
		local json = activity.new({ activityType = "Custom", state = "Watching over the staff team!" }):build() :: any

		check.equal(json.type, 4)
		check.equal(json.state, "Watching over the staff team!")
		check.equal(json.name, "Custom Status")
	end)

	test.case("Activity keeps the state on other activity types", function()
		local json = activity
			.new()
			:setActivityName("Rocket League")
			:setActivityType("Game")
			:setState("In a match")
			:build() :: any

		check.equal(json.type, 0)
		check.equal(json.name, "Rocket League")
		check.equal(json.state, "In a match")
	end)

	test.case("Activity build errors when an activity other than a custom status has no name", function()
		local unnamed = activity.new({ activityType = "Watching" })

		check.should_error(function()
			unnamed:build()

			return
		end)
	end)
end
