local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Sodium = require("../src")
local helpers = require("./helpers")

local PLAINTEXT = helpers.makeBuffer("box test message")

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("box", function() end)
	end
end

local bufferEqual = helpers.bufferEqual

return function()
	test.suite("box", function()
		test.case("keypair produces correct key sizes", function()
			local keyPair = Sodium.box.keypair()

			check.equal(buffer.len(keyPair.publicKey), Sodium.sys.box.PUBLIC_KEY_BYTES)
			check.equal(buffer.len(keyPair.secretKey), Sodium.sys.box.SECRET_KEY_BYTES)
		end)

		test.case("nonce produces NONCE_BYTES bytes", function()
			local nonce = Sodium.box.nonce()

			check.equal(buffer.len(nonce), Sodium.sys.box.NONCE_BYTES)
		end)

		test.case("combined seal/open roundtrip", function()
			local sender = Sodium.box.keypair()
			local recipient = Sodium.box.keypair()
			local nonce = Sodium.box.nonce()
			local sealed = Sodium.box.seal(PLAINTEXT, recipient.publicKey, sender.secretKey, nonce)

			check.equal(buffer.len(sealed), Sodium.sys.box.MAC_BYTES + buffer.len(PLAINTEXT))

			local plain = Sodium.box.open(sealed, sender.publicKey, recipient.secretKey, nonce)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("open rejects truncated ciphertext", function()
			local tiny = buffer.create(Sodium.sys.box.MAC_BYTES - 1)
			local keyPair = Sodium.box.keypair()

			check.should_error(function()
				Sodium.box.open(tiny, keyPair.publicKey, keyPair.secretKey, Sodium.box.nonce())

				return
			end)
		end)

		test.case("open fails with wrong recipient key", function()
			local sender = Sodium.box.keypair()
			local recipient1 = Sodium.box.keypair()
			local recipient2 = Sodium.box.keypair()
			local nonce = Sodium.box.nonce()
			local sealed = Sodium.box.seal(PLAINTEXT, recipient1.publicKey, sender.secretKey, nonce)

			check.should_error(function()
				Sodium.box.open(sealed, sender.publicKey, recipient2.secretKey, nonce)

				return
			end)
		end)

		test.case("detached sealDetached/openDetached roundtrip", function()
			local sender = Sodium.box.keypair()
			local recipient = Sodium.box.keypair()
			local nonce = Sodium.box.nonce()
			local sealResult = Sodium.box.sealDetached(PLAINTEXT, recipient.publicKey, sender.secretKey, nonce)

			check.equal(buffer.len(sealResult.cipher), buffer.len(PLAINTEXT))
			check.equal(buffer.len(sealResult.mac), Sodium.sys.box.MAC_BYTES)

			local plain =
				Sodium.box.openDetached(sealResult.cipher, sealResult.mac, sender.publicKey, recipient.secretKey, nonce)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("precompute + sealAfterPrecompute/openAfterPrecompute roundtrip", function()
			local sender = Sodium.box.keypair()
			local recipient = Sodium.box.keypair()
			local nonce = Sodium.box.nonce()
			local shared = Sodium.box.precompute(recipient.publicKey, sender.secretKey)

			check.equal(buffer.len(shared), Sodium.sys.box.BEFORENM_BYTES)

			local sealed = Sodium.box.sealAfterPrecompute(PLAINTEXT, shared, nonce)
			local plain = Sodium.box.openAfterPrecompute(sealed, shared, nonce)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("openAfterPrecompute rejects truncated ciphertext", function()
			local keyPair = Sodium.box.keypair()
			local shared = Sodium.box.precompute(keyPair.publicKey, keyPair.secretKey)
			local tiny = buffer.create(Sodium.sys.box.MAC_BYTES - 1)

			check.should_error(function()
				Sodium.box.openAfterPrecompute(tiny, shared, Sodium.box.nonce())

				return
			end)
		end)
	end)
end
