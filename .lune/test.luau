--> Task for running unit-tests using frktest

local frktest = require("@frktest/frktest")
local reporter = require("@frktest/reporters/lune_console_reporter")

local requireTests = require("task/requireTests")

requireTests("tests")

reporter.init()

if not frktest.run() then
	print("--------------------")
	error(`See above for test failures.`, -1)
end
