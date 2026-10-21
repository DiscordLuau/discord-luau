local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Sodium = require("../src")
local helpers = require("./helpers")

local DATA = helpers.makeBuffer("hash test data")

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("hash", function() end)
	end
end

local bufferEqual = helpers.bufferEqual

return function()
	test.suite("hash", function()
		test.case("sha256 produces 32 bytes", function()
			local digest = Sodium.hash.sha256(DATA)

			check.equal(buffer.len(digest), Sodium.sys.hash.SHA256_BYTES)
			check.equal(Sodium.sys.hash.SHA256_BYTES, 32)
		end)

		test.case("sha512 produces 64 bytes", function()
			local digest = Sodium.hash.sha512(DATA)

			check.equal(buffer.len(digest), Sodium.sys.hash.SHA512_BYTES)
			check.equal(Sodium.sys.hash.SHA512_BYTES, 64)
		end)

		test.case("sha256 is deterministic", function()
			local digest1 = Sodium.hash.sha256(DATA)
			local digest2 = Sodium.hash.sha256(DATA)

			check.is_true(bufferEqual(digest1, digest2))
		end)

		test.case("sha512 is deterministic", function()
			local digest1 = Sodium.hash.sha512(DATA)
			local digest2 = Sodium.hash.sha512(DATA)

			check.is_true(bufferEqual(digest1, digest2))
		end)

		test.case("sha256 and sha512 differ on same input", function()
			local digest256 = Sodium.hash.sha256(DATA)
			local digest512 = Sodium.hash.sha512(DATA)

			check.not_equal(buffer.len(digest256), buffer.len(digest512))
		end)
	end)
end
