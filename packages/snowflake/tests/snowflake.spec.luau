local frktest = require("../../../luau_packages/frktest")
local snowflake = require("../src")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("correctly decomposes a snowflake above 2^53 (175928847299117063)", function()
		local flake = snowflake.new("175928847299117063")

		local timestamp = flake:getTimestamp()
		check.equal(timestamp.unixTimestampMillis, 1462015105796)

		check.equal(flake:getInternalWorkerId(), 1)
		check.equal(flake:getInternalProcessId(), 0)
		check.equal(flake:getIncrement(), 7)
	end)

	test.case("correctly decomposes a snowflake above 2^53 (1266808027668021268)", function()
		local flake = snowflake.new("1266808027668021268")

		local timestamp = flake:getTimestamp()
		check.equal(timestamp:toUnixTimestamp() * 1000, 1722100969951)

		check.equal(flake:getInternalWorkerId(), 2)
		check.equal(flake:getInternalProcessId(), 0)
		check.equal(flake:getIncrement(), 20)
	end)

	test.case("increment is always in range 0-4095", function()
		check.is_true(snowflake.new("175928847299117063"):getIncrement() <= 4095)
		check.is_true(snowflake.new("1266808027668021268"):getIncrement() <= 4095)
	end)

	test.case("worker ID and process ID are always in range 0-31", function()
		local flake = snowflake.new("175928847299117063")
		check.is_true(flake:getInternalWorkerId() <= 31)
		check.is_true(flake:getInternalProcessId() <= 31)
	end)
end
