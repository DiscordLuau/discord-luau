local frktest = require("../../../luau_packages/frktest")
local dave = require("../luau_packages/dave")
local opus = require("../luau_packages/opus")
local sodium = require("../luau_packages/sodium")
local stdPolyfills = require("../luau_packages/std_polyfills")

local SELF_USER_ID = "1111111111111111111"
local KEY_SIZE = 32
local NONCE_SIZE = 24

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Native pointers across packages", function() end)
	end
end

return function()
	test.suite("Native pointers across packages", function()
		test.case("a NULL from libdave leaves sodium and opus working", function()
			local session = dave.Session.new("", nil)

			check.equal(session:getKeyRatchet(SELF_USER_ID), nil)

			local key = buffer.create(KEY_SIZE)
			local nonce = buffer.create(NONCE_SIZE)
			local sealed = sodium.xchacha20poly1305.encrypt(buffer.fromstring("voice"), key, nonce)
			local opened = sodium.xchacha20poly1305.decrypt(sealed.cipher, sealed.tag, key, nonce)
			local decoder = opus.decoder.new(opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)
			local concealed = decoder:decodePLC()

			check.equal(buffer.tostring(opened), "voice")
			check.is_true(buffer.len(concealed) > 0)

			decoder:destroy()
			session:destroy()
		end)
	end)
end
