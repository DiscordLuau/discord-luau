local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Sodium = require("../src")
local helpers = require("./helpers")

local MESSAGE = helpers.makeBuffer("auth test message")

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("auth", function() end)
	end
end

local makeBuffer = helpers.makeBuffer

return function()
	test.suite("auth", function()
		test.case("keygen produces KEY_BYTES bytes", function()
			local key = Sodium.auth.keygen()

			check.equal(buffer.len(key), Sodium.sys.auth.KEY_BYTES)
		end)

		test.case("sign produces BYTES bytes", function()
			local key = Sodium.auth.keygen()
			local mac = Sodium.auth.sign(MESSAGE, key)

			check.equal(buffer.len(mac), Sodium.sys.auth.BYTES)
		end)

		test.case("verify accepts a valid MAC", function()
			local key = Sodium.auth.keygen()
			local mac = Sodium.auth.sign(MESSAGE, key)

			check.is_true(Sodium.auth.verify(mac, MESSAGE, key))
		end)

		test.case("verify rejects a wrong key", function()
			local key1 = Sodium.auth.keygen()
			local key2 = Sodium.auth.keygen()
			local mac = Sodium.auth.sign(MESSAGE, key1)

			check.is_false(Sodium.auth.verify(mac, MESSAGE, key2))
		end)

		test.case("verify rejects a tampered message", function()
			local key = Sodium.auth.keygen()
			local mac = Sodium.auth.sign(MESSAGE, key)
			local tampered = makeBuffer("auth test messagX")

			check.is_false(Sodium.auth.verify(mac, tampered, key))
		end)
	end)
end
