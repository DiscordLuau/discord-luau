local stream = require("../src")
local frktest = require("../../../lune_packages/frktest")

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
end
