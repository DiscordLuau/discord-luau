local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Dave = require("../src")

local FRAME_COUNT = 200
local DAVE_MAGIC_MARKER = "\250\250"

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Log sink", function() end)
	end
end

return function()
	test.suite("Log sink", function()
		test.case("every libdave log message reaches the sink as readable text", function()
			local messages: { string } = {}
			local unreadable: { string } = {}
			local decryptor = Dave.Decryptor.new()

			Dave.setLogSinkCallback(function(_, message: string)
				table.insert(if message == "" then unreadable else messages, message)
			end)

			for index = 1, FRAME_COUNT do
				local frame = buffer.fromstring(string.rep("x", index % 50 + 20) .. DAVE_MAGIC_MARKER)

				pcall(decryptor.decrypt :: (...any) -> ...any, decryptor, Dave.sys.mediaType.audio, frame)
			end

			decryptor:destroy()

			check.is_true(#messages > 0)
			check.equal(#unreadable, 0)
		end)
	end)
end
