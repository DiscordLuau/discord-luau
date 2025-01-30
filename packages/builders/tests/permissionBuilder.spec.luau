local frktest = require("../../../lune_packages/frktest")
local Permission = require("../src/permission")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Permission builder sets and builds bitflag correctly", function()
		local permission = Permission.new()

		permission:setPermissionBitflag(12345)

		check.equal(permission.bitflag, 12345)

		local builtBitflag = permission:build()
		check.equal(builtBitflag, "12345")
	end)

	test.case("Permission builder adds permissions correctly", function()
		local permission = Permission.new()

		permission:addPermission("Administrator")
		permission:addPermission("ManageChannels")

		check.equal(#permission.addedPermissions, 2)

		local builtBitflag = permission:build()
		check.not_equal(builtBitflag, "0")
	end)

	test.case("Permission builder removes permissions correctly", function()
		local permission = Permission.new()

		permission:addPermission("Administrator")
		permission:removePermission("Administrator")

		check.equal(#permission.removedPermissions, 1)

		local builtBitflag = permission:build()
		check.equal(builtBitflag, "0")
	end)

	test.case("Permission builder allows chaining of methods", function()
		local permission = Permission.new()

		check.should_not_error(function()
			permission:setPermissionBitflag(12345):addPermission("ManageChannels"):removePermission("Administrator")

			check.equal(permission.bitflag, 12345)

			return permission
		end)
	end)
end
