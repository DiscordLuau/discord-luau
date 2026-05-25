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

local MESSAGE = makeBuffer("sign test message")

return function()
	test.suite("sign", function()
		test.case("keypair produces correct key sizes", function()
			local keyPair = Sodium.sign.keypair()
			check.equal(buffer.len(keyPair.publicKey), Sodium.sys.sign.PUBLIC_KEY_BYTES)
			check.equal(buffer.len(keyPair.secretKey), Sodium.sys.sign.SECRET_KEY_BYTES)
		end)

		test.case("sign produces BYTES bytes", function()
			local keyPair = Sodium.sign.keypair()
			local sig = Sodium.sign.sign(MESSAGE, keyPair.secretKey)
			check.equal(buffer.len(sig), Sodium.sys.sign.BYTES)
		end)

		test.case("verify accepts a valid signature", function()
			local keyPair = Sodium.sign.keypair()
			local sig = Sodium.sign.sign(MESSAGE, keyPair.secretKey)
			check.is_true(Sodium.sign.verify(sig, MESSAGE, keyPair.publicKey))
		end)

		test.case("verify rejects a wrong public key", function()
			local keyPair1 = Sodium.sign.keypair()
			local keyPair2 = Sodium.sign.keypair()
			local sig = Sodium.sign.sign(MESSAGE, keyPair1.secretKey)
			check.is_false(Sodium.sign.verify(sig, MESSAGE, keyPair2.publicKey))
		end)

		test.case("verify rejects a tampered message", function()
			local keyPair = Sodium.sign.keypair()
			local sig = Sodium.sign.sign(MESSAGE, keyPair.secretKey)
			local tampered = makeBuffer("sign test messagX")
			check.is_false(Sodium.sign.verify(sig, tampered, keyPair.publicKey))
		end)

		test.case("secretKeyToPublicKey recovers the public key", function()
			local keyPair = Sodium.sign.keypair()
			local recoveredPublicKey = Sodium.sign.secretKeyToPublicKey(keyPair.secretKey)
			check.is_true(bufferEqual(keyPair.publicKey, recoveredPublicKey))
		end)
	end)
end
