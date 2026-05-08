local overwrite = require("../../src/guild/overwrite")
local apiTypes = require("../../luau_packages/api_types")
local frktest = require("../../../../luau_packages/frktest")

local Overwrite = overwrite
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Overwrite builds correct allow/deny bitstrings for role type", function()
		local ow = Overwrite.new({ permissionType = "role" })
		ow:allowPermissions("SendMessages")
		local json = ow:build()

		check.equal(json.type, 0)
		check.equal(type(json.allow), "string")
		check.equal(type(json.deny), "string")
	end)

	test.case("Overwrite builds correct type integer for member type", function()
		local ow = Overwrite.new({ permissionType = "member" })
		local json = ow:build()

		check.equal(json.type, 1)
	end)

	test.case("Overwrite constructor with allowFlags does not double-insert flags", function()
		local ow = Overwrite.new({
			permissionType = "role",
			allowFlags = { "SendMessages", "ViewChannel" } :: { apiTypes.Permissions },
		})

		check.equal(#ow.allowedPermissionFlags, 2)
	end)

	test.case("Overwrite constructor with denyFlags does not double-insert flags", function()
		local ow = Overwrite.new({
			permissionType = "role",
			denyFlags = { "Administrator" } :: { apiTypes.Permissions },
		})

		check.equal(#ow.deniedPermissionFlags, 1)
	end)

	test.case("Overwrite fromId sets id and builds correctly", function()
		local ow = Overwrite.fromId({
			permissionId = "123456789012345678",
			permissionType = "role",
			allowFlags = { "SendMessages" } :: { apiTypes.Permissions },
		})
		local json = ow:build()

		check.equal(ow.id, "123456789012345678")
		check.equal(json.type, 0)
	end)

	test.case("Overwrite allow and deny are both present even when empty", function()
		local ow = Overwrite.new({ permissionType = "role" })
		local json = ow:build()

		check.equal(type(json.allow), "string")
		check.equal(type(json.deny), "string")
	end)
end
