local channelPosition = require("../../src/guild/channelPosition")
local frktest = require("../../../../luau_packages/frktest")

local ChannelPosition = channelPosition
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("ChannelPosition builds with id", function()
		local cp = ChannelPosition.new()
		cp:setId("111222333")
		local json = cp:build()

		check.equal(json.id, "111222333")
	end)

	test.case("ChannelPosition build errors when id is missing", function()
		local cp = ChannelPosition.new()
		check.should_error(function()
			cp:build()
			return
		end)
	end)

	test.case("ChannelPosition optional fields are nil when not set", function()
		local cp = ChannelPosition.new()
		cp:setId("111")
		local json = cp:build()

		check.equal(json.position, nil)
		check.equal(json.lock_permissions, nil)
		check.equal(json.parent_id, nil)
	end)

	test.case("ChannelPosition all fields are passed through", function()
		local cp = ChannelPosition.new()
		cp:setId("111"):setPosition(2):setLockPermissions(true):setParentId("999")
		local json = cp:build()

		check.equal(json.position, 2)
		check.equal(json.lock_permissions, true)
		check.equal(json.parent_id, "999")
	end)

	test.case("ChannelPosition position can be nil (reset)", function()
		local cp = ChannelPosition.new()
		cp:setId("111"):setPosition(nil)
		local json = cp:build()

		check.equal(json.position, nil)
	end)
end
