local stream = require("../src")
local frktest = require("../../../luau_packages/frktest")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("is able to construct an stream object", function()
		local object = stream.new("example")

		check.not_nil(object)
		check.equal(object.textSource, "example")
	end)

	test.suite("advancing an stream object", function()
		test.case("advancing in a stream respects order", function()
			local object = stream.new("abcdef")

			check.equal(object:advance(2), "ab")
			check.equal(object:advance(2), "cd")
			check.equal(object:advance(2), "ef")
		end)

		test.case("is able to advance an stream object", function()
			local object = stream.new("example")

			check.equal(object.cursorPosition, 0)

			local char = object:advance()

			check.equal(char, "e")
			check.equal(object.cursorPosition, 1)

			object:advance(2)

			check.equal(object.cursorPosition, 3)
		end)

		test.case("is able to advance multiple characters", function()
			local object = stream.new("example")

			check.equal(object.cursorPosition, 0)

			local response = object:advanceUntil(function(char)
				return char == "a"
			end)

			check.equal(response, "exa")
			check.equal(object.cursorPosition, 3)

			object:advance(2)

			check.equal(object.cursorPosition, 5)
		end)
	end)

	test.case("is able to peek an stream object", function()
		local object = stream.new("example")

		local char = object:peek()

		check.equal(char, "e")
		check.equal(object.cursorPosition, 0)
	end)

	test.suite("advance edge cases", function()
		test.case("returns nil for a negative length", function()
			local object = stream.new("hello")

			check.equal(object:advance(-1), nil)
			check.equal(object.cursorPosition, 0)
		end)

		test.case("returns nil when advancing past the end", function()
			local object = stream.new("hi")

			check.equal(object:advance(3), nil)
			check.equal(object.cursorPosition, 0)
		end)

		test.case("returns nil when already at the end", function()
			local object = stream.new("hi")

			object:advance(2)

			check.equal(object:advance(), nil)
		end)

		test.case("consuming exactly to the end succeeds", function()
			local object = stream.new("abc")

			check.equal(object:advance(3), "abc")
			check.equal(object.cursorPosition, 3)
		end)
	end)

	test.suite("rewind", function()
		test.case("moves the cursor back by one by default", function()
			local object = stream.new("hello")

			object:advance(3)
			object:rewind()

			check.equal(object.cursorPosition, 2)
		end)

		test.case("moves the cursor back by the given amount", function()
			local object = stream.new("hello")

			object:advance(5)
			object:rewind(3)

			check.equal(object.cursorPosition, 2)
		end)

		test.case("clamps to zero rather than going negative", function()
			local object = stream.new("hello")

			object:advance(2)
			object:rewind(10)

			check.equal(object.cursorPosition, 0)
		end)

		test.case("rewind then advance re-reads the same characters", function()
			local object = stream.new("abcdef")

			check.equal(object:advance(3), "abc")
			object:rewind(3)
			check.equal(object:advance(3), "abc")
		end)
	end)

	test.suite("advanceUntil edge cases", function()
		test.case("returns nil when cursor is already at the end", function()
			local object = stream.new("hi")

			object:advance(2)

			check.equal(object:advanceUntil(function(_char)
				return true
			end), nil)
		end)

		test.case("returns nil and advances to end when predicate never matches", function()
			local object = stream.new("abc")

			local result = object:advanceUntil(function(_char)
				return false
			end)

			check.equal(result, nil)
			check.equal(object.cursorPosition, 3)
		end)

		test.case("matches on the very first character", function()
			local object = stream.new("abc")

			local result = object:advanceUntil(function(char)
				return char == "a"
			end)

			check.equal(result, "a")
			check.equal(object.cursorPosition, 1)
		end)
	end)

	test.suite("readUntilEnd", function()
		test.case("returns the entire string when cursor is at the start", function()
			local object = stream.new("hello")

			check.equal(object:readUntilEnd(), "hello")
		end)

		test.case("returns only the remaining text after a partial advance", function()
			local object = stream.new("hello world")

			object:advance(6)

			check.equal(object:readUntilEnd(), "world")
		end)

		test.case("advances the cursor to the end", function()
			local object = stream.new("hello")

			object:readUntilEnd()

			check.equal(object.cursorPosition, 5)
		end)

		test.case("returns an empty string when already at the end", function()
			local object = stream.new("hi")

			object:advance(2)

			check.equal(object:readUntilEnd(), "")
		end)

		test.case("successive calls return empty string", function()
			local object = stream.new("abc")

			object:readUntilEnd()

			check.equal(object:readUntilEnd(), "")
		end)
	end)

	test.suite("trim", function()
		test.case("skips leading spaces", function()
			local object = stream.new("   hello")

			object:trim()

			check.equal(object:advance(5), "hello")
		end)

		test.case("is a no-op when there is no leading whitespace", function()
			local object = stream.new("hello")

			object:trim()

			check.equal(object.cursorPosition, 0)
		end)

		test.case("does not consume non-whitespace after the whitespace", function()
			local object = stream.new("  abc")

			object:trim()

			check.equal(object:peek(), "a")
		end)
	end)
end
