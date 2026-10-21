local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Sodium = require("../src")

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("randombytes", function() end)
	end
end

return function()
	test.suite("randombytes", function()
		test.case("buf returns a buffer of the requested size", function()
			local bytes = Sodium.randombytes.buf(32)
			check.equal(buffer.len(bytes), 32)
		end)

		test.case("buf(0) returns an empty buffer", function()
			local bytes = Sodium.randombytes.buf(0)
			check.equal(buffer.len(bytes), 0)
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
