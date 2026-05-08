local scheduledEventRecurrenceRule = require("../../src/guild/scheduledEventRecurrenceRule")
local frktest = require("../../../../luau_packages/frktest")
local apiTypes = require("../../luau_packages/api_types")

local RecurrenceRule = scheduledEventRecurrenceRule
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("RecurrenceRule builds with required fields", function()
		local rule = RecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setFrequency("Weekly"):setInterval(1)
		local json = rule:build()

		check.equal(json.start, "2026-06-01T18:00:00Z")
		check.equal(json.frequency, apiTypes.guild.RecurrenceRuleFrequency.Weekly)
		check.equal(json.interval, 1)
		check.equal(type(json.frequency), "number")
	end)

	test.case("RecurrenceRule frequency maps to integer", function()
		local rule = RecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setFrequency("Daily"):setInterval(1)
		local json = rule:build()

		check.equal(json.frequency, apiTypes.guild.RecurrenceRuleFrequency.Daily)
		check.equal(type(json.frequency), "number")
	end)

	test.case("RecurrenceRule by_weekday maps to integers", function()
		local rule = RecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setFrequency("Weekly"):setInterval(1)
		rule:setByWeekday({ "Monday", "Friday" })
		local json = rule:build()

		check.equal(json.by_weekday ~= nil, true)
		local by_weekday = json.by_weekday
		assert(by_weekday)
		check.equal(by_weekday[1], apiTypes.guild.RecurrenceRuleWeekday.Monday)
		check.equal(by_weekday[2], apiTypes.guild.RecurrenceRuleWeekday.Friday)
		check.equal(type(by_weekday[1]), "number")
	end)

	test.case("RecurrenceRule by_month maps to integers", function()
		local rule = RecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setFrequency("Monthly"):setInterval(1)
		rule:setByMonth({ "January", "July" })
		local json = rule:build()

		local by_month = json.by_month
		assert(by_month)
		check.equal(by_month[1], apiTypes.guild.RecurrenceRuleMonth.January)
		check.equal(by_month[2], apiTypes.guild.RecurrenceRuleMonth.July)
	end)

	test.case("RecurrenceRule build errors when start is missing", function()
		local rule = RecurrenceRule.new()
		rule:setFrequency("Weekly"):setInterval(1)
		check.should_error(function()
			rule:build()
			return
		end)
	end)

	test.case("RecurrenceRule build errors when frequency is missing", function()
		local rule = RecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setInterval(1)
		check.should_error(function()
			rule:build()
			return
		end)
	end)

	test.case("RecurrenceRule build errors when interval is missing", function()
		local rule = RecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setFrequency("Weekly")
		check.should_error(function()
			rule:build()
			return
		end)
	end)

	test.case("RecurrenceRule interval must be at least 1", function()
		local rule = RecurrenceRule.new()
		check.should_error(function()
			rule:setInterval(0)
			return
		end)
	end)

	test.case("RecurrenceRule optional fields are nil when not set", function()
		local rule = RecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setFrequency("Weekly"):setInterval(1)
		local json = rule:build()

		check.equal(json.by_weekday, nil)
		check.equal(json.by_month, nil)
		check.equal(json.by_month_day, nil)
		check.equal(json.by_n_weekday, nil)
	end)
end
