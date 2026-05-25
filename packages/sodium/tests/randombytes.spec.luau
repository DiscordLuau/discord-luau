local frktest = require("../../../luau_packages/frktest")

local test = frktest.test
local check = frktest.assert.check

local ok, Sodium = pcall(require, "../src")

if not ok then
	return function() end
end

Sodium = Sodium :: any

return function()
	test.suite("randombytes", function()
		test.case("buf returns a buffer of the requested size", function()
			local b = Sodium.randombytes.buf(32)
			check.equal(buffer.len(b), 32)
		end)

		test.case("buf(0) returns an empty buffer", function()
			local b = Sodium.randombytes.buf(0)
			check.equal(buffer.len(b), 0)
		end)

		test.case("two calls to buf(32) almost certainly differ", function()
			local randomBytes1 = Sodium.randombytes.buf(32)
			local randomBytes2 = Sodium.randombytes.buf(32)
			local firstBytesString = buffer.readstring(randomBytes1, 0, 32)
			local secondBytesString = buffer.readstring(randomBytes2, 0, 32)
			-- probability of collision is 1/2^256
			check.not_equal(firstBytesString, secondBytesString)
		end)

		test.case("uniform returns a number in [0, upperBound)", function()
			for _ = 1, 20 do
				local sample = Sodium.randombytes.uniform(100)
				check.is_true(sample >= 0 and sample < 100)
			end
		end)

		test.case("uniform(1) always returns 0", function()
			for _ = 1, 5 do
				check.equal(Sodium.randombytes.uniform(1), 0)
			end
		end)
	end)
end
