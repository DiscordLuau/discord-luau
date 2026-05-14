local frktest = require("../../../luau_packages/frktest")
local utilities = require("../src")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.suite("validateKebabCase", function()
		test.case("accepts a single lowercase word", function()
			check.is_true(utilities.validateKebabCase("hello"))
		end)

		test.case("accepts multiple words joined by hyphens", function()
			check.is_true(utilities.validateKebabCase("hello-world"))
			check.is_true(utilities.validateKebabCase("one-two-three"))
		end)

		test.case("accepts words containing digits", function()
			check.is_true(utilities.validateKebabCase("abc-123"))
			check.is_true(utilities.validateKebabCase("v2-endpoint"))
		end)

		test.case("rejects an empty string", function()
			check.is_false(utilities.validateKebabCase(""))
		end)

		test.case("rejects a leading hyphen", function()
			check.is_false(utilities.validateKebabCase("-hello"))
		end)

		test.case("rejects a trailing hyphen", function()
			check.is_false(utilities.validateKebabCase("hello-"))
		end)

		test.case("rejects consecutive hyphens", function()
			check.is_false(utilities.validateKebabCase("hello--world"))
		end)

		test.case("rejects uppercase letters", function()
			check.is_false(utilities.validateKebabCase("Hello"))
			check.is_false(utilities.validateKebabCase("hello-World"))
		end)

		test.case("rejects spaces", function()
			check.is_false(utilities.validateKebabCase("hello world"))
		end)

		test.case("rejects underscores", function()
			check.is_false(utilities.validateKebabCase("hello_world"))
		end)
	end)

	test.suite("validateCommandName", function()
		test.case("accepts a lowercase word", function()
			check.is_true(utilities.validateCommandName("ping"))
		end)

		test.case("accepts hyphens, underscores, and apostrophes", function()
			check.is_true(utilities.validateCommandName("my-command"))
			check.is_true(utilities.validateCommandName("my_command"))
			check.is_true(utilities.validateCommandName("can't"))
		end)

		test.case("accepts a 32-character name", function()
			check.is_true(utilities.validateCommandName(string.rep("a", 32)))
		end)

		test.case("rejects an empty string", function()
			check.is_false(utilities.validateCommandName(""))
		end)

		test.case("rejects a name longer than 32 characters", function()
			check.is_false(utilities.validateCommandName(string.rep("a", 33)))
		end)

		test.case("rejects uppercase letters", function()
			check.is_false(utilities.validateCommandName("Ping"))
		end)

		test.case("rejects spaces", function()
			check.is_false(utilities.validateCommandName("my command"))
		end)
	end)

	test.suite("createGuid", function()
		test.case("returns a string", function()
			check.is_true(type(utilities.createGuid()) == "string")
		end)

		test.case("matches the UUID v4 format", function()
			local guid = utilities.createGuid()

			check.is_true(string.match(guid, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil)
		end)

		test.case("the version nibble is always 4", function()
			for _ = 1, 20 do
				local guid = utilities.createGuid()

				check.equal(string.sub(guid, 15, 15), "4")
			end
		end)

		test.case("the variant nibble is always 8, 9, a, or b", function()
			for _ = 1, 20 do
				local guid = utilities.createGuid()
				local variantNibble = string.sub(guid, 20, 20)

				check.is_true(
					variantNibble == "8"
					or variantNibble == "9"
					or variantNibble == "a"
					or variantNibble == "b"
				)
			end
		end)

		test.case("successive calls return distinct values", function()
			local guids: { [string]: boolean } = {}

			for _ = 1, 50 do
				local guid = utilities.createGuid()

				check.is_false(guids[guid] == true)

				guids[guid] = true
			end
		end)
	end)

	test.suite("tableReflect", function()
		test.case("preserves original key-value pairs", function()
			local reflected = utilities.tableReflect({ a = 1, b = 2 })

			check.equal(reflected["a"], 1)
			check.equal(reflected["b"], 2)
		end)

		test.case("adds reversed value-to-key pairs", function()
			local reflected = utilities.tableReflect({ a = 1, b = 2 })

			check.equal(reflected[1], "a")
			check.equal(reflected[2], "b")
		end)

		test.case("works with numeric keys", function()
			local reflected = utilities.tableReflect({ [10] = "ten", [20] = "twenty" })

			check.equal(reflected[10], "ten")
			check.equal(reflected["ten"], 10)
		end)

		test.case("returns an empty table for an empty source", function()
			local reflected = utilities.tableReflect({})
			local count = 0

			for _ in reflected do
				count += 1
			end

			check.equal(count, 0)
		end)

		test.case("does not mutate the source table", function()
			local source = { x = 1 }
			utilities.tableReflect(source)

			check.equal(source[1], nil)
		end)
	end)

	test.suite("coroutineRun", function()
		test.case("returns the spawned thread", function()
			local thread = utilities.coroutineRun(function() end)

			check.is_true(type(thread) == "thread")
		end)

		test.case("executes the callback immediately", function()
			local executed = false

			utilities.coroutineRun(function()
				executed = true
			end)

			check.is_true(executed)
		end)

		test.case("forwards arguments to the callback", function()
			local received: { any } = {}

			utilities.coroutineRun(function(a, b, c)
				received = { a, b, c }
			end, 1, "two", true)

			check.equal(received[1], 1)
			check.equal(received[2], "two")
			check.equal(received[3], true)
		end)

		test.case("re-raises errors from the callback", function()
			check.should_error(function()
				utilities.coroutineRun(function()
					error("inner error")
				end)

				return
			end)
		end)

		test.case("thread is alive after yielding", function()
			local thread = utilities.coroutineRun(function()
				coroutine.yield()
			end)

			check.equal(coroutine.status(thread), "suspended")
		end)
	end)
end
