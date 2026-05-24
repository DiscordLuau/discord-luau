local frktest = require("../../../luau_packages/frktest")
local Sodium = require("../src")
local helpers = require("./helpers")

local test = frktest.test
local check = frktest.assert.check
local makeBuffer = helpers.makeBuffer
local bufferEqual = helpers.bufferEqual

return function()
	test.suite("utils", function()
		test.case("memcmp returns true for equal buffers", function()
			local bufferA = makeBuffer("hello")
			local bufferB = makeBuffer("hello")
			check.is_true(Sodium.utils.memcmp(bufferA, bufferB))
		end)

		test.case("memcmp returns false for different buffers of same length", function()
			local bufferA = makeBuffer("hello")
			local bufferB = makeBuffer("world")
			check.is_false(Sodium.utils.memcmp(bufferA, bufferB))
		end)

		test.case("memcmp errors on different-length buffers", function()
			local bufferA = makeBuffer("hi")
			local bufferB = makeBuffer("hello")
			check.should_error(function()
				Sodium.utils.memcmp(bufferA, bufferB)
				return
			end)
		end)

		test.case("bin2hex produces lowercase hex string", function()
			local data = makeBuffer("\0\255\171")
			local hex = Sodium.utils.bin2hex(data)
			check.equal(hex, "00ffab")
		end)

		test.case("hex2bin roundtrips bin2hex", function()
			local data = Sodium.randombytes.buf(16)
			local hex = Sodium.utils.bin2hex(data)
			local back = Sodium.utils.hex2bin(hex)
			check.is_true(bufferEqual(data, back))
		end)

		test.case("hex2bin produces correct byte length", function()
			local hex = "deadbeef"
			local data = Sodium.utils.hex2bin(hex)
			check.equal(buffer.len(data), 4)
		end)

		test.case("bin2base64 roundtrips base642bin (original variant)", function()
			local data = Sodium.randombytes.buf(32)
			local encoded = Sodium.utils.bin2base64(data, Sodium.sys.base64.VARIANT_ORIGINAL)
			local back = Sodium.utils.base642bin(encoded, Sodium.sys.base64.VARIANT_ORIGINAL)
			check.is_true(bufferEqual(data, back))
		end)

		test.case("bin2base64 roundtrips base642bin (urlsafe no-padding variant)", function()
			local data = Sodium.randombytes.buf(32)
			local encoded = Sodium.utils.bin2base64(data, Sodium.sys.base64.VARIANT_URLSAFE_NO_PADDING)
			local back = Sodium.utils.base642bin(encoded, Sodium.sys.base64.VARIANT_URLSAFE_NO_PADDING)
			check.is_true(bufferEqual(data, back))
		end)

		test.case("bin2base64 defaults to original variant", function()
			local data = Sodium.randombytes.buf(16)
			local explicit = Sodium.utils.bin2base64(data, Sodium.sys.base64.VARIANT_ORIGINAL)
			local default = Sodium.utils.bin2base64(data)
			check.equal(explicit, default)
		end)
	end)
end
