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

local PLAINTEXT = makeBuffer("hello sodium aead")
local AD = makeBuffer("additional data")

return function()
	test.suite("aes256gcm", function()
		test.case("isAvailable returns a boolean", function()
			local available = Sodium.aes256gcm.isAvailable()

			check.is_true(type(available) == "boolean")
		end)

		test.case("keygen produces KEY_BYTES bytes", function()
			local key = Sodium.aes256gcm.keygen()

			check.equal(buffer.len(key), Sodium.sys.aes256gcm.KEY_BYTES)
		end)

		test.case("encrypt/decrypt roundtrip without ad", function()
			if not Sodium.aes256gcm.isAvailable() then
				return
			end

			local key = Sodium.aes256gcm.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.aes256gcm.NONCE_BYTES)
			local encryptResult = Sodium.aes256gcm.encrypt(PLAINTEXT, key, nonce)

			check.equal(buffer.len(encryptResult.cipher), buffer.len(PLAINTEXT))
			check.equal(buffer.len(encryptResult.tag), Sodium.sys.aes256gcm.TAG_BYTES)

			local plain = Sodium.aes256gcm.decrypt(encryptResult.cipher, encryptResult.tag, key, nonce)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("encrypt/decrypt roundtrip with ad", function()
			if not Sodium.aes256gcm.isAvailable() then
				return
			end

			local key = Sodium.aes256gcm.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.aes256gcm.NONCE_BYTES)
			local encryptResult = Sodium.aes256gcm.encrypt(PLAINTEXT, key, nonce, AD)
			local plain = Sodium.aes256gcm.decrypt(encryptResult.cipher, encryptResult.tag, key, nonce, AD)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("decrypt fails with wrong tag", function()
			if not Sodium.aes256gcm.isAvailable() then
				return
			end

			local key = Sodium.aes256gcm.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.aes256gcm.NONCE_BYTES)
			local encryptResult = Sodium.aes256gcm.encrypt(PLAINTEXT, key, nonce)
			local badTag = Sodium.randombytes.buf(Sodium.sys.aes256gcm.TAG_BYTES)

			check.should_error(function()
				Sodium.aes256gcm.decrypt(encryptResult.cipher, badTag, key, nonce)

				return
			end)
		end)
	end)

	test.suite("chacha20poly1305", function()
		test.case("keygen produces KEY_BYTES bytes", function()
			local key = Sodium.chacha20poly1305.keygen()

			check.equal(buffer.len(key), Sodium.sys.chacha20poly1305.KEY_BYTES)
		end)

		test.case("encrypt/decrypt roundtrip without ad", function()
			local key = Sodium.chacha20poly1305.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.chacha20poly1305.NONCE_BYTES)
			local encryptResult = Sodium.chacha20poly1305.encrypt(PLAINTEXT, key, nonce)
			local plain = Sodium.chacha20poly1305.decrypt(encryptResult.cipher, encryptResult.tag, key, nonce)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("encrypt/decrypt roundtrip with ad", function()
			local key = Sodium.chacha20poly1305.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.chacha20poly1305.NONCE_BYTES)
			local encryptResult = Sodium.chacha20poly1305.encrypt(PLAINTEXT, key, nonce, AD)
			local plain = Sodium.chacha20poly1305.decrypt(encryptResult.cipher, encryptResult.tag, key, nonce, AD)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("decrypt fails with wrong key", function()
			local key1 = Sodium.chacha20poly1305.keygen()
			local key2 = Sodium.chacha20poly1305.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.chacha20poly1305.NONCE_BYTES)
			local encryptResult = Sodium.chacha20poly1305.encrypt(PLAINTEXT, key1, nonce)

			check.should_error(function()
				Sodium.chacha20poly1305.decrypt(encryptResult.cipher, encryptResult.tag, key2, nonce)

				return
			end)
		end)
	end)

	test.suite("xchacha20poly1305", function()
		test.case("keygen produces KEY_BYTES bytes", function()
			local key = Sodium.xchacha20poly1305.keygen()

			check.equal(buffer.len(key), Sodium.sys.xchacha20poly1305.KEY_BYTES)
		end)

		test.case("nonce is NONCE_BYTES long (24 bytes)", function()
			check.equal(Sodium.sys.xchacha20poly1305.NONCE_BYTES, 24)
		end)

		test.case("encrypt/decrypt roundtrip without ad", function()
			local key = Sodium.xchacha20poly1305.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.xchacha20poly1305.NONCE_BYTES)
			local encryptResult = Sodium.xchacha20poly1305.encrypt(PLAINTEXT, key, nonce)
			local plain = Sodium.xchacha20poly1305.decrypt(encryptResult.cipher, encryptResult.tag, key, nonce)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("encrypt/decrypt roundtrip with ad", function()
			local key = Sodium.xchacha20poly1305.keygen()
			local nonce = Sodium.randombytes.buf(Sodium.sys.xchacha20poly1305.NONCE_BYTES)
			local encryptResult = Sodium.xchacha20poly1305.encrypt(PLAINTEXT, key, nonce, AD)
			local plain = Sodium.xchacha20poly1305.decrypt(encryptResult.cipher, encryptResult.tag, key, nonce, AD)

			check.is_true(bufferEqual(plain, PLAINTEXT))
		end)

		test.case("decrypt fails with wrong nonce", function()
			local key = Sodium.xchacha20poly1305.keygen()
			local nonce1 = Sodium.randombytes.buf(Sodium.sys.xchacha20poly1305.NONCE_BYTES)
			local nonce2 = Sodium.randombytes.buf(Sodium.sys.xchacha20poly1305.NONCE_BYTES)
			local encryptResult = Sodium.xchacha20poly1305.encrypt(PLAINTEXT, key, nonce1)

			check.should_error(function()
				Sodium.xchacha20poly1305.decrypt(encryptResult.cipher, encryptResult.tag, key, nonce2)

				return
			end)
		end)
	end)
end
