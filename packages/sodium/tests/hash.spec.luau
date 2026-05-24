local frktest = require("../../../luau_packages/frktest")
local helpers = require("./helpers")

local test = frktest.test
local check = frktest.assert.check

local ok, Sodium = pcall(require, "../src")

if not ok then
	return function() end
end

Sodium = Sodium :: any
local makeBuffer = helpers.makeBuffer
local bufferEqual = helpers.bufferEqual

local DATA = makeBuffer("hash test data")

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
