local frktest = require("../luau_packages/frktest")
local reporter = frktest.reporters.console_reporter

local requireTests = require("./task/requireTests")

requireTests("./packages")

reporter.init()

if not frktest.run() then
	print("--------------------")
	error(`See above for test failures.`, -1)
end
