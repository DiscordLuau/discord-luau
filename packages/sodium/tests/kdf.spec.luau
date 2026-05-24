local frktest = require("../../../luau_packages/frktest")
local helpers = require("./helpers")

local test = frktest.test
local check = frktest.assert.check

local ok, Sodium = pcall(require, "../src")

if not ok then
	return function() end
end

Sodium = Sodium :: any
local bufferEqual = helpers.bufferEqual

return function()
	test.suite("kdf", function()
		test.case("keygen produces KEY_BYTES bytes", function()
			local key = Sodium.kdf.keygen()
			check.equal(buffer.len(key), Sodium.sys.kdf.KEY_BYTES)
		end)

		test.case("deriveKey produces requested output length", function()
			local master = Sodium.kdf.keygen()
			local subkey = Sodium.kdf.deriveKey(master, 1, "testctx", 32)
			check.equal(buffer.len(subkey), 32)
		end)

		test.case("deriveKey is deterministic for same inputs", function()
			local master = Sodium.kdf.keygen()
			local subkey1 = Sodium.kdf.deriveKey(master, 1, "context!", 32)
			local subkey2 = Sodium.kdf.deriveKey(master, 1, "context!", 32)
			check.is_true(bufferEqual(subkey1, subkey2))
		end)

		test.case("different subkey IDs produce different subkeys", function()
			local master = Sodium.kdf.keygen()
			local subkey1 = Sodium.kdf.deriveKey(master, 1, "context!", 32)
			local subkey2 = Sodium.kdf.deriveKey(master, 2, "context!", 32)
			check.is_false(bufferEqual(subkey1, subkey2))
		end)

		test.case("different contexts produce different subkeys", function()
			local master = Sodium.kdf.keygen()
			local subkey1 = Sodium.kdf.deriveKey(master, 1, "context1", 32)
			local subkey2 = Sodium.kdf.deriveKey(master, 1, "context2", 32)
			check.is_false(bufferEqual(subkey1, subkey2))
		end)

		test.case("context longer than 8 bytes errors", function()
			local master = Sodium.kdf.keygen()
			check.should_error(function()
				Sodium.kdf.deriveKey(master, 1, "toolongctx", 32)
				return
			end)
		end)

		test.case("deriveKey defaults to KEY_BYTES output", function()
			local master = Sodium.kdf.keygen()
			local subkey = Sodium.kdf.deriveKey(master, 1, "ctx")
			check.equal(buffer.len(subkey), Sodium.sys.kdf.KEY_BYTES)
		end)
	end)
end
