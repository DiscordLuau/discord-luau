local frktest = require("../../../luau_packages/frktest")
local Dave = require("../src")

local test = frktest.test
local check = frktest.assert.check

local GROUP_ID = "1234567890123456789"
local USER_ID_A = "111111111111111111"
local USER_ID_B = "222222222222222222"

local maxVersion = Dave.sys.lib.daveMaxSupportedProtocolVersion()

return function()
	test.suite("Session", function()
		test.case("constructs without error", function()
			local session = Dave.Session.new("auth-session-id")
			check.not_nil(session)
			session:destroy()
		end)

		test.case("constructs with MLS failure callback", function()
			local session = Dave.Session.new("auth-session-id", function(_source, _reason) end)
			check.not_nil(session)
			session:destroy()
		end)

		test.case("protocol version is 0 before init", function()
			local session = Dave.Session.new("auth-session-id")
			check.equal(session:getProtocolVersion(), 0)
			session:destroy()
		end)

		test.case("setProtocolVersion / getProtocolVersion round-trip", function()
			local session = Dave.Session.new("auth-session-id")
			session:setProtocolVersion(1)
			check.equal(session:getProtocolVersion(), 1)
			session:destroy()
		end)

		test.suite("after init", function()
			test.case("getProtocolVersion matches version passed to init", function()
				local session = Dave.Session.new("auth-session-id")
				session:init(maxVersion, GROUP_ID, USER_ID_A)
				check.equal(session:getProtocolVersion(), maxVersion)
				session:destroy()
			end)

			test.case("reset succeeds without error", function()
				local session = Dave.Session.new("auth-session-id")
				session:init(maxVersion, GROUP_ID, USER_ID_A)
				check.should_not_error(function()
					session:reset()

					return
				end)
				session:destroy()
			end)

			test.case("setMlsFailureCallback can replace the callback after construction", function()
				local callCount = 0
				local session = Dave.Session.new("auth-session-id", function(_source, _reason)
					callCount += 1
				end)
				session:setMlsFailureCallback(function(_source, _reason)
					callCount += 10
				end)
				check.equal(callCount, 0)
				session:destroy()
			end)
		end)

	end)
end
