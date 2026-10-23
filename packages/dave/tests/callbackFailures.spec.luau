local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Dave = require("../src")

local DAVE_MAGIC_MARKER = "\250\250"
local GROUP_ID = "1234567890123456789"
local USER_ID = "111111111111111111"

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Callback failures", function() end)
	end
end

local function captureWarnings(work: () -> ()): { string }
	local lines: { string } = {}

	Dave.log:setSink(function(line: string)
		table.insert(lines, line)
	end)

	local succeeded, failure = pcall(work :: () -> ...any)

	Dave.log:setSink(print)
	assert(succeeded, failure)

	return lines
end

local function hasLine(lines: { string }, needle: string): boolean
	for _, line in lines do
		if string.find(line, needle, 1, true) then
			return true
		end
	end

	return false
end

return function()
	test.suite("Callback failures", function()
		test.case("a raising log sink callback is warned instead of vanishing", function()
			local decryptor = Dave.Decryptor.new()
			local lines = captureWarnings(function()
				Dave.setLogSinkCallback(function()
					error("sink boom")
				end)

				for index = 1, 50 do
					local frame = buffer.fromstring(string.rep("x", index % 50 + 20) .. DAVE_MAGIC_MARKER)

					pcall(decryptor.decrypt :: (...any) -> ...any, decryptor, Dave.sys.mediaType.audio, frame)
				end
			end)

			Dave.setLogSinkCallback(function() end)
			decryptor:destroy()

			check.is_true(hasLine(lines, "[WARN]"))
			check.is_true(hasLine(lines, "sink boom"))
		end)

		test.case("a raising protocol version changed callback is warned", function()
			local encryptor = Dave.Encryptor.new()
			local lines = captureWarnings(function()
				encryptor:setProtocolVersionChangedCallback(function()
					error("version boom")
				end)
				encryptor:setPassthroughMode(true)
				encryptor:setPassthroughMode(false)
			end)

			encryptor:destroy()

			check.is_true(hasLine(lines, "[WARN]"))
			check.is_true(hasLine(lines, "version boom"))
		end)

		test.case("a raising MLS failure callback is warned", function()
			local session = Dave.Session.new("auth-session-id", function()
				error("mls boom")
			end)
			local lines = captureWarnings(function()
				session:init(Dave.sys.lib.daveMaxSupportedProtocolVersion(), GROUP_ID, USER_ID)
				pcall(session.processCommit :: (...any) -> ...any, session, buffer.fromstring("not a commit"))
			end)

			session:destroy()

			check.is_true(hasLine(lines, "[WARN]"))
			check.is_true(hasLine(lines, "mls boom"))
		end)
	end)
end
