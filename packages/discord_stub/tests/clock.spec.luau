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

			check.greater_eq(stub.clock:wait(1), 1)
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
			check.greater_eq(stub.clock:wait(0.01), 0.01)

			stub:stop()
		end)

		local scenarios: { { mode: "virtual" | "real", requestedSeconds: number } } = {
			{ mode = "virtual", requestedSeconds = 0.5 },
			{ mode = "real", requestedSeconds = 0.02 },
		}

		for _, scenario in scenarios do
			local mode = scenario.mode
			local requestedSeconds = scenario.requestedSeconds

			test.case(`wait returns the time that passed on the {mode} clock, not the time it was asked for`, function()
				local stub = discordStub.new({ clock = scenario.mode })
				local clock = stub.clock
				local realTask = clock.originalTask
				local lateTask = {
					wait = function(seconds: number): number
						return realTask.wait(seconds * 3)
					end,
				}

				clock.originalTask = lateTask

				local startedAt = clock:now()
				local returned = clock:wait(requestedSeconds)
				local measured = clock:now() - startedAt

				check.greater_eq(returned, requestedSeconds * 2.5)
				check.lesser_eq(returned, measured)
				check.lesser(measured - returned, requestedSeconds)

				clock.originalTask = realTask

				stub:stop()

				check.equal(stdPolyfills.task, realTask)
			end)
		end
	end)
end
