--> Task for running unit-tests using frktest

local frktest = require("../lune_packages/frktest")
local reporter = frktest._reporters.lune_console_reporter

local requireTests = require("./task/requireTests")

requireTests("./packages")

reporter.init()

if not frktest.run() then
	print("--------------------")
	error(`See above for test failures.`, -1)
end
