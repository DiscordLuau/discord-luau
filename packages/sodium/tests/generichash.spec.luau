local frktest = require("../../../luau_packages/frktest")
local Sodium = require("../src")
local helpers = require("./helpers")

local test = frktest.test
local check = frktest.assert.check
local makeBuffer = helpers.makeBuffer
local bufferEqual = helpers.bufferEqual

local DATA = makeBuffer("generichash test data")
local CHUNK1 = makeBuffer("chunk one ")
local CHUNK2 = makeBuffer("chunk two")

return function()
	test.suite("generichash", function()
		test.case("one-shot hash defaults to BYTES output", function()
			local digest = Sodium.generichash.hash(DATA)

			check.equal(buffer.len(digest), Sodium.sys.generichash.BYTES)
		end)

		test.case("one-shot hash with custom output length", function()
			local digest = Sodium.generichash.hash(DATA, 64)

			check.equal(buffer.len(digest), 64)
		end)

		test.case("one-shot hash is deterministic", function()
			local digest1 = Sodium.generichash.hash(DATA)
			local digest2 = Sodium.generichash.hash(DATA)

			check.is_true(bufferEqual(digest1, digest2))
		end)

		test.case("keyed hash differs from unkeyed hash", function()
			local key = Sodium.randombytes.buf(Sodium.sys.generichash.KEY_BYTES)
			local keyed = Sodium.generichash.hash(DATA, nil, key)
			local plain = Sodium.generichash.hash(DATA)

			check.is_false(bufferEqual(keyed, plain))
		end)

		test.case("streaming hash matches one-shot on same data", function()
			local combined = makeBuffer(
				buffer.readstring(CHUNK1, 0, buffer.len(CHUNK1)) .. buffer.readstring(CHUNK2, 0, buffer.len(CHUNK2))
			)

			local oneShot = Sodium.generichash.hash(combined)
			local state = Sodium.generichash.new()

			state:update(CHUNK1)
			state:update(CHUNK2)

			local streamed = state:final()

			check.is_true(bufferEqual(oneShot, streamed))
		end)

		test.case("State:final errors if called twice", function()
			local state = Sodium.generichash.new()

			state:update(DATA)
			state:final()

			check.should_error(function()
				state:final()

				return
			end)
		end)
	end)
end
