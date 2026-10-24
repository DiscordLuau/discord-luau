local frktest = require("../luau_packages/frktest")

local requireTests = require("./task/requireTests")

local SUMMARY_PATH_VARIABLE = "DISCORD_LUAU_TEST_SUMMARY_PATH"
local GREEN = "\27[32m"
local RED = "\27[31m"
local YELLOW = "\27[33m"
local RESET = "\27[0m"

local reporter = frktest.reporters.console_reporter
local testModule = frktest.test
local summaryPath = zune.process.env[SUMMARY_PATH_VARIABLE]
local testFolder = string.gsub(zune.process.args[2] or "./packages", "/+$", "")
local suiteName = ""
local suitePassed = 0
local suiteFailed = 0
local suiteSkipped = 0
local announcedTests = 0

--[=[
	Runs this script again as a child that writes its test counts to a summary file once frktest prints its summary,
	then fails when the child ended without one or ran fewer tests than it announced. Zune exits 0 once every thread is
	blocked, so a test that is never resumed would otherwise end the run green with the tests after it unrun.
]=]
local function superviseRun()
	local temporaryFolder = zune.process.env.TEMP or zune.process.env.TMPDIR or "/tmp"
	local childSummaryPath = `{temporaryFolder}/discord-luau-test-summary-{zune.process.pid()}.json`
	local environment = table.clone(zune.process.env)

	environment[SUMMARY_PATH_VARIABLE] = childSummaryPath

	if zune.fs.stat(childSummaryPath).kind ~= "none" then
		zune.fs.deleteFile(childSummaryPath)
	end

	local result = zune.process.run(zune.fs.getExePath(), { "run", table.unpack(zune.process.args) }, {
		env = environment,
		stdout = "inherit",
		stderr = "inherit",
	})
	local failureCode = if result.ok then 1 else result.code

	if zune.fs.stat(childSummaryPath).kind == "none" then
		print(
			`\n{RED}The test run ended without its summary (exit code {result.code}): a test never finished or stopped the process, so the tests after it never ran.{RESET}`
		)
		zune.process.exit(failureCode)
	end

	local summary = zune.serde.json.decode(zune.fs.readFileSync(childSummaryPath))

	zune.fs.deleteFile(childSummaryPath)

	if summary.ran + summary.skipped < summary.announced then
		print(
			`\n{RED}{summary.announced} tests were announced, but only {summary.ran} ran and {summary.skipped} were skipped.{RESET}`
		)
		zune.process.exit(failureCode)
	end

	zune.process.exit(result.code)
end

if not summaryPath then
	superviseRun()
end

if string.sub(testFolder, 1, 2) ~= "./" then
	testFolder = `./{testFolder}`
end

requireTests(testFolder)

reporter.init()

testModule.on_suite_enter(function(suite)
	suiteName = suite.name
	suitePassed = 0
	suiteFailed = 0
	suiteSkipped = 0
end)

testModule.on_test_leave(function(testCase)
	if testCase.failed then
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

testModule.on_exec_begin(function(counts)
	announcedTests = counts.tests
end)

testModule.on_exec_end(function(result)
	zune.fs.writeFileSync(
		summaryPath,
		zune.serde.json.encode({ announced = announcedTests, ran = result.ran, skipped = result.skipped })
	)
end)

if not frktest.run() then
	print("--------------------")
	error(`See above for test failures.`, -1)
end
