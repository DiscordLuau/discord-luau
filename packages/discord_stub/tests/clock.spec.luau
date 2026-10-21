local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local discordStub = require("../src/init")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.suite("discord_stub clock", function()
		test.case("virtual time runs 100x faster and is restored on stop", function()
			local originalTask = stdPolyfills.task
			local originalDatetime = stdPolyfills.datetime
			local stub = discordStub.new({ clock = "virtual" })
			local before = stdPolyfills.datetime.now().unixTimestampMillis
			local started = os.clock()

			check.equal(stub.clock:wait(1), 1)
			check.greater_eq(os.clock() - started, 0.009)
			check.is_true(os.clock() - started < 0.5)
			check.greater_eq(stdPolyfills.datetime.now().unixTimestampMillis, before + 999)

			stub:stop()
			stub:stop()

			check.equal(stdPolyfills.task, originalTask)
			check.equal(stdPolyfills.datetime, originalDatetime)
		end)

		test.case(
			"waitFor returns true when the predicate turns truthy before the deadline, false after the deadline in clock time",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local flag = false

				stdPolyfills.task.delay(2, function()
					flag = true
				end)

				local started = stub.clock:now()

				check.is_true(stub.clock:waitFor(function()
					return flag
				end, 10))
				check.lesser(stub.clock:now() - started, 10)

				local neverStarted = stub.clock:now()

				check.is_false(stub.clock:waitFor(function()
					return false
				end, 5))
				check.greater_eq(stub.clock:now() - neverStarted, 5)

				stub:stop()
			end
		)

		test.case("a real clock leaves std_polyfills alone", function()
			local originalTask = stdPolyfills.task
			local stub = discordStub.new()

			check.equal(stdPolyfills.task, originalTask)
			check.equal(stub.clock:wait(0.01), 0.01)

			stub:stop()
		end)
	end)
end
