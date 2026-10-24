local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Dave = require("../src")

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Frame failures", function() end)
	end
end

local function runInThread(work: () -> ...any): Attempt
	local attempt: Attempt = { finished = false }
	local thread = coroutine.create(function()
		local succeeded, failure = pcall(work)

		attempt.succeeded = succeeded
		attempt.failure = if succeeded then nil else tostring(failure)
		attempt.finished = true
	end)
	local resumed, resumeError = coroutine.resume(thread)

	assert(resumed, resumeError)

	return attempt
end

type Attempt = { finished: boolean, succeeded: boolean?, failure: string? }

return function()
	test.suite("Frame failures", function()
		test.case("a decrypt failure raises an error the caller can catch", function()
			local decryptor = Dave.Decryptor.new()
			local frame = buffer.fromstring("not a dave frame")
			local attempt = runInThread(function()
				decryptor:decrypt(Dave.sys.mediaType.audio, frame)
			end)

			check.is_true(attempt.finished)
			check.equal(attempt.succeeded, false)
			check.not_nil(attempt.failure)

			decryptor:destroy()
		end)

		test.case("an encrypt failure raises an error the caller can catch", function()
			local encryptor = Dave.Encryptor.new()
			local frame = buffer.fromstring("opus frame")
			local attempt = runInThread(function()
				encryptor:encrypt(Dave.sys.mediaType.audio, 12345, frame)
			end)

			check.is_true(attempt.finished)
			check.equal(attempt.succeeded, false)
			check.not_nil(attempt.failure)

			encryptor:destroy()
		end)
	end)
end
