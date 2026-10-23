local frktest = require("../../../luau_packages/frktest")
local logger = require("../luau_packages/logger")
local stdPolyfills = require("../luau_packages/std_polyfills")

local loader = require("../src/loader")
local registry = require("../src/registry")

local SCRATCH_DIRECTORY = "packages/commands/tests/loaderScratch"
local WAIT_SECONDS = 5
local POLL_SECONDS = 0.05

local test = frktest.test
local check = frktest.assert.check

local function waitUntil(predicate: () -> boolean): boolean
	local waited = 0

	while waited < WAIT_SECONDS do
		if predicate() then
			return true
		end

		stdPolyfills.task.wait(POLL_SECONDS)
		waited += POLL_SECONDS
	end

	return predicate()
end

local function hasLine(lines: { string }, needle: string): boolean
	for _, line in lines do
		if string.find(line, needle, 1, true) then
			return true
		end
	end

	return false
end

local function watchScratch(body: (lines: { string }) -> ())
	local lines: { string } = {}
	local log = logger.new("LoaderTest", "Warn")

	log:setSink(function(message)
		table.insert(lines, message)
	end)

	stdPolyfills.fileSystem.writeDir(SCRATCH_DIRECTORY)

	local instance = loader.new(registry.new(), log, nil)
	local stop = instance:watch(SCRATCH_DIRECTORY)
	local ran, failure = pcall(function()
		body(lines)
	end)

	stop()
	stdPolyfills.fileSystem.removeDir(SCRATCH_DIRECTORY)

	if not ran then
		error(failure, 0)
	end
end

return function()
	test.suite("commands loader watch", function()
		test.case("a new file that fails to require is warned about by name", function()
			watchScratch(function(lines)
				stdPolyfills.fileSystem.writeFile(`{SCRATCH_DIRECTORY}/broken.luau`, "this is not luau (")

				check.is_true(waitUntil(function()
					return hasLine(lines, "new file 'broken.luau'")
				end))
			end)
		end)

		test.case("a new file with the wrong shape is warned about", function()
			watchScratch(function(lines)
				stdPolyfills.fileSystem.writeFile(`{SCRATCH_DIRECTORY}/shapeless.luau`, "return { name = 'nothing' }")

				check.is_true(waitUntil(function()
					return hasLine(lines, "new file 'shapeless.luau'")
				end))
			end)
		end)

		test.case("a new file whose factory throws is warned about", function()
			watchScratch(function(lines)
				stdPolyfills.fileSystem.writeFile(
					`{SCRATCH_DIRECTORY}/thrower.luau`,
					"return function() error('factory failure') end"
				)

				check.is_true(waitUntil(function()
					return hasLine(lines, "new file 'thrower.luau'")
				end))
			end)
		end)
	end)
end
