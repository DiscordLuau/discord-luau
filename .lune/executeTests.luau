--[[
	This file is used to execute all unit tests found under the `tests` directory.
]]

local frktest = require("@frktest/frktest")
local reporter = require("@frktest/reporters/lune_console_reporter")

local requireTests = require("src/requireTests")

requireTests("tests")

reporter.init()

if not frktest.run() then
	print("--------------------")
	error(`See above for test failures.`, -1)
end
