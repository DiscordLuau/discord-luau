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

local PLAINTEXT = makeBuffer("secretbox test message")

return function()
	test.suite("secretbox", function()
		test.case("keygen produces KEY_BYTES bytes", function()
			local key = Sodium.secretbox.keygen()
			check.equal(buffer.len(key), Sodium.sys.secretbox.KEY_BYTES)
		end)

		test.case("nonce produces NONCE_BYTES bytes", function()
			local nonce = Sodium.secretbox.nonce()
			check.equal(buffer.len(nonce), Sodium.sys.secretbox.NONCE_BYTES)
		end)

		test.case("combined seal/open roundtrip", function()
			local key = Sodium.secretbox.keygen()
			local nonce = Sodium.secretbox.nonce()
			local sealed = Sodium.secretbox.seal(PLAINTEXT, key, nonce)
			check.equal(buffer.len(sealed), Sodium.sys.secretbox.MAC_BYTES + buffer.len(PLAINTEXT))
			local plain = Sodium.secretbox.open(sealed, key, nonce)
			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("open fails with wrong key", function()
			local key1 = Sodium.secretbox.keygen()
			local key2 = Sodium.secretbox.keygen()
			local nonce = Sodium.secretbox.nonce()
			local sealed = Sodium.secretbox.seal(PLAINTEXT, key1, nonce)
			check.should_error(function()
				Sodium.secretbox.open(sealed, key2, nonce)
				return
			end)
		end)

		test.case("open rejects truncated ciphertext", function()
			local tiny = buffer.create(Sodium.sys.secretbox.MAC_BYTES - 1)
			check.should_error(function()
				Sodium.secretbox.open(tiny, Sodium.secretbox.keygen(), Sodium.secretbox.nonce())
				return
			end)
		end)

		test.case("detached sealDetached/openDetached roundtrip", function()
			local key = Sodium.secretbox.keygen()
			local nonce = Sodium.secretbox.nonce()
			local sealResult = Sodium.secretbox.sealDetached(PLAINTEXT, key, nonce)
			check.equal(buffer.len(sealResult.cipher), buffer.len(PLAINTEXT))
			check.equal(buffer.len(sealResult.mac), Sodium.sys.secretbox.MAC_BYTES)
			local plain = Sodium.secretbox.openDetached(sealResult.cipher, sealResult.mac, key, nonce)
			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("openDetached fails with corrupted mac", function()
			local key = Sodium.secretbox.keygen()
			local nonce = Sodium.secretbox.nonce()
			local sealResult = Sodium.secretbox.sealDetached(PLAINTEXT, key, nonce)
			local badMac = Sodium.randombytes.buf(Sodium.sys.secretbox.MAC_BYTES)
			check.should_error(function()
				Sodium.secretbox.openDetached(sealResult.cipher, badMac, key, nonce)
				return
			end)
		end)
	end)
end
