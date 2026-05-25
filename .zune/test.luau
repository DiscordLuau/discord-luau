local frktest = require("../luau_packages/frktest")
local reporter = frktest.reporters.console_reporter

local requireTests = require("./task/requireTests")

requireTests("./packages")

reporter.init()

local testModule = frktest.test

local suiteName = ""
local suitePassed = 0
local suiteFailed = 0
local suiteSkipped = 0

local GREEN = "\27[32m"
local RED = "\27[31m"
local YELLOW = "\27[33m"
local RESET = "\27[0m"

testModule.on_suite_enter(function(s)
	suiteName = s.name
	suitePassed = 0
	suiteFailed = 0
	suiteSkipped = 0
end)

testModule.on_test_leave(function(t)
	if t.failed then
		suiteFailed += 1
	else
		suitePassed += 1
	end
end)

testModule.on_test_skipped(function(_)
	suiteSkipped += 1
end)

testModule.on_suite_leave(function(_)
	local parts = {}
	if suiteFailed > 0 then
		table.insert(parts, `{suiteFailed} failed`)
	end
	if suitePassed > 0 then
		table.insert(parts, `{suitePassed} passed`)
	end
	if suiteSkipped > 0 then
		table.insert(parts, `{YELLOW}{suiteSkipped} skipped{RESET}`)
	end
	local counts = if #parts > 0 then `({table.concat(parts, ", ")})` else ""
	if suiteFailed > 0 then
		print(`{RED}✗{RESET} {suiteName} {counts}`)
	else
		print(`{GREEN}✓{RESET} {suiteName} {counts}`)
	end
end)

if not frktest.run() then
	print("--------------------")
	error(`See above for test failures.`, -1)
end
