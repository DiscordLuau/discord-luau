local frktest = require("../../../luau_packages/frktest")
local accumulator = require("../src")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("starts empty", function()
		local acc = accumulator.new()

		check.equal(acc:peek(), "")
		check.equal(acc:size(), 0)
	end)

	test.case("write appends data", function()
		local acc = accumulator.new()

		acc:write("hello")
		check.equal(acc:peek(), "hello")
		check.equal(acc:size(), 5)

		acc:write(" world")
		check.equal(acc:peek(), "hello world")
		check.equal(acc:size(), 11)
	end)

	test.case("peek does not clear accumulated data", function()
		local acc = accumulator.new()

		acc:write("data")
		local first = acc:peek()
		local second = acc:peek()

		check.equal(first, "data")
		check.equal(second, "data")
		check.equal(acc:size(), 4)
	end)

	test.case("flush returns all data and clears the accumulator", function()
		local acc = accumulator.new()

		acc:write("chunk1")
		acc:write("chunk2")

		local flushed = acc:flush()

		check.equal(flushed, "chunk1chunk2")
		check.equal(acc:peek(), "")
		check.equal(acc:size(), 0)
	end)

	test.case("write after flush accumulates fresh data", function()
		local acc = accumulator.new()

		acc:write("first")
		acc:flush()
		acc:write("second")

		check.equal(acc:peek(), "second")
		check.equal(acc:size(), 6)
	end)

	test.case("zlib framing pattern: write, peek to inspect, flush only on success", function()
		local acc = accumulator.new()

		acc:write("chunk1")
		acc:write("chunk2")

		local inspected = acc:peek()
		check.equal(inspected, "chunk1chunk2")

		local flushed = acc:flush()
		check.equal(flushed, inspected)
		check.equal(acc:size(), 0)
	end)
end
