local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Dave = require("../src")
local Buffer = require("../src/buffer")
local Sys = require("../src/sys")

local GROUP_ID = "1234567890123456789"
local SELF_USER_ID = "1111111111111111111"

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Dave pointers", function() end)
	end
end

return function()
	test.suite("Dave pointers", function()
		test.case("a NULL key ratchet comes back as nil and leaves the shared null usable", function()
			local session = Dave.Session.new("", nil)
			local ratchet = session:getKeyRatchet(SELF_USER_ID)
			local encryptor = Dave.Encryptor.new()

			check.equal(ratchet, nil)
			check.not_nil(encryptor)

			encryptor:destroy()
			session:destroy()
		end)

		test.case("a rejected welcome comes back as nil and leaves the shared null usable", function()
			local session = Dave.Session.new("", nil)

			session:init(1, GROUP_ID, SELF_USER_ID)

			local welcome = session:processWelcome(buffer.fromstring("not a welcome"), { SELF_USER_ID })
			local encryptor = Dave.Encryptor.new()

			check.equal(welcome, nil)
			check.not_nil(encryptor)

			encryptor:destroy()
			session:destroy()
		end)

		test.case("a stale tag on memory libdave hands back is cleared before it is freed", function()
			local session = Dave.Session.new("", nil)

			session:init(1, GROUP_ID, SELF_USER_ID)

			local staleType = stdPolyfills.ffi.getTypes().pointer:newTag("Stale")
			local dataSlot = Buffer.allocateSlot()
			local lengthSlot = Buffer.allocateSlot()

			Sys.lib.daveSessionGetMarshalledKeyPackage(session.handle :: any, dataSlot, lengthSlot)
			dataSlot:readptr(0):tag(staleType:tag())

			local readOk, keyPackage = pcall(Buffer.readLibBytes, dataSlot, lengthSlot)

			check.is_true(readOk)
			check.is_true(readOk and buffer.len(keyPackage) > 0)

			stdPolyfills.ffi.free(dataSlot)
			stdPolyfills.ffi.free(lengthSlot)
			session:destroy()
		end)

		test.case("a destroyed encryptor raises instead of calling libdave", function()
			local encryptor = Dave.Encryptor.new()

			encryptor:destroy()

			check.should_error(function()
				return encryptor:hasKeyRatchet()
			end)
		end)
	end)
end
